[ -n "${__SFW_ARG_PARS_SH__}" ] && return 0 || readonly __SFW_ARG_PARS_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/ui.sh"



readonly __SFW_OPTION_DELIMITER__=","

readonly __SFW_PARAMETER_REQUIRED__="REQUIRED"
readonly __SFW_PARAMETER_OPTIONAL__="OPTIONAL"

readonly __SFW_PARAMETER_TYPE_ARGUMENT__="ARGUMENT"
readonly __SFW_PARAMETER_TYPE_OPTION__="OPTION"

readonly __SFW_OPTION_DEFINED__="DEFINED"
readonly __SFW_OPTION_NOT_DEFINED__="UNDEFINED"

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
   __print_parameters_info__
}

function __print_parameters_info__( )
{
   for _PARAMETER_ in "${CMD_PARAMETERS[@]}"; do
      local PARAMETER=${_PARAMETER_^^}
      local _NAME_="CMD_${PARAMETER}_NAME"
      local _TYPE_="CMD_${PARAMETER}_TYPE"

      local IFS_BACKUP=${IFS}
      IFS=","

      local STRING_NAME="--${!_NAME_}:"
      local STRING="   type: '${!_TYPE_}'"$'\n'
      if [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_ARGUMENT__} ]; then
         local _ALLOWED_VALUES_="CMD_${PARAMETER}_ALLOWED_VALUES"
         local _DEFAULT_VALUES_="CMD_${PARAMETER}_DEFAULT_VALUES"
         local _DEFINED_VALUES_="CMD_${PARAMETER}_DEFINED_VALUES"
         local _REQUIRED_="CMD_${PARAMETER}_REQUIRED"

         STRING+="   required: '${!_REQUIRED_}'"$'\n'

         STRING+="   values:"$'\n'

         declare -n __ALLOWED_ARRAY__=${_ALLOWED_VALUES_}
         STRING+="      allowed [${#__ALLOWED_ARRAY__[@]}]: '${__ALLOWED_ARRAY__[*]}'"$'\n'

         declare -n __DEFAULT_ARRAY__=${_DEFAULT_VALUES_}
         STRING+="      default [${#__DEFAULT_ARRAY__[@]}]: '${__DEFAULT_ARRAY__[*]}'"$'\n'

         declare -n __DEFINED_ARRAY__=${_DEFINED_VALUES_}
         STRING+="      defined [${#__DEFINED_ARRAY__[@]}]: '${__DEFINED_ARRAY__[*]}'"$'\n'
      elif [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_OPTION__} ]; then
         local _DEFINED_="CMD_${PARAMETER}_DEFINED"

         STRING+="   defined: '${!_DEFINED_}'"$'\n'
      else
         print_error "undefined parameter type: '${PARAMETER}'"
         exit 1
      fi
      print_ok ${STRING_NAME}
      print_info ${STRING}
   done

   # IFS=" "
   IFS=${IFS_BACKUP}
}

