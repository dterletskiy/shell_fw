if [ -n "${__SFW_PRINT_SH__}" ]; then
   return 0
fi
__SFW_PRINT_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/constants/console.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/constants/constants.sh"



readonly SPLIT_ARGUMENTS=1

# Building bunner data
readonly DELIMITER_CHAR="-"
readonly SIDE_CHAR="|"
readonly SPACE_CHAR=" "

readonly BANNER_LENGTH=200

readonly DELIMITER_1="+"$(printf "%$(( BANNER_LENGTH - 2 ))s" | tr ' ' "${DELIMITER_CHAR}")"+"
readonly DELIMITER_1_LENGTH=$(echo -n "${DELIMITER_1}" | wc -c)

readonly DELIMITER_2="||"$(printf "%$(( BANNER_LENGTH - 4 ))s" | tr ' ' "${SPACE_CHAR}")"||"
readonly DELIMITER_2_LENGTH=$(echo -n "${DELIMITER_2}" | wc -c)



function print_text_in_bunner( )
{
   local TEXT=${1}
   local TEXT_LENGTH=$(echo -n "${TEXT}" | wc -c)

   local SIDE_SPACE_COUNT=$(( ( BANNER_LENGTH - TEXT_LENGTH - 2 ) / 2 ))
   local SIDE_SPACE=$(printf "%${SIDE_SPACE_COUNT}s" | tr ' ' "${SPACE_CHAR}")
   local SPACE_ADD_COUNT=$(( ( BANNER_LENGTH - TEXT_LENGTH - 2 ) % 2 ))
   local SPACE_ADD=$(printf "%${SPACE_ADD_COUNT}s" | tr ' ' "${SPACE_CHAR}")

   local BG_COLOR=${ECHO_BG_LightYellow}
   local FG_COLOR=${ECHO_FG_Red}
   local COLOR=${BG_COLOR}${FG_COLOR}
   local COLOR_RESET=${ECHO_RESET}
   local FORMAT=${COLOR}%s${COLOR_RESET}

   printf "${FORMAT}\n" "${DELIMITER_1}"
   printf "${FORMAT}\n" "${DELIMITER_2}"
   printf "${FORMAT}\n" "${DELIMITER_2}"
   printf "${FORMAT}\n" "${SIDE_CHAR}${SIDE_SPACE}${TEXT}${SIDE_SPACE}${SPACE_ADD}${SIDE_CHAR}"
   printf "${FORMAT}\n" "${DELIMITER_2}"
   printf "${FORMAT}\n" "${DELIMITER_2}"
   printf "${FORMAT}\n" "${DELIMITER_1}"
}

function print_time_bar( )
{
   local LOCAL_TIME=${1}
   local LOCAL_BAR_WIDTH=${2}

   if [ -z "${LOCAL_BAR_WIDTH}" ]; then
      LOCAL_BAR_WIDTH=100
   elif ! [[ "${LOCAL_BAR_WIDTH}" =~ ^[0-9]+$ ]]; then
      return 1
   elif [ "${CMD_TIME}" -le 0 ]; then
      LOCAL_BAR_WIDTH=100
   fi

   echo
   echo
   for sec in $(seq 1 "${LOCAL_TIME}"); do
      local left=$(( LOCAL_TIME - sec ))
      local percent=$(( sec * 100 / LOCAL_TIME ))
      local filled=$(( sec * LOCAL_BAR_WIDTH / LOCAL_TIME ))
      local empty=$(( LOCAL_BAR_WIDTH - filled ))

      local bar=$(printf "%0.s#" $(seq 1 $filled))
      bar="$bar$(printf "%0.s-" $(seq 1 $empty))"

      # Select color
      if [ $percent -lt 50 ]; then
         COLOR=${ECHO_OK}
      elif [ $percent -lt 80 ]; then
         COLOR=${ECHO_WARNING}
      else
         COLOR=${ECHO_ERROR}
      fi

      # Move cursor up 2 lines, overwrite both lines
      echo -ne "\033[2A"   # Move cursor up 2 lines
      echo -e "\rElapsed: ${sec}s | Remaining: ${left}s\033[K"  # First line
      echo -e "${COLOR}[${bar}] ${percent}%${ECHO_RESET}\033[K"    # Second line
      # echo -ne "\r${COLOR}[${bar}] ${percent}%${ECHO_RESET} | Elapsed: ${sec}s | Remaining: ${left}s"
      sleep 1
   done
   echo
}

function action_begin( )
{
   print_text_in_bunner $@
   #press_any_key
}
function action_end( )
{
   echo ""
   #press_any_key
}

function print_old( )
{
   local LOCAL_FORMAT=$1
   local LOCAL_MESSAGE=("${!2}")
   echo -e ${LOCAL_FORMAT}${LOCAL_MESSAGE[@]}${ECHO_RESET}
}

