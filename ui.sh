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
   print_info "EXECUTE START: '${COMMAND}'"
   eval "${COMMAND}"
   local EXECUTE_STATUS=$?

   if [ ${EXECUTE_STATUS} -eq 0 ]; then
      print_ok "EXECUTE FINISH (${EXECUTE_STATUS}): '${COMMAND}'"
   else
      print_error "EXECUTE FINISH (${EXECUTE_STATUS}): '${COMMAND}'"
   fi

   return ${EXECUTE_STATUS}
}

function execute_arr( )
{
   declare -n __EXECUTE_ARR_COMMAND__=${1}
   # printf "%q " "${__EXECUTE_ARR_COMMAND__[@]}"
   print_info "${__EXECUTE_ARR_COMMAND__[@]}"
   "${__EXECUTE_ARR_COMMAND__[@]}"
   local EXECUTE_STATUS=$?

   if [ ${EXECUTE_STATUS} -eq 0 ]; then
      print_ok "EXECUTE FINISH (${EXECUTE_STATUS}): '${__EXECUTE_ARR_COMMAND__[@]}'"
   else
      print_error "EXECUTE FINISH (${EXECUTE_STATUS}): '${__EXECUTE_ARR_COMMAND__[@]}'"
   fi

   return ${EXECUTE_STATUS}
}
