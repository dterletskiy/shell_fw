if [ -n "${__SFW_BASE_SH__}" ]; then
   return 0
fi
__SFW_BASE_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"



function get_current_dir( )
{
   # echo $(cd -P -- "$(dirname -- "$0")" && pwd -P)
   # echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
   echo ${PWD}
}

function get_current_dir_name( )
{
   echo ${PWD##*/}
}

function get_current_script_name( )
{
   # https://stackoverflow.com/a/192337
   echo $(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
}

function get_current_script_dir( )
{
   echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
}

# 'dir_names_list' - returns to the second parameter list of all directories names
# in the path passed in the first parameter.
# Example:
# DIR="..."
# DIR_NAMES=( )
# dir_names_list ${DIR} DIR_NAMES
function dir_names_list( )
{
   local LOCAL_PATH=${1}
   local -n RESULT=${2}

   if [ ! -d "${LOCAL_PATH}" ]; then
      echo "Error: ${LOCAL_PATH} is not a directory."
      echo ""
      return 1
   fi

   local DIR_LIST=$(find "${LOCAL_PATH}" -mindepth 1 -maxdepth 1 -type d)

   RESULT=( )
   for DIR in ${DIR_LIST[@]}; do
      RESULT+=("$(basename ${DIR})")
   done

   return 0
}

function remove_dir( )
{
   if [ $# -lt 1 ]; then return 2; fi

   local DIR_PATH=$1
   if [ -d "${DIR_PATH}" ]; then
      echo removing ${DIR_PATH}
      rm -rf ${DIR_PATH}
   fi
}

function check_execute_result( )
{
   local EXECUTE_RESULT=$?

   if [ ${EXECUTE_RESULT} -eq 0 ]; then
      print_ok "Execute OK"
      return 0
   fi

   while [ 1 ]; do
      print_error "Execute error: ${EXECUTE_RESULT}"
      read -p "$( print_question Continue installation [y/N]? )" is_continue
      case ${is_continue} in
         y|Y|yes|Yes|YES)
            echo "continue"
            return 1
         ;;
         n|N|no|No|NO|"")
            echo "interrupt"
            exit ${EXECUTE_RESULT}
         ;;
         * ) echo "Please type 'Y' or 'N'" ;;
      esac
   done
}

