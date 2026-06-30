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



define_required_argument "project" \
   --allowed="uboot kernel aosp" \

define_optional_argument "action" \
   --allowed="info sync config build deploy" \
   --default="info"

define_required_argument "source_dir"

define_optional_argument "build_dir"

define_optional_argument "deploy_dir"

define_option "debug"

define_option "verbose"



function build( )
{
   declare -n CMD_PARAMETERS_MAP=${1}

   local -A RESOLVED_PARAMETERS
   copy_map RESOLVED_PARAMETERS CMD_PARAMETERS_MAP

   local -r REQUIRED_PARAMETERS=(
         "SOURCE_DIR"
      )
   validate_require_function_params RESOLVED_PARAMETERS REQUIRED_PARAMETERS || return $?

   declare -A DEFAULT_PARAMETERS=(
         [INSTALL_DIR]="__BUILD_DIR__/install"
         [BUILD_DIR]="__SOURCE_DIR__/build"
      )
   validate_default_function_params RESOLVED_PARAMETERS DEFAULT_PARAMETERS

   print_map RESOLVED_PARAMETERS



   return 0
}




parse_arguments "${@}"
print_parameters_info

echo "$( get_parameter_value "source_dir" )"
declare -A PARAMETERS=(
      [SOURCE_DIR]="$( get_parameter_value "source_dir" )"
      [BUILD_DIR]="$( get_parameter_value "build_dir" )"
      [INSTALL_DIR]="$( get_parameter_value "deploy_dir" )"
   )
build PARAMETERS





exit 0







function define_variable( )
{
   local NAME=${1}
   local NAME_UP="${NAME^^}"

   echo ${NAME}
   echo ${NAME_UP}

   declare -g "CMD_${NAME_UP}_VARIABLE=${NAME}"

   eval "CMD_${NAME_UP}_VARIABLE=${NAME}"

   declare -g "CMD_${NAME_UP}_VARIABLE"
   printf -v "CMD_${NAME_UP}_VARIABLE" '%s' "$NAME"
}

var_exists CMD_DEBUG_VARIABLE && echo yes || echo no
var_exists CMD_DEBUG_VARIABLE_ && echo yes || echo no
define_variable debug
var_exists CMD_DEBUG_VARIABLE && echo yes || echo no
var_exists CMD_DEBUG_VARIABLE_ && echo yes || echo no