function __validate_argument__( )
{
   local LOCAL_PARAMETER_NAME=${1}
   declare -n LOCAL_PARAMETER_DEFINED_VALUES=${2}
   declare -n LOCAL_PARAMETER_ALLOWED_VALUES=${3}
   local LOCAL_PARAMETER_CRITICAL=${4}

   if [[ 0 -eq ${#LOCAL_PARAMETER_DEFINED_VALUES[@]} ]]; then
      if [[ "${__SFW_PARAMETER_REQUIRED__}" == "${LOCAL_PARAMETER_CRITICAL}" ]]; then
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

   if [ "${LOCAL_OPTION_DEFINED}" == "${__SFW_OPTION_DEFINED__}" ]; then
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
      if [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_ARGUMENT__} ]; then
         local _DEFINED_VALUES_="CMD_${PARAMETER}_DEFINED_VALUES"
         local _ALLOWED_VALUES_="CMD_${PARAMETER}_ALLOWED_VALUES"
         local _REQUIRED_="CMD_${PARAMETER}_REQUIRED"
         __validate_argument__ ${!_NAME_} ${_DEFINED_VALUES_} ${_ALLOWED_VALUES_} ${!_REQUIRED_}
      elif [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_OPTION__} ]; then
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

         if [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_ARGUMENT__} ]; then
            if [[ ${option} == --${!_NAME_}=* ]]; then
               local __TEMP__="${option#*=}"
               if [ -z "${__TEMP__}" ]; then
                  print_error "'--${!_NAME_}' is defined but has no value"
                  exit 1
               fi
               __split_string_add_to_array__ "${__TEMP__}" \
                        ${__SFW_OPTION_DELIMITER__} ${_DEFINED_VALUES_}
               OPTION_PROCESSED=1
               break
            fi
         elif [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_OPTION__} ]; then
            if [[ ${option} == --${!_NAME_} ]]; then
               declare "CMD_${PARAMETER}_DEFINED=${__SFW_OPTION_DEFINED__}"
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

   if [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_ARGUMENT__} ]; then
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
   elif [ ${!_TYPE_} == ${__SFW_PARAMETER_TYPE_OPTION__} ]; then
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

# Calling this function like this:
# __define_parameter__ "xxxxx" "ARGUMENT" \
#    ["REQUIRED" ["allowed_value_1 ... allowed_value_n" ["default_value_1 ... default_value_n"]]]
# automatically defined next varuables:
#    - CMD_XXXXX_NAME="xxxxx"
#    - CMD_XXXXX_TYPE="ARGUMENT"
#    - CMD_XXXXX_REQUIRED="REQUIRED"
#    - CMD_XXXXX_ALLOWED_VALUES=( "allowed_value_1" ... "allowed_value_n" )
#    - CMD_XXXXX_DEFAULT_VALUES=( "default_value_1" ... "default_value_n" )
#    - CMD_XXXXX_DEFINED_VALUES=( )
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
   declare -g "CMD_${LOCAL_NAME_UP}_TYPE=${__SFW_PARAMETER_TYPE_ARGUMENT__}"
   declare -g "CMD_${LOCAL_NAME_UP}_REQUIRED=${LOCAL_REQUIRED}"
   declare -ag "CMD_${LOCAL_NAME_UP}_ALLOWED_VALUES=(\"\${LOCAL_PARAMETER_VALUES_ALLOWED[@]}\")"
   declare -ag "CMD_${LOCAL_NAME_UP}_DEFAULT_VALUES=(\"\${LOCAL_PARAMETER_VALUES_DEFAULT[@]}\")"
   declare -ag "CMD_${LOCAL_NAME_UP}_DEFINED_VALUES=( )"
}

# Calling this function like this:
# __define_parameter__ "xxxxx" "OPTION"
# automatically defined next varuables:
#    - CMD_XXXXX_NAME="xxxxx"
#    - CMD_XXXXX_TYPE="OPTION"
#    - CMD_XXXXX_DEFINED="UNDEFINED"
function __define_option__( )
{
   local LOCAL_NAME=${1}
   local LOCAL_TYPE=${2}

   local LOCAL_NAME_UP="${LOCAL_NAME^^}"

   eval "readonly CMD_${LOCAL_NAME_UP}_NAME=\"${LOCAL_NAME}\""
   eval "readonly CMD_${LOCAL_NAME_UP}_TYPE=${__SFW_PARAMETER_TYPE_OPTION__}"
   eval "CMD_${LOCAL_NAME_UP}_DEFINED=${__SFW_OPTION_NOT_DEFINED__}"
}