function check_is_number( )
{
   if [ $# -lt 1 ]; then return 2; fi

   # links: https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
   local NUMBER_PATTERN='^[0-9]+$'
   #local NUMBER_PATTERN='^[0-9]+([.][0-9]+)?$'
   #local NUMBER_PATTERN='^[+-]?[0-9]+([.][0-9]+)?$'
   local LOCAL_NUMBER="$1"

   if [[ $LOCAL_NUMBER =~ $NUMBER_PATTERN ]] ; then
      return 0
   fi
   return 1
}

function check_root( )
{
   if [ "$(id -u)" != "0" ]; then
      echo "This script must be run as root" 1>&2
      exit 1
   fi
}


# declare -a ARRAY=(0 1 2 3 4 5)
# array_add ARRAY 6
function array_add( )
{
   local -n LOCAL_ARRAY=${1}
   local LOCAL_ELEMENT=${2}

   LOCAL_ARRAY=("${LOCAL_ARRAY[@]}" ${LOCAL_ELEMENT})
}

# declare -a ARRAY=(0 1 2 3 4 5)
# array_remove ARRAY 3
function array_remove( )
{
   local -n LOCAL_ARRAY=${1}
   local LOCAL_ELEMENT=${2}

   for LOCAL_INDEX in ${!LOCAL_ARRAY[@]}; do
      if [ ${LOCAL_ELEMENT} == ${LOCAL_ARRAY[${LOCAL_INDEX}]} ] ; then
         break
      fi
   done
   # echo ${LOCAL_INDEX}

   LOCAL_ARRAY=( "${LOCAL_ARRAY[@]:0:${LOCAL_INDEX}}" "${LOCAL_ARRAY[@]:${LOCAL_INDEX}+1}" )
}

function array_find( )
{
   local -n LOCAL_LIST=${1}
   local LOCAL_ITEM=${2}

   for __ITEM__ in "${LOCAL_LIST[@]}"; do
      if [ "${__ITEM__}" == "${LOCAL_ITEM}" ]; then
         return 1
      fi
   done

   return 0
}

function map_find_key( )
{
   local -n LOCAL_MAP=${1}
   local LOCAL_KEY=${2}


   for __KEY__ in "${!LOCAL_MAP[@]}"; do
      if [ "${__KEY__}" == "${LOCAL_KEY}" ]; then
         return 1
      fi
   done

   return 0
}

function map_find_value( )
{
   local -n LOCAL_MAP=${1}
   local LOCAL_VALUE=${2}

   for __KEY__ in "${!LOCAL_MAP[@]}"; do
      if [ "${LOCAL_MAP[${__KEY__}]}" == "${LOCAL_VALUE}" ]; then
         return 1
      fi
   done

   return 0
}

function map_find_key_value( )
{
   local -n LOCAL_MAP=${1}
   local LOCAL_KEY=${2}


   for __KEY__ in "${!LOCAL_MAP[@]}"; do
      if [ "${__KEY__}" == "${LOCAL_KEY}" ]; then
         if [ "${LOCAL_MAP[${__KEY__}]}" == "${LOCAL_VALUE}" ]; then
            return 1
         fi
         return 0
      fi
   done

   return 0
}

# This function recurcively searches all files in gived directory with given
# extentiones.
# Example:
#  declare -a FILE_LIST=()
#  declare -a EXTENTIONS=( "c" "cpp" "cxx" )
#  find_extentions_in_dir /home EXTENTIONS FILE_LIST
#  echo "FILE_LIST: " ${FILE_LIST[@]}
#  echo "FILE_LIST size: " ${#FILE_LIST[@]}
function find_extentions_in_dir( )
{
   local LOCAL_SEARCH_DIR=${1}
   local -n LOCAL_EXTENTIONS=${2}
   local -n LOCAL_FILE_LIST=${3}

   local LOCAL_PATTERN=""
   for LOCAL_EXTENTION in ${LOCAL_EXTENTIONS[@]} ; do
      LOCAL_PATTERN+="${LOCAL_EXTENTION}|"
   done
   LOCAL_PATTERN=${LOCAL_PATTERN::-1}

   local -a LOCAL_RESULT_LIST=()
   local LOCAL_RESULT_LIST=$( find ${LOCAL_SEARCH_DIR} -regextype posix-extended -regex ".*\.(${LOCAL_PATTERN})" )

   for LOCAL_RESULT_ITEM in ${LOCAL_RESULT_LIST[@]} ; do
      LOCAL_FILE_LIST+=( ${LOCAL_RESULT_ITEM} )
   done
}



# This function parses list of numbers and ranges of numbers passed in the string
# and fills an array of numbers passed as a second argument.
# List of numbers and ranges must be passed as a string and separated by ','.
# Ranges is the two numbers separated by '-'.
# Examples:
#     declare -a ARRAY
#     parse_range "1" ARRAY
#     parse_range "1,7,9" ARRAY
#     parse_range "0-7" ARRAY
#     parse_range "1-3,6,7" ARRAY
#     parse_range "0,2-7,9" ARRAY
function parse_range( )
{
   local INPUT_STRING="${1}"
   local -n _PARSE_RANGE_RESULT_ARRAY_=${2}

   _PARSE_RANGE_RESULT_ARRAY_=( )

   IFS=',' read -r -a tokens <<< "${INPUT_STRING}"

   for token in "${tokens[@]}"; do
      if [[ "${token}" =~ ^[0-9]+$ ]]; then
         _PARSE_RANGE_RESULT_ARRAY_+=("${token}")
      elif [[ "${token}" =~ ^([0-9]+)-([0-9]+)$ ]]; then
         start=${BASH_REMATCH[1]}
         end=${BASH_REMATCH[2]}
         if (( start <= end )); then
            for (( i=start; i<=end; i++ )); do
               _PARSE_RANGE_RESULT_ARRAY_+=("${i}")
            done
         else
            print_error "Error: invalid range '${token}' (end is less then begin)"
            return 1
         fi
      else
            print_error "Error: invalid '${token}'"
            return 1
      fi
   done

   return 0
}

function test_parse_range( )
{
   declare -a ARRAY

   local STRING="1"
   parse_range ${STRING} ARRAY
   print_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="1,7,9"
   parse_range ${STRING} ARRAY
   print_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="0-7"
   parse_range ${STRING} ARRAY
   print_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="1-3,6,7"
   parse_range ${STRING} ARRAY
   print_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="0,2-7,9"
   parse_range ${STRING} ARRAY
   print_info "'${STRING}' ->"
   print_array ARRAY
}
