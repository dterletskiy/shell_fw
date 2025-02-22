if [ -n "${__SFW_ARG_PARS_SH__}" ]; then
   return 0
fi
__SFW_ARG_PARS_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/base.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/ui.sh"



readonly OPTION_DELIMITER=","

readonly PARAMETER_REQUIRED="REQUIRED"
readonly PARAMETER_OPTIONAL="OPTIONAL"

readonly PARAMETER_TYPE_ARGUMENT="ARGUMENT"
readonly PARAMETER_TYPE_OPTION="OPTION"

readonly OPTION_DEFINED="DEFINED"
readonly OPTION_NOT_DEFINED="UNDEFINED"

declare -a CMD_PARAMETERS=( )



function __split_string_add_to_array__( )
{
   local LOCAL_STRING=${1}
   local LOCAL_DELIMITER=${2}
   declare -n LOCAL_ARRAY=${3}

   IFS="${LOCAL_DELIMITER}" read -r -a __ARRAY__ <<< "${LOCAL_STRING}"
   LOCAL_ARRAY+=("${__ARRAY__[@]}")
}

function __print_parameters_help__( )
{
   for _PARAMETER_ in "${CMD_PARAMETERS[@]}"; do
      local PARAMETER=${_PARAMETER_^^}
      local _NAME_="CMD_${PARAMETER}_NAME"
      local _TYPE_="CMD_${PARAMETER}_TYPE"

      IFS=","

      local STRING="--${!_NAME_}:"$'\n'
      STRING+="   type: '${!_TYPE_}'"$'\n'
      if [ ${!_TYPE_} == ${PARAMETER_TYPE_ARGUMENT} ]; then
         local _ALLOWED_VALUES_="CMD_${PARAMETER}_ALLOWED_VALUES"
         local _DEFAULT_VALUES_="CMD_${PARAMETER}_DEFAULT_VALUES"
         local _REQUIRED_="CMD_${PARAMETER}_REQUIRED"

         STRING+="   required: '${!_REQUIRED_}'"$'\n'

         declare -n __ALLOWED_ARRAY__=${_ALLOWED_VALUES_}
         STRING+="   allowed values: '${__ALLOWED_ARRAY__[*]}' (${#__ALLOWED_ARRAY__[@]})"$'\n'

         declare -n __DEFAULT_ARRAY__=${_DEFAULT_VALUES_}
         STRING+="   default values: '${__DEFAULT_ARRAY__[*]}' (${#__DEFAULT_ARRAY__[@]})"$'\n'
      elif [ ${!_TYPE_} == ${PARAMETER_TYPE_OPTION} ]; then
         local _DEFINED_="CMD_${PARAMETER}_DEFINED"

         STRING+=""
      else
         print_error "undefined parameter type: '${PARAMETER}'"
         exit 1
      fi
      print_info ${STRING}
   done

   IFS=" "
}

function __print_parameters_info__( )
{
   for _PARAMETER_ in "${CMD_PARAMETERS[@]}"; do
      local PARAMETER=${_PARAMETER_^^}
      local _NAME_="CMD_${PARAMETER}_NAME"
      local _TYPE_="CMD_${PARAMETER}_TYPE"

      IFS=","

      local STRING="--${!_NAME_}:"$'\n'
      STRING+="   type: '${!_TYPE_}'"$'\n'
      if [ ${!_TYPE_} == ${PARAMETER_TYPE_ARGUMENT} ]; then
         local _ALLOWED_VALUES_="CMD_${PARAMETER}_ALLOWED_VALUES"
         local _DEFAULT_VALUES_="CMD_${PARAMETER}_DEFAULT_VALUES"
         local _DEFINED_VALUES_="CMD_${PARAMETER}_DEFINED_VALUES"
         local _REQUIRED_="CMD_${PARAMETER}_REQUIRED"

         STRING+="   required: '${!_REQUIRED_}'"$'\n'

         declare -n __ALLOWED_ARRAY__=${_ALLOWED_VALUES_}
         STRING+="   allowed values: '${__ALLOWED_ARRAY__[*]}' (${#__ALLOWED_ARRAY__[@]})"$'\n'

         declare -n __DEFAULT_ARRAY__=${_DEFAULT_VALUES_}
         STRING+="   default values: '${__DEFAULT_ARRAY__[*]}' (${#__DEFAULT_ARRAY__[@]})"$'\n'

         declare -n __DEFINED_ARRAY__=${_DEFINED_VALUES_}
         STRING+="   defined values: '${__DEFINED_ARRAY__[*]}' (${#__DEFINED_ARRAY__[@]})"$'\n'
      elif [ ${!_TYPE_} == ${PARAMETER_TYPE_OPTION} ]; then
         local _DEFINED_="CMD_${PARAMETER}_DEFINED"

         STRING+="   defined: '${!_DEFINED_}'"$'\n'
      else
         print_error "undefined parameter type: '${PARAMETER}'"
         exit 1
      fi
      print_info ${STRING}
   done

   IFS=" "
}

