[ -n "${__SFW_UI_SH__}" ] && return 0 || readonly __SFW_UI_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"



function press_enter( )
{
   #echo -e ${ECHO_FG_Magenta}
   #read -p "Press enter to continue..."
   #echo -e ${ECHO_RESET}
   read -p "$(echo -e ${ECHO_FG_Magenta})Press enter to continue...$(echo -e ${ECHO_RESET})"
}
function press_any_key( )
{
   #echo -e ${ECHO_FG_Magenta}
   #read -n 1 -s -r -p "Press any key to continue..."
   #echo -e ${ECHO_RESET}
   read -n 1 -s -r -p "$(echo -e ${ECHO_FG_Magenta})Press any key to continue...$(echo -e ${ECHO_RESET})"
   echo ""
}

# LIST=( "A" "B" "C" )
# CHOICE=""
# choose_from_array LIST CHOICE
# echo "CHOICE: " ${CHOICE}
function choose_from_array( )
{
   # local LIST=("$@")
   local -n ARRAY=${1}
   local -n LOCAL_RESULT=${2}

   print_promt "Choose target:"
   select ITEM in "${ARRAY[@]}"; do
      if [ -n "${ITEM}" ]; then break; fi
   done

   LOCAL_RESULT=${ITEM}
}

function enter_choice( )
{
   local LOCAL_RESULT=""
   local LOCAL_MESSAGE=$@
   read -p "$(echo -e ${ECHO_FG_Magenta})${LOCAL_MESSAGE}: $(echo -e ${ECHO_RESET})" LOCAL_RESULT
   echo $LOCAL_RESULT
}

function execute( )
{
   local COMMAND="${@}"
   log_debug "EXECUTE START: '${COMMAND}'"
   eval "${COMMAND}"
   local EXECUTE_STATUS=$?

   if [ ${EXECUTE_STATUS} -eq 0 ]; then
      log_info "EXECUTE FINISH (${EXECUTE_STATUS}): '${COMMAND}'"
   else
      log_error "EXECUTE FINISH (${EXECUTE_STATUS}): '${COMMAND}'"
   fi

   return ${EXECUTE_STATUS}
}

function execute_arr( )
{
   declare -n __EXECUTE_ARR_COMMAND__=${1}
   # printf "%q " "${__EXECUTE_ARR_COMMAND__[@]}"
   log_debug "${__EXECUTE_ARR_COMMAND__[@]}"
   "${__EXECUTE_ARR_COMMAND__[@]}"
   local EXECUTE_STATUS=$?

   if [ ${EXECUTE_STATUS} -eq 0 ]; then
      log_info "EXECUTE FINISH (${EXECUTE_STATUS}): '${__EXECUTE_ARR_COMMAND__[@]}'"
   else
      log_error "EXECUTE FINISH (${EXECUTE_STATUS}): '${__EXECUTE_ARR_COMMAND__[@]}'"
   fi

   return ${EXECUTE_STATUS}
}



##
# @brief Check if a required utility is available in PATH.
#
# This function verifies that the specified command-line utility exists
# and is accessible via the current PATH environment variable.
#
# @param[in]  $1   Name of the utility to check (e.g. "jq", "cp").
#
# @return 0    Utility is found and executable.
# @return 127  Utility is not found in PATH.
#
# @details
# Uses `command -v` to test for availability in a POSIX-compliant way.
# If the utility is missing, an error message is printed to stderr.
#
# @note
# This function does not terminate the script. Caller should handle
# the return code explicitly if required.
#
# @warning
# Argument must be a valid command name. No validation is performed
# for empty or malformed input.
#
# @code
# test_required_util "jq" || exit $?
# @endcode
#
function test_required_util( )
{
   local UTIL=${1}

   if ! command -v ${UTIL} > /dev/null 2>&1; then
      log_error "Error: '${UTIL}' is required but not installed" >&2
      return 127
   fi
}



# var_exists()
#
# Checks whether a variable exists, regardless of whether its value
# is empty.
#
# Parameters:
#   $1 - Variable name
#
# Return values:
#   0 - Variable exists
#   1 - Variable does not exist
#
# Notes:
#   - Uses [[ -v ]] on Bash 4.2+
#   - Falls back to parameter expansion on older Bash versions
#
var_exists()
{
   local var_name=$1

   if (( BASH_VERSINFO[0] > 4 )) ||
      (( BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2 ))
   then
      [[ -v $var_name ]]
   else
      [[ ${!var_name+x} ]]
   fi
}
