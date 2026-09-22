#!/bin/bash



readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly SHELL_FW=${SCRIPT_DIR}/shell_fw/
if [ ! -e "${SHELL_FW}/.git" ]; then
   git clone "https://github.com/dterletskiy/shell_fw.git" ${SHELL_FW}
   RETURN_CODE=$?
   if [ 0 -ne ${RETURN_CODE} ]; then
      echo "'shell framework' clone error."
      exit ${RETURN_CODE}
   fi
fi
source ${SHELL_FW}/__init__



function test_arg_pars_jq( )
{
   local __PARAMETERS__="{}"

   register_argument --registry=__PARAMETERS__ \
      --name="project" \
      --allowed_values="aosp,kernel,uboot" \
      --required \
      || return $?
   register_argument --registry=__PARAMETERS__ \
      --name="action" \
      --allowed_values="info,sync,config,build,deploy,clean" \
      --default_values="info" \
      || return $?
   register_argument --registry=__PARAMETERS__ \
      --name="target" \
      || return $?
   register_option --registry=__PARAMETERS__ \
      --name="help" \
      || return $?
   register_option --registry=__PARAMETERS__ \
      --name="debug" \
      || return $?

   echo "${__PARAMETERS__}" | jq .
   parse_parameters __PARAMETERS__ "${@}" || return $?
   echo "${__PARAMETERS__}" | jq .
   validate_parameters __PARAMETERS__ || return $?

   local result

   log_info "Get argument 'project'"
   get_argument_value --registry=__PARAMETERS__ --name="project" --result=result
   echo "   $?: ${result}"

   log_info "Get argument 'action'"
   get_argument_value --registry=__PARAMETERS__ --name="action" --result=result
   echo "   $?: ${result}"

   log_info "Get argument 'target'"
   get_argument_value --registry=__PARAMETERS__ --name="target" --result=result
   echo "   $?: ${result}"

   log_info "Get argument 'xxxxx'"
   get_argument_value --registry=__PARAMETERS__ --name="xxxxx" --result=result
   echo "   $?: ${result}"

   log_info "Get option 'debug'"
   get_option --registry=__PARAMETERS__ --name="debug" --result=result
   echo "   $?: ${result}"

   log_info "Get option 'yyyyy'"
   get_option --registry=__PARAMETERS__ --name="yyyyy" --result=result
   echo "   $?: ${result}"

   log_info "Test option 'debug'"
   test_option --registry=__PARAMETERS__ --name="debug"
   echo "   $?"

   log_info "Test option 'help'"
   test_option --registry=__PARAMETERS__ --name="help"
   echo "   $?"

   log_info "Test option 'yyyyy'"
   test_option --registry=__PARAMETERS__ --name="yyyyy"
   echo "   $?"
}

test_arg_pars_jq "${@}"
exit $?