PRINT_WITH_IMAGES=0

function print( )
{
   declare -A __TRACE_TYPE_TO_COLOR__=(
      [HEADER]=${ECHO_HEADER}
      [INFO]=${ECHO_INFO}
      [OK]=${ECHO_OK}
      [ERROR]=${ECHO_ERROR}
      [WARNING]=${ECHO_WARNING}
      [QUESTION]=${ECHO_QUESTION}
      [PROMT]=${ECHO_PROMT}
   )

   declare -A __TRACE_TYPE_TO_IMAGE__=(
      [HEADER]=📌
      [HEADER1]=📢
      [INFO]=ℹ️
      [INFO1]=💡
      [OK]=✅
      [ERROR]=❌
      [WARNING]=⚠️
      [QUESTION]=❓
      [PROMT]=💬
   )

   local LOCAL_FORMAT=$1
   local LOCAL_MESSAGE=("${!2}")

   if [[ 0 -ne ${PRINT_WITH_IMAGES} ]]; then
      printf "${__TRACE_TYPE_TO_IMAGE__[$LOCAL_FORMAT]}: "
   fi

   if [[ 0 -eq ${SPLIT_ARGUMENTS} ]]; then
      # No split arguments
      printf "${__TRACE_TYPE_TO_COLOR__[$LOCAL_FORMAT]}%s${ECHO_RESET}" ${LOCAL_MESSAGE[@]}
      printf "\n"
   else
      # Split arguments
      printf "${__TRACE_TYPE_TO_COLOR__[$LOCAL_FORMAT]}%s${ECHO_RESET}\n" "${LOCAL_MESSAGE[@]}"
   fi
}

function print_and_run( )
{
   echo ${1}
   time eval ${1}
}


function print_header( )
{
   local LOCAL_MESSAGE=$@
   print HEADER LOCAL_MESSAGE[@]
}
function print_info( )
{
   local LOCAL_MESSAGE=$@
   print INFO LOCAL_MESSAGE[@]
}
function print_ok( )
{
   local LOCAL_MESSAGE=$@
   print OK LOCAL_MESSAGE[@]
}
function print_error( )
{
   local LOCAL_MESSAGE=$@
   print ERROR LOCAL_MESSAGE[@]
}
function print_warning( )
{
   local LOCAL_MESSAGE=$@
   print WARNING LOCAL_MESSAGE[@]
}

function print_question( )
{
   local LOCAL_MESSAGE=$@
   print QUESTION LOCAL_MESSAGE[@]
}

function print_promt( )
{
   local LOCAL_MESSAGE=$@
   print PROMT LOCAL_MESSAGE[@]
}

# This function prints variable name (passed as the parameter) and its value
# print_variable "PWD"
function print_variable( )
{
   local VARIABLE=${1}
   print_info "${VARIABLE}: ${!VARIABLE}"
}


# LIST=( "A" "B" "C" )
# print_list "${LIST[@]}" "OPTIONAL_NAME"
function print_list( )
{
   local LOCAL_LIST=("$@")
   local NAME="list"

   if [ -z ${2+x} ]; then
      NAME="list"
   else
      NAME=$2
   fi

   echo "${NAME} [${#LOCAL_ARRAY[@]}]"
   echo "{"
   for LOCAL_ITEM in ${LOCAL_LIST[*]} ; do
      echo "   ${LOCAL_ITEM}"
   done
   echo "}"
}

# This function do the same and 'print_list' but should be called similar to 'print_map'
# ARRAY=( "A" "B" "C" )
# print_array ARRAY "OPTIONAL_NAME"
function print_array( )
{
   local -n LOCAL_ARRAY=${1}
   local NAME="array"

   if [ -z ${2+x} ]; then
      NAME="array"
   else
      NAME=$2
   fi

   echo "${NAME} [${#LOCAL_ARRAY[@]}]"
   echo "{"
   for LOCAL_ITEM in "${LOCAL_ARRAY[@]}"; do
      echo "   ${LOCAL_ITEM}"
   done
   echo "}"
   # print_list "${LOCAL_ARRAY[@]}"
}

# declare -A MAP=( [one]=111 [two]=222 [three]=333 )
# print_map MAP "OPTIONAL_NAME"
function print_map( )
{
   local -n LOCAL_MAP=$1
   local NAME="map"

   if [ -z ${2+x} ]; then
      NAME="map"
   else
      NAME=$2
   fi

   echo "${NAME} [${#LOCAL_MAP[@]}]"
   echo "{"
   for KEY in "${!LOCAL_MAP[@]}"; do
      echo "   { ${KEY} -> ${LOCAL_MAP[${KEY}]} }"
   done
   echo "}"
}
