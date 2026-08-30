[ -n "${__SFW_LOG_SH__}" ] && return 0 || readonly __SFW_LOG_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/constants/colors.sh"



__SWF_LOG_SPLIT_ARGUMENTS__=1
function log_enable_split_arguments( )
{
   __SWF_LOG_SPLIT_ARGUMENTS__=1
}
function log_disable_split_arguments( )
{
   __SWF_LOG_SPLIT_ARGUMENTS__=0
}

__SWF_LOG_WITH_COLOR__=1
function log_enable_color( )
{
   __SWF_LOG_WITH_COLOR__=1
}
function log_disable_color( )
{
   __SWF_LOG_WITH_COLOR__=0
}

__SWF_LOG_WITH_IMAGES__=0
function log_enable_images( )
{
   __SWF_LOG_WITH_IMAGES__=1
}
function log_disable_images( )
{
   __SWF_LOG_WITH_IMAGES__=0
}

__SWF_LOG_WITH_FORMAT__=0
function log_enable_format( )
{
   __SWF_LOG_WITH_FORMAT__=1
}
function log_disable_format( )
{
   __SWF_LOG_WITH_FORMAT__=0
}

__SWF_LOG_WITH_TIMESTAMP__=0
function log_enable_timestamp( )
{
   __SWF_LOG_WITH_TIMESTAMP__=1
}
function log_disable_timestamp( )
{
   __SWF_LOG_WITH_TIMESTAMP__=0
}

__SWF_LOG_WITH_CODEPOINT__=0
function log_enable_codepoint( )
{
   __SWF_LOG_WITH_CODEPOINT__=1
}
function log_disable_codepoint( )
{
   __SWF_LOG_WITH_CODEPOINT__=0
}


declare -A -g -r __SWF_LOG_SKIP_STACK_FUNCTIONS__=(
   [__log__]=1
   [log_trace]=1
   [log_debug]=1
   [log_info]=1
   [log_notice]=1
   [log_warning]=1
   [log_error]=1
   [log_critical]=1
   [log_fatal]=1
   [execute]=1
   [execute_arr]=1
)

declare -A -g -r __SWF_LOG_TRACE_TYPE_TO_COLOR__=(
   [TRACE]=${ECHO_FG_Default}
   [DEBUG]=${ECHO_FG_LightGray}
   [INFO]=${ECHO_FG_Green}
   [NOTICE]=${ECHO_FG_LightCyan}
   [WARNING]=${ECHO_FG_Blue}
   [ERROR]=${ECHO_FG_Red}
   [CRITICAL]=${ECHO_FG_Magenta}
   [FATAL]=${ECHO_FG_Default}${ECHO_BG_Red}

   [RED]=${ECHO_FG_Red}
   [GREEN]=${ECHO_FG_Green}
   [YELLOW]=${ECHO_FG_Yellow}
   [BLUE]=${ECHO_FG_Blue}
   [MAGENTA]=${ECHO_FG_Magenta}
   [CYAN]=${ECHO_FG_Cyan}

   [LIGHTRED]=${ECHO_FG_LightRed}
   [LIGHTGREEN]=${ECHO_FG_LightGreen}
   [LIGHTYELLOW]=${ECHO_FG_LightYellow}
   [LIGHTBLUE]=${ECHO_FG_LightBlue}
   [LIGHTMAGENTA]=${ECHO_FG_LightMagenta}
   [LIGHTCYAN]=${ECHO_FG_LightCyan}

   [BLACK]=${ECHO_FG_Black}
   [DARKGRAY]=${ECHO_FG_DarkGray}
   [LIGHTGRAY]=${ECHO_FG_LightGray}
   [WHITE]=${ECHO_FG_White}
)

declare -A -g -r __SWF_LOG_TRACE_TYPE_TO_IMAGE__=(
   [TRACE]="📝"
   [DEBUG]="🔧"
   [INFO]="ℹ️ "
   [NOTICE]="📌"
   [WARNING]="⚠️ "
   [ERROR]="❌"
   [CRITICAL]="🚨"
   [FATAL]="💀"
)