# __define_parameter__ "name" "ARGUMENT|OPTION" \
#    ["REQUIRED|OPTIONAL" ["allowed_value_1 ... allowed_value_n" ["default_value_1 ... default_value_n"]]]
function __define_parameter__( )
{
   local LOCAL_NAME=${1}
   local LOCAL_TYPE=${2}

   if [ ${LOCAL_TYPE} == ${__SFW_PARAMETER_TYPE_ARGUMENT__} ]; then
      __define_argument__ "$@"
   elif [ ${LOCAL_TYPE} == ${__SFW_PARAMETER_TYPE_OPTION__} ]; then
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

   __define_parameter__ "${LOCAL_NAME}" "${__SFW_PARAMETER_TYPE_ARGUMENT__}" \
      "${__SFW_PARAMETER_REQUIRED__}" \
      "${LOCAL_ALLOWED_VALUES}" \
      "${LOCAL_DEFAULT_VALUES}"
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

   __define_parameter__ "${LOCAL_NAME}" "${__SFW_PARAMETER_TYPE_ARGUMENT__}" \
      "${__SFW_PARAMETER_OPTIONAL__}" \
      "${LOCAL_ALLOWED_VALUES}" \
      "${LOCAL_DEFAULT_VALUES}"
}

# define_option "name"
function define_option( )
{
   local LOCAL_NAME="${1}"

   __define_parameter__ "${LOCAL_NAME}" "${__SFW_PARAMETER_TYPE_OPTION__}"
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

   if [ ${_DEFINED_} == ${__SFW_OPTION_DEFINED__} ]; then
      LOCAL_RESULT=${LOCAL_POS_VALUE}
      # print_info "option '${LOCAL_NAME}' defined"
   elif [ ${_DEFINED_} == ${__SFW_OPTION_NOT_DEFINED__} ]; then
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

# This method returns the value of the parameter with name defined in the first argument
# and by index optionally defined in the second argument. If index is not passed 0 will
# be used by default.
# If parameter was not passed in the command line then default values will be processed.
# print_info $( get_parameter_value "name" [index] )
function get_parameter_value( )
{
   local LOCAL_NAME=${1}
   local LOCAL_INDEX=${2:-0}

   local LOCAL_VALUE=""
   get_parameter_values ${LOCAL_NAME} VALUES
   if [[ 0 -eq ${#VALUES[@]} ]]; then
      LOCAL_VALUE=""
   elif [[ ${LOCAL_INDEX} -ge ${#VALUES[@]} ]]; then
      LOCAL_VALUE=${VALUES[-1]}
   else
      LOCAL_VALUE=${VALUES[${LOCAL_INDEX}]}
   fi

   echo ${LOCAL_VALUE}
}




# Description:
# 'filer_parameters' filters a list of command-line arguments and returns only
# those arguments and options whose keys are explicitly allowed.
# The function supports arguments in the following forms:
#     --option — a standalone flag
#     --arg=value — an option with an inline value
# Only the argument name (the part before =) is evaluated.
# The value, if present, is preserved unchanged.
# 
# Behavior:
# - Iterates over all arguments in source_array
# - Extracts the argument key:
#     --arg=value → --arg
#     --option → --option
# - Compares the extracted key against allowed_keys_array
# - If a match is found, the original argument is added to output_array
# - Argument values are not modified or validated
# 
# Notes:
# - Requires Bash 4.3+ due to use of local -n
# - Does not support space-separated values (--arg value)
# - Comparison is strict (exact string match)
# - Order of arguments is preserved
function filer_parameters( )
{
   local -n _FP_INPUT_=${1}
   local -n _FP_FILTER_=${2}
   local -n _FP_OUTPUT_=${3}

   _FP_OUTPUT_=( )

   for arg in "${_FP_INPUT_[@]}"; do
      local key="${arg%%=*}"

      for allowed in "${_FP_FILTER_[@]}"; do
         if [[ "$key" == "${allowed}" ]]; then
            _FP_OUTPUT_+=( "$arg" )
            break
         fi
      done
   done

   log_info "INPUT:  ${_FP_INPUT_[@]}"
   log_info "FILTER: ${_FP_FILTER_[@]}"
   log_info "OUTPUT: ${_FP_OUTPUT_[@]}"
}



# Description:
# 'map_parameters' transforms a list of command-line arguments using 
# a mapping dictionary.
# The function accepts a list of arguments in the form:
#     --option — a standalone flag
#     --arg=value — an option with an inline value
# 
# Each matched argument key is replaced with the corresponding value 
# from the dictionary, while the argument value (if present) is preserved.
# 
# Function Signature:
# map_parameters <source_array> <mapping_dictionary> <output_array>
# 
# Parameters:
# source_array - Name of the array containing the original command-line arguments.
# mapping_dictionary - Name of an associative array where:
#     - the key is an argument name (e.g. --width)
#     - the value is the string that should replace it in the output (e.g. -w)
# output_array - Name of the array that will receive the filtered and transformed arguments.
# 
# All parameters are passed by reference using Bash namerefs (local -n).
function map_parameters( )
{
   local -n _MP_INPUT_=${1}
   local -n _MP_MAP_=${2}
   local -n _MP_OUTPUT_=${3}

   _MP_OUTPUT_=( )

   for arg in "${_MP_INPUT_[@]}"; do
      local key="${arg%%=*}"
      local value=""

      if [[ "$arg" == *"="* ]]; then
         value="=${arg#*=}"
      fi

      if [[ -n "${_MP_MAP_[$key]+_}" ]]; then
         _MP_OUTPUT_+=( "${_MP_MAP_[$key]}${value}" )
      else
         _MP_OUTPUT_+=( "${arg}" )
      fi
   done

   log_info "INPUT:  ${_MP_INPUT_[@]}"
   log_info "MAP:"
   for key in "${!_MP_MAP_[@]}"; do
      log_info "   ${key} = ${_MP_MAP_[$key]}"
   done
   log_info "OUTPUT: ${_MP_OUTPUT_[@]}"
}



# Description:
# 'filter_map_parameters' filters and transforms a list of command-line arguments using 
# a mapping dictionary.
# The function accepts a list of arguments in the form:
#     --option — a standalone flag
#     --arg=value — an option with an inline value
# 
# Only arguments whose keys exist in the provided mapping dictionary 
# are included in the output.
# Each matched argument key is replaced with the corresponding value 
# from the dictionary, while the argument value (if present) is preserved.
# 
# Function Signature:
# map_args <source_array> <mapping_dictionary> <output_array>
# 
# Parameters:
# source_array - Name of the array containing the original command-line arguments.
# mapping_dictionary - Name of an associative array where:
#     - the key is an allowed argument name (e.g. --width)
#     - the value is the string that should replace it in the output (e.g. -w)
# output_array - Name of the array that will receive the filtered and transformed arguments.
# 
# All parameters are passed by reference using Bash namerefs (local -n).
function filter_map_parameters( )
{
   local -n _FMP_INPUT_=${1}
   local -n _FMP_MAP_=${2}
   local -n _FMP_OUTPUT_=${3}

   _FMP_OUTPUT_=( )
   _FMP_OUTPUT_TMP_=( )
   filter=( "${!_FMP_MAP_[@]}" )
   filer_parameters _FMP_INPUT_ filter _FMP_OUTPUT_TMP_
   map_parameters _FMP_OUTPUT_TMP_ _FMP_MAP_ _FMP_OUTPUT_
}



function __test_parameters_transform__( )
{
   parameters=(
         "--width=100"
         "--height=200"
         "--debug"
         "--debug=5"
         "--test"
         "--id=10"
      )

   filter=(
         "--width"
         "--height"
         "--debug"
      )

   declare -A map=(
         [--debug]="--verbose"
      )

   output=( )
   log_warning "filter"
   filer_parameters parameters filter output
   log_warning "map"
   map_parameters parameters map output
   log_warning "filter and map"
   filter_map_parameters parameters map output
}




# Usage example:
#
# ----------------------------------------------------------------------
# #!/bin/bash
#
# source ./sfw/__init__
#
# define_required_argument "action" \
#    --allowed="fetch config build install"
#
# define_optional_argument "target" \
#    --allowed="framework application all" \
#    --default="all"
#
# define_option "debug"
#
# parse_arguments "${@}"
#
# print_info $( get_option "debug" --pos="true" --neg="false" )
#
# get_parameter_values "action" VALUES
# print_info "${VALUES[*]}"
#
# print_info $( get_parameter_value "target" 0 )
#
# ----------------------------------------------------------------------
#
# ./__test__ --action=fetch --debug --action=config,build






















__define_argument_ext__( )
{
   local name="$1"
   local type="$2"
   local required="$3"
   local allowed_src="$4"
   local default_src="$5"

   # Преобразуем имя аргумента в верхний регистр
   local name_up="${name^^}"

   # Создаём глобальные переменные (безопасно, без eval)
   declare -g "CMD_${name_up}_NAME=$name"
   declare -g "CMD_${name_up}_TYPE=$type"
   declare -g "CMD_${name_up}_REQUIRED=$required"

   # Создаём пустые глобальные массивы
   declare -g -a "CMD_${name_up}_ALLOWED_VALUES=()"
   declare -g -a "CMD_${name_up}_DEFAULT_VALUES=()"
   declare -g -a "CMD_${name_up}_DEFINED_VALUES=()"

   # Создаём ссылки на эти массивы
   local -n allowed_ref="CMD_${name_up}_ALLOWED_VALUES"
   local -n default_ref="CMD_${name_up}_DEFAULT_VALUES"

   # ---- Определяем разрешённые значения ----
   if [[ -n "$allowed_src" ]]; then
      if declare -p "${allowed_src%%[@]}" &>/dev/null; then
         # Если передано имя массива (array[@])
         local -n tmp_allowed="${allowed_src%%[@]}"
         allowed_ref=("${tmp_allowed[@]}")
      else
         # Иначе разбиваем строку по пробелам
         read -r -a allowed_ref <<< "$allowed_src"
      fi
   fi

   # ---- Определяем значения по умолчанию ----
   if [[ -n "$default_src" ]]; then
      if declare -p "${default_src%%[@]}" &>/dev/null; then
         # Если передано имя массива
         local -n tmp_default="${default_src%%[@]}"
         default_ref=("${tmp_default[@]}")
      else
         read -r -a default_ref <<< "$default_src"
      fi
   fi
}

__print_defined_argument_info__( )
{
   local name="$1"

   if [[ -z "$name" ]]; then
      echo "Usage: __print_defined_argument_info__ <argument_name>" >&2
      return 1
   fi

   local name_up="${name^^}"

   local vars=(
      "CMD_${name_up}_NAME"
      "CMD_${name_up}_TYPE"
      "CMD_${name_up}_REQUIRED"
      "CMD_${name_up}_ALLOWED_VALUES"
      "CMD_${name_up}_DEFAULT_VALUES"
      "CMD_${name_up}_DEFINED_VALUES"
   )

   echo "=== Argument info: ${name} ==="

   for var in "${vars[@]}"; do
      if ! declare -p "$var" &>/dev/null; then
         printf "%-35s : <not defined>\n" "$var"
         continue
      fi

      local decl
      decl=$(declare -p "$var" 2>/dev/null)

      if [[ "$decl" =~ "declare -a" ]]; then
         # массив
         local -n arr="$var"
         printf "%-35s : [array] %s\n" "$var" "${arr[*]}"
      else
         # обычная переменная
         printf "%-35s : %s\n" "$var" "${!var}"
      fi
   done

   echo "=========================================="
}

# Usage:
# __define_argument_ext__ "test" "ARGUMENT" "REQUIRED" \
#    "value_1 value_2 value_3" \
#    "value_1 value_2"
# __print_defined_argument_info__ "test"
#
# declare ALLOWED=( value_1 value_2 value_3 )
# declare DEFAULT=( value_1 value_2 )
# __define_argument_ext__ "test_1" "ARGUMENT" "REQUIRED" \
#    ALLOWED \
#    DEFAULT
# __print_defined_argument_info__ "test_1"
