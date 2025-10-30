if [ -n "${__SFW_LOG_SH__}" ]; then
   return 0
fi
__SFW_LOG_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/constants/console.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/constants/constants.sh"



readonly __SWF_LOG_SPLIT_ARGUMENTS__=1
readonly __SWF_LOG_WITH_COLOR__=1
readonly __SWF_LOG_WITH_IMAGES__=1
readonly __SWF_LOG_WITH_FORMAT__=1
readonly __SWF_LOG_WITH_TIMESTAMP__=1



function __log__( )
{
   declare -A __TRACE_TYPE_TO_COLOR__=(
      [TRACE]=${ECHO_FG_Default}
      [DEBUG]=${ECHO_FG_LightGray}
      [INFO]=${ECHO_FG_Green}
      [NOTICE]=${ECHO_FG_LightCyan}
      [WARNING]=${ECHO_FG_Blue}
      [ERROR]=${ECHO_FG_Red}
      [CRITICAL]=${ECHO_FG_Magenta}
      [FATAL]=${ECHO_FG_Default}${ECHO_BG_Red}
   )

   declare -A __TRACE_TYPE_TO_IMAGE__=(
      [TRACE]="📝"
      [DEBUG]="🔧"
      [INFO]="ℹ️ "
      [NOTICE]="📌"
      [WARNING]="⚠️ "
      [ERROR]="❌"
      [CRITICAL]="🚨"
      [FATAL]="💀"
   )

   declare -A __TRACE_TYPE_TO_TEXT__=(
      [TRACE]="TRACE"
      [DEBUG]="DEBUG"
      [INFO]="INFO"
      [NOTICE]="NOTICE"
      [WARNING]="WARNING"
      [ERROR]="ERROR"
      [CRITICAL]="CRITICAL"
      [FATAL]="FATAL"
   )


   local LOCAL_FORMAT=$1
   local LOCAL_MESSAGE=("${!2}")

   if [[ 0 -ne ${__SWF_LOG_WITH_TIMESTAMP__} ]]; then
      printf "[$(date '+%Y-%m-%d %H:%M:%S')]   "
   fi

   if [[ 0 -ne ${__SWF_LOG_WITH_IMAGES__} ]]; then
      local emoji="${__TRACE_TYPE_TO_IMAGE__[$LOCAL_FORMAT]}"
      printf "%s%-4s" "$emoji" ""
   fi

   if [[ 0 -ne ${__SWF_LOG_WITH_FORMAT__} ]]; then
      printf "%-12s" "[${__TRACE_TYPE_TO_TEXT__[$LOCAL_FORMAT]}]"
   fi

   local COLOR=""
   local RESET_COLOR=""
   if [[ 0 -ne ${__SWF_LOG_WITH_COLOR__} ]]; then
      COLOR="${__TRACE_TYPE_TO_COLOR__[$LOCAL_FORMAT]}"
      RESET_COLOR="${ECHO_RESET}"
   fi

   if [[ 0 -eq ${__SWF_SPLIT_ARGUMENTS__} ]]; then
      # No split arguments
      printf "${COLOR}%s${RESET_COLOR}" ${LOCAL_MESSAGE[@]}
      printf "\n"
   else
      # Split arguments
      printf "${COLOR}%s${RESET_COLOR}\n" "${LOCAL_MESSAGE[@]}"
   fi
}



function log_trace( )
{
   local LOCAL_MESSAGE=$@
   __log__ TRACE LOCAL_MESSAGE[@]
}

function log_debug( )
{
   local LOCAL_MESSAGE=$@
   __log__ DEBUG LOCAL_MESSAGE[@]
}

function log_info( )
{
   local LOCAL_MESSAGE=$@
   __log__ INFO LOCAL_MESSAGE[@]
}

function log_notice( )
{
   local LOCAL_MESSAGE=$@
   __log__ NOTICE LOCAL_MESSAGE[@]
}

function log_warning( )
{
   local LOCAL_MESSAGE=$@
   __log__ WARNING LOCAL_MESSAGE[@]
}

function log_error( )
{
   local LOCAL_MESSAGE=$@
   __log__ ERROR LOCAL_MESSAGE[@]
}

function log_critical( )
{
   local LOCAL_MESSAGE=$@
   __log__ CRITICAL LOCAL_MESSAGE[@]
}

function log_fatal( )
{
   local LOCAL_MESSAGE=$@
   __log__ FATAL LOCAL_MESSAGE[@]
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