declare -A -g -r __SWF_LOG_TRACE_TYPE_TO_TEXT__=(
   [TRACE]="TRACE"
   [DEBUG]="DEBUG"
   [INFO]="INFO"
   [NOTICE]="NOTICE"
   [WARNING]="WARNING"
   [ERROR]="ERROR"
   [CRITICAL]="CRITICAL"
   [FATAL]="FATAL"

   [RED]="UNDEFINED"
   [GREEN]="UNDEFINED"
   [YELLOW]="UNDEFINED"
   [BLUE]="UNDEFINED"
   [MAGENTA]="UNDEFINED"
   [CYAN]="UNDEFINED"

   [LIGHTRED]="UNDEFINED"
   [LIGHTGREEN]="UNDEFINED"
   [LIGHTYELLOW]="UNDEFINED"
   [LIGHTBLUE]="UNDEFINED"
   [LIGHTMAGENTA]="UNDEFINED"
   [LIGHTCYAN]="UNDEFINED"

   [BLACK]="UNDEFINED"
   [DARKGRAY]="UNDEFINED"
   [LIGHTGRAY]="UNDEFINED"
   [WHITE]="UNDEFINED"
)




function __log__( )
{
   local LOCAL_FORMAT=$1
   local LOCAL_MESSAGE=("${!2}")
   local COLOR=""
   local RESET_COLOR=""

   if [[ 0 -ne ${__SWF_LOG_WITH_TIMESTAMP__} ]]; then
      (( __SWF_LOG_WITH_COLOR__ )) && \
         COLOR="${ECHO_FG_LightCyan}" || COLOR=""
      (( __SWF_LOG_WITH_COLOR__ )) && \
         RESET_COLOR="${ECHO_RESET}" || RESET_COLOR=""
      printf "${COLOR}%-25s${RESET_COLOR}" "[$(date '+%Y-%m-%d %H:%M:%S')]"
   fi

   if [[ 0 -ne ${__SWF_LOG_WITH_IMAGES__} ]]; then
      local emoji="${__SWF_LOG_TRACE_TYPE_TO_IMAGE__[$LOCAL_FORMAT]}"
      printf "%s%-4s" "$emoji" ""
   fi

   if [[ 0 -ne ${__SWF_LOG_WITH_FORMAT__} ]]; then
      (( __SWF_LOG_WITH_COLOR__ )) && \
         COLOR="${__SWF_LOG_TRACE_TYPE_TO_COLOR__[$LOCAL_FORMAT]}" || COLOR=""
      (( __SWF_LOG_WITH_COLOR__ )) && \
         RESET_COLOR="${ECHO_RESET}" || RESET_COLOR=""
      printf "${COLOR}%-12s${RESET_COLOR}" "[${__SWF_LOG_TRACE_TYPE_TO_TEXT__[$LOCAL_FORMAT]}]"
   fi

   if [[ 0 -ne ${__SWF_LOG_WITH_CODEPOINT__} ]]; then

      local STACK_INDEX=0
      local func=""
      local src=""
      local line=""
      # Here we skip functions in highest stack points, defined in the map.
      for(( STACK_INDEX = 1; STACK_INDEX < ${#FUNCNAME[@]}; ++STACK_INDEX )); do
         if [[ -n "${__SWF_LOG_SKIP_STACK_FUNCTIONS__[${FUNCNAME[$STACK_INDEX]}]}" ]]; then
            continue
         fi

         func="${FUNCNAME[${STACK_INDEX}]}"
         src="${BASH_SOURCE[${STACK_INDEX}]}"
         line="${BASH_LINENO[$(( ${STACK_INDEX} - 1 ))]}"
         break
      done

      if [[ -z "${func}" ]]; then
         local STACK_LAST_INDEX=$(( ${#BASH_SOURCE[@]} - 1 ))
         func="main"
         src="${BASH_SOURCE[${STACK_LAST_INDEX}]}"
         line="${BASH_LINENO[${STACK_LAST_INDEX}]:-0}"
      fi

      (( __SWF_LOG_WITH_COLOR__ )) && \
         COLOR="${ECHO_FG_LightYellow}" || COLOR=""
      (( __SWF_LOG_WITH_COLOR__ )) && \
         RESET_COLOR="${ECHO_RESET}" || RESET_COLOR=""

      printf "${COLOR}%-25s${RESET_COLOR}" "[${func}():${line}]"
   fi

   (( __SWF_LOG_WITH_COLOR__ )) && \
      COLOR="${__SWF_LOG_TRACE_TYPE_TO_COLOR__[$LOCAL_FORMAT]}" || COLOR=""
   (( __SWF_LOG_WITH_COLOR__ )) && \
      RESET_COLOR="${ECHO_RESET}" || RESET_COLOR=""

   if [[ 0 -eq ${__SWF_LOG_SPLIT_ARGUMENTS__} ]]; then
      # No split arguments
      printf "${COLOR}%s${RESET_COLOR}" "${LOCAL_MESSAGE[*]}"
      printf "\n"
   else
      # Split arguments
      printf "${COLOR}%s${RESET_COLOR}\n" "${LOCAL_MESSAGE[@]}"
   fi
}



function log_trace( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ TRACE LOCAL_MESSAGE[@]
}

function log_debug( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ DEBUG LOCAL_MESSAGE[@]
}

function log_info( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ INFO LOCAL_MESSAGE[@]
}

function log_notice( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ NOTICE LOCAL_MESSAGE[@]
}

function log_warning( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ WARNING LOCAL_MESSAGE[@]
}

function log_error( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ ERROR LOCAL_MESSAGE[@]
}

function log_critical( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ CRITICAL LOCAL_MESSAGE[@]
}

function log_fatal( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ FATAL LOCAL_MESSAGE[@]
}



function log_red( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ RED LOCAL_MESSAGE[@]
}

function log_green( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ GREEN LOCAL_MESSAGE[@]
}

function log_yellow( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ YELLOW LOCAL_MESSAGE[@]
}

function log_blue( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ BLUE LOCAL_MESSAGE[@]
}

function log_magenta( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ MAGENTA LOCAL_MESSAGE[@]
}

function log_cyan( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ CYAN LOCAL_MESSAGE[@]
}

function log_lightred( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTRED LOCAL_MESSAGE[@]
}

function log_lightgreen( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTGREEN LOCAL_MESSAGE[@]
}

function log_lightyellow( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTYELLOW LOCAL_MESSAGE[@]
}

function log_lightblue( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTBLUE LOCAL_MESSAGE[@]
}

function log_lightmagenta( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTMAGENTA LOCAL_MESSAGE[@]
}

function log_lightcyan( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTCYAN LOCAL_MESSAGE[@]
}

function log_black( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ BLACK LOCAL_MESSAGE[@]
}

function log_darkgray( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ DARKGRAY LOCAL_MESSAGE[@]
}

function log_lightgray( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ LIGHTGRAY LOCAL_MESSAGE[@]
}

function log_white( )
{
   local LOCAL_MESSAGE=("$@")
   __log__ WHITE LOCAL_MESSAGE[@]
}



function __test_log__( )
{
   local MESSAGE=${1:-MESSAGE}
   log_trace ${MESSAGE}
   log_debug ${MESSAGE}
   log_info ${MESSAGE}
   log_notice ${MESSAGE}
   log_warning ${MESSAGE}
   log_error ${MESSAGE}
   log_critical ${MESSAGE}
   log_fatal ${MESSAGE}
}



function __log_test__( )
{
   local -a TEST_MESSAGE=()

   if [[ 0 -eq $# ]]; then
      TEST_MESSAGE=("MESSAGE" "MESSAGE WITH SPACES" "symbols: * ? [ ]")
   else
      TEST_MESSAGE=("$@")
   fi

   local -a SPLIT_VALUES=(0 1)
   local -a COLOR_VALUES=(0 1)
   local -a IMAGE_VALUES=(0 1)
   local -a FORMAT_VALUES=(0 1)
   local -a TIMESTAMP_VALUES=(0 1)
   local -a CODEPOINT_VALUES=(0 1)

   local SAVED_SPLIT=${__SWF_LOG_SPLIT_ARGUMENTS__}
   local SAVED_COLOR=${__SWF_LOG_WITH_COLOR__}
   local SAVED_IMAGES=${__SWF_LOG_WITH_IMAGES__}
   local SAVED_FORMAT=${__SWF_LOG_WITH_FORMAT__}
   local SAVED_TIMESTAMP=${__SWF_LOG_WITH_TIMESTAMP__}
   local SAVED_CODEPOINT=${__SWF_LOG_WITH_CODEPOINT__}

   local split
   local color
   local images
   local format
   local timestamp
   local codepoint
   local index=0

   for split in "${SPLIT_VALUES[@]}"; do
      for color in "${COLOR_VALUES[@]}"; do
         for images in "${IMAGE_VALUES[@]}"; do
            for format in "${FORMAT_VALUES[@]}"; do
               for timestamp in "${TIMESTAMP_VALUES[@]}"; do
                  for codepoint in "${CODEPOINT_VALUES[@]}"; do
                     __SWF_LOG_SPLIT_ARGUMENTS__=${split}
                     __SWF_LOG_WITH_COLOR__=${color}
                     __SWF_LOG_WITH_IMAGES__=${images}
                     __SWF_LOG_WITH_FORMAT__=${format}
                     __SWF_LOG_WITH_TIMESTAMP__=${timestamp}
                     __SWF_LOG_WITH_CODEPOINT__=${codepoint}

                     printf "\n"
                     printf "log test #%02d: split=%s color=%s images=%s format=%s timestamp=%s codepoint=%s\n" \
                        "${index}" \
                        "${split}" \
                        "${color}" \
                        "${images}" \
                        "${format}" \
                        "${timestamp}" \
                        "${codepoint}"

                     log_trace "${TEST_MESSAGE[@]}"
                     log_debug "${TEST_MESSAGE[@]}"
                     log_info "${TEST_MESSAGE[@]}"
                     log_notice "${TEST_MESSAGE[@]}"
                     log_warning "${TEST_MESSAGE[@]}"
                     log_error "${TEST_MESSAGE[@]}"
                     log_critical "${TEST_MESSAGE[@]}"
                     log_fatal "${TEST_MESSAGE[@]}"

                     log_red "${TEST_MESSAGE[@]}"
                     log_green "${TEST_MESSAGE[@]}"
                     log_yellow "${TEST_MESSAGE[@]}"
                     log_blue "${TEST_MESSAGE[@]}"
                     log_magenta "${TEST_MESSAGE[@]}"
                     log_cyan "${TEST_MESSAGE[@]}"
                     log_lightred "${TEST_MESSAGE[@]}"
                     log_lightgreen "${TEST_MESSAGE[@]}"
                     log_lightyellow "${TEST_MESSAGE[@]}"
                     log_lightblue "${TEST_MESSAGE[@]}"
                     log_lightmagenta "${TEST_MESSAGE[@]}"
                     log_lightcyan "${TEST_MESSAGE[@]}"
                     log_black "${TEST_MESSAGE[@]}"
                     log_darkgray "${TEST_MESSAGE[@]}"
                     log_lightgray "${TEST_MESSAGE[@]}"
                     log_white "${TEST_MESSAGE[@]}"

                     (( ++index ))
                  done
               done
            done
         done
      done
   done

   __SWF_LOG_SPLIT_ARGUMENTS__=${SAVED_SPLIT}
   __SWF_LOG_WITH_COLOR__=${SAVED_COLOR}
   __SWF_LOG_WITH_IMAGES__=${SAVED_IMAGES}
   __SWF_LOG_WITH_FORMAT__=${SAVED_FORMAT}
   __SWF_LOG_WITH_TIMESTAMP__=${SAVED_TIMESTAMP}
   __SWF_LOG_WITH_CODEPOINT__=${SAVED_CODEPOINT}
}