function __validate_argument__( )
{
   local LOCAL_PARAMETER_NAME=${1}
   declare -n LOCAL_PARAMETER_DEFINED_VALUES=${2}
   declare -n LOCAL_PARAMETER_ALLOWED_VALUES=${3}
   local LOCAL_PARAMETER_CRITICAL=${4}

   if [[ 0 -eq ${#LOCAL_PARAMETER_DEFINED_VALUES[@]} ]]; then
      if [[ "${PARAMETER_REQUIRED}" == "${LOCAL_PARAMETER_CRITICAL}" ]]; then
         print_error "'${LOCAL_PARAMETER_NAME}' is not defined but it is required"
         exit 1
      fi
   else
      for ITEM in "${LOCAL_PARAMETER_DEFINED_VALUES[@]}"; do
         # print_info "Processing value: '${ITEM}'"
         if [[ 0 -eq ${#LOCAL_PARAMETER_ALLOWED_VALUES[@]} ]]; then
            # print_ok "'${LOCAL_PARAMETER_NAME}' can has any value"
            :
         # elif [[ ! "${LOCAL_PARAMETER_ALLOWED_VALUES[@]}" =~ "${ITEM}" ]]; then
         elif [[ ! " ${LOCAL_PARAMETER_ALLOWED_VALUES[@]} " == *" ${ITEM} "* ]]; then
            print_error "'${LOCAL_PARAMETER_NAME}' is defined but invalid: '${ITEM}'"
            exit 1
         else
            # print_ok "'${LOCAL_PARAMETER_NAME}' is defined and valid: '${ITEM}'"
            :
         fi
      done
   fi
}

function __validate_option__( )
{
   local LOCAL_OPTION_NAME=${1}
   local LOCAL_OPTION_DEFINED=${2}

   if [ "${LOCAL_OPTION_DEFINED}" == "${OPTION_DEFINED}" ]; then
      # print_info "'${LOCAL_OPTION_NAME}' defined"
      :
   else
      # print_info "'${LOCAL_OPTION_NAME}' not defined"
      :
   fi
}

function __validate_parameters__( )
{
   for _PARAMETER_ in "${CMD_PARAMETERS[@]}"; do
      local PARAMETER=${_PARAMETER_^^}
      local _NAME_="CMD_${PARAMETER}_NAME"
      local _TYPE_="CMD_${PARAMETER}_TYPE"

      # print_info "Validating parameter: '${PARAMETER}'"
      if [ ${!_TYPE_} == ${PARAMETER_TYPE_ARGUMENT} ]; then
         local _DEFINED_VALUES_="CMD_${PARAMETER}_DEFINED_VALUES"
         local _ALLOWED_VALUES_="CMD_${PARAMETER}_ALLOWED_VALUES"
         local _REQUIRED_="CMD_${PARAMETER}_REQUIRED"
         __validate_argument__ ${!_NAME_} ${_DEFINED_VALUES_} ${_ALLOWED_VALUES_} ${!_REQUIRED_}
      elif [ ${!_TYPE_} == ${PARAMETER_TYPE_OPTION} ]; then
         local _DEFINED_="CMD_${PARAMETER}_DEFINED"
         __validate_option__ ${!_NAME_} ${!_DEFINED_}
      else
         print_error "undefined parameter type: '${PARAMETER}'"
         exit 1
      fi
   done
}

# parse_arguments ${@}
function parse_arguments( )
{
   for option in "$@"; do
      if [[ ${option} == --help ]]; then
         __print_parameters_help__
         exit 0
      fi

      local OPTION_PROCESSED=0
      for _PARAMETER_ in "${CMD_PARAMETERS[@]}"; do
         local PARAMETER=${_PARAMETER_^^}
         local _NAME_="CMD_${PARAMETER}_NAME"
         local _TYPE_="CMD_${PARAMETER}_TYPE"
         local _DEFINED_VALUES_="CMD_${PARAMETER}_DEFINED_VALUES"

         if [ ${!_TYPE_} == ${PARAMETER_TYPE_ARGUMENT} ]; then
            if [[ ${option} == --${!_NAME_}=* ]]; then
               local __TEMP__="${option#*=}"
               if [ -z "${__TEMP__}" ]; then
                  print_error "'--${!_NAME_}' is defined but has no value"
                  exit 1
               fi
               __split_string_add_to_array__ "${__TEMP__}" ${OPTION_DELIMITER} ${_DEFINED_VALUES_}
               OPTION_PROCESSED=1
               break
            fi
         elif [ ${!_TYPE_} == ${PARAMETER_TYPE_OPTION} ]; then
            if [[ ${option} == --${!_NAME_} ]]; then
               eval "CMD_${PARAMETER}_DEFINED=${OPTION_DEFINED}"
               OPTION_PROCESSED=1
               break
            fi
         fi
      done

      if [[ ${OPTION_PROCESSED} -eq 0 ]]; then
         print_error "unsupported parameter '${option}'"
         exit 1
      fi
   done

   __validate_parameters__

   __print_parameters_info__
}



function __test_defined_parameter__( )
{
   local LOCAL_NAME=${1}
   local LOCAL_NAME_UP="${LOCAL_NAME^^}"


   local _NAME_="CMD_${LOCAL_NAME_UP}_NAME"
   if [ -z ${!_NAME_+x} ]; then
      print_error "'${_NAME_}' is not defined"
      exit 1
   fi

   local _TYPE_="CMD_${LOCAL_NAME_UP}_TYPE"
   if [ -z ${!_TYPE_+x} ]; then
      print_error "'${_TYPE_}' is not defined"
      exit 1
   fi

   if [ ${!_TYPE_} == ${PARAMETER_TYPE_ARGUMENT} ]; then
      local _REQUIRED_="CMD_${LOCAL_NAME_UP}_REQUIRED"
      if [ -z ${!_REQUIRED_+x} ]; then
         print_error "'${_REQUIRED_}' is not defined"
         exit 1
      fi

      local _ALLOWED_VALUES_="CMD_${LOCAL_NAME_UP}_ALLOWED_VALUES"
      if ! declare -p ${_ALLOWED_VALUES_} 2>/dev/null | grep -q 'declare -a'; then
         print_error "'${_ALLOWED_VALUES_}' is not defined 3"
      fi

      local _DEFAULT_VALUES_="CMD_${LOCAL_NAME_UP}_DEFAULT_VALUES"
      if ! declare -p ${_DEFAULT_VALUES_} 2>/dev/null | grep -q 'declare -a'; then
         print_error "'${_DEFAULT_VALUES_}' is not defined 3"
      fi

      local _DEFINED_VALUES_="CMD_${LOCAL_NAME_UP}_DEFINED_VALUES"
      if ! declare -p ${_DEFINED_VALUES_} 2>/dev/null | grep -q 'declare -a'; then
         print_error "'${_DEFINED_VALUES_}' is not defined 3"
      fi
   elif [ ${!_TYPE_} == ${PARAMETER_TYPE_OPTION} ]; then
      local _DEFINED_="CMD_${LOCAL_NAME_UP}_DEFINED"
      if [ -z ${!_DEFINED_+x} ]; then
         print_error "'${_DEFINED_}' is not defined"
         exit 1
      fi
   else
      print_error "undefined parameter type: '${!_NAME_}'"
      exit 1
   fi
}

function __define_argument__( )
{
   local LOCAL_NAME=${1}
   local LOCAL_TYPE=${2}
   local LOCAL_REQUIRED=${3}
   # declare -n LOCAL_PARAMETER_VALUES_ALLOWED=${4}
   declare -a LOCAL_PARAMETER_VALUES_ALLOWED=(${4})
   # declare -n LOCAL_PARAMETER_VALUES_DEFAULT=${5}
   declare -a LOCAL_PARAMETER_VALUES_DEFAULT=(${5})

   local LOCAL_NAME_UP="${LOCAL_NAME^^}"

   declare -g "CMD_${LOCAL_NAME_UP}_NAME=${LOCAL_NAME}"
   declare -g "CMD_${LOCAL_NAME_UP}_TYPE=${PARAMETER_TYPE_ARGUMENT}"
   declare -g "CMD_${LOCAL_NAME_UP}_REQUIRED=${LOCAL_REQUIRED}"
   declare -ag "CMD_${LOCAL_NAME_UP}_ALLOWED_VALUES=(\"\${LOCAL_PARAMETER_VALUES_ALLOWED[@]}\")"
   declare -ag "CMD_${LOCAL_NAME_UP}_DEFAULT_VALUES=(\"\${LOCAL_PARAMETER_VALUES_DEFAULT[@]}\")"
   declare -ag "CMD_${LOCAL_NAME_UP}_DEFINED_VALUES=( )"
}

function __define_option__( )
{
   local LOCAL_NAME=${1}
   local LOCAL_TYPE=${2}

   local LOCAL_NAME_UP="${LOCAL_NAME^^}"

   eval "readonly CMD_${LOCAL_NAME_UP}_NAME=\"${LOCAL_NAME}\""
   eval "readonly CMD_${LOCAL_NAME_UP}_TYPE=${PARAMETER_TYPE_OPTION}"
   eval "CMD_${LOCAL_NAME_UP}_DEFINED=${OPTION_NOT_DEFINED}"
}

# __define_parameter__ "name" "type" \
#    ["required/not_required" ["allowed_value_1 ... allowed_value_n" ["default_value_1 ... default_value_n"]]]
function __define_parameter__( )
{
   local LOCAL_NAME=${1}
   local LOCAL_TYPE=${2}

   if [ ${LOCAL_TYPE} == ${PARAMETER_TYPE_ARGUMENT} ]; then
      __define_argument__ "$@"
   elif [ ${LOCAL_TYPE} == ${PARAMETER_TYPE_OPTION} ]; then
      __define_option__ "$@"
   else
      print_error "undefined parameter type: '${LOCAL_NAME}'"
      exit 1
   fi

   CMD_PARAMETERS+=( "${LOCAL_NAME}" )
   __test_defined_parameter__ ${LOCAL_NAME}
}

# define_required_argument "name" \
#    [--allowed="allowed_value_1 ... allowed_value_n"]
function define_required_argument( )
{
   local LOCAL_NAME="${1}"

   local LOCAL_ALLOWED_VALUES=""
   local LOCAL_DEFAULT_VALUES=""

   for PARAMETER in "${@}"; do
      case ${PARAMETER} in
         --allowed=*)
            LOCAL_ALLOWED_VALUES="${PARAMETER#*=}"
            shift
         ;;
      esac
   done

   __define_parameter__ "${LOCAL_NAME}" "${PARAMETER_TYPE_ARGUMENT}" "${PARAMETER_REQUIRED}" \
      "${LOCAL_ALLOWED_VALUES}" "${LOCAL_DEFAULT_VALUES}"
}

# define_optional_argument "name" \
#    [--allowed="allowed_value_1 ... allowed_value_n"] \
#    [--default="default_value_1 ... default_value_n"]
function define_optional_argument( )
{
   local LOCAL_NAME="${1}"

   local LOCAL_ALLOWED_VALUES=""
   local LOCAL_DEFAULT_VALUES=""

   for PARAMETER in "${@}"; do
      case ${PARAMETER} in
         --allowed=*)
            LOCAL_ALLOWED_VALUES="${PARAMETER#*=}"
            shift
         ;;
         --default=*)
            LOCAL_DEFAULT_VALUES="${PARAMETER#*=}"
            shift
         ;;
      esac
   done

   __define_parameter__ "${LOCAL_NAME}" "${PARAMETER_TYPE_ARGUMENT}" "${PARAMETER_OPTIONAL}" \
      "${LOCAL_ALLOWED_VALUES}" "${LOCAL_DEFAULT_VALUES}"
}

# define_option "name"
function define_option( )
{
   local LOCAL_NAME="${1}"

   __define_parameter__ "${LOCAL_NAME}" "${PARAMETER_TYPE_OPTION}"
}

# echo $( get_option "dlt" [--pos="true"] [--neg="false"] )
function get_option( )
{
   local LOCAL_NAME=${1}

   local LOCAL_POS_VALUE="yes"
   local LOCAL_NEG_VALUE="no"
   local LOCAL_ERR_VALUE="no"

   for PARAMETER in "${@}"; do
      case ${PARAMETER} in
         --pos=*)
            LOCAL_POS_VALUE="${PARAMETER#*=}"
            shift
         ;;
         --neg=*)
            LOCAL_NEG_VALUE="${PARAMETER#*=}"
            shift
         ;;
         *)
            :
         ;;
      esac
   done

   local LOCAL_NAME_UP="${LOCAL_NAME^^}"

   local LOCAL_OPTION_VARIABLE_NAME="CMD_${LOCAL_NAME_UP}_DEFINED"
   local _DEFINED_=${!LOCAL_OPTION_VARIABLE_NAME}
   local LOCAL_RESULT=${LOCAL_ERR_VALUE}
   # print_info "Processing option '${LOCAL_NAME}' => ${LOCAL_OPTION_VARIABLE_NAME} = ${_DEFINED_}"

   if [ ${_DEFINED_} == ${OPTION_DEFINED} ]; then
      LOCAL_RESULT=${LOCAL_POS_VALUE}
      # print_info "option '${LOCAL_NAME}' defined"
   elif [ ${_DEFINED_} == ${OPTION_NOT_DEFINED} ]; then
      LOCAL_RESULT=${LOCAL_NEG_VALUE}
      # print_info "option '${LOCAL_NAME}' not defined"
   elif [ -z ${_DEFINED_+x} ]; then
      LOCAL_RESULT=${LOCAL_ERR_VALUE}
      # print_error "invalid option '${LOCAL_NAME}'"
   else
      LOCAL_RESULT=${LOCAL_ERR_VALUE}
      # print_error "invalid option '${LOCAL_NAME}' = ${_DEFINED_}"
   fi

   echo ${LOCAL_RESULT}
}

# declare -a VALUES=( )
# get_parameter_values "test" VALUES
# print_info "${VALUES[*]}"
function get_parameter_values( )
{
   local LOCAL_NAME=${1}
   declare -n LOCAL_VALUES=${2}

   local LOCAL_NAME_UP="${LOCAL_NAME^^}"
   declare -n LOCAL_DEFINED_VALUES="CMD_${LOCAL_NAME_UP}_DEFINED_VALUES"

   if [[ 0 -ne ${#LOCAL_DEFINED_VALUES[@]} ]]; then
      LOCAL_VALUES=("${LOCAL_DEFINED_VALUES[@]}")
   else
      declare -n LOCAL_DEFAULT_VALUES="CMD_${LOCAL_NAME_UP}_DEFAULT_VALUES"
      LOCAL_VALUES=("${LOCAL_DEFAULT_VALUES[@]}")
   fi
}
