[ -n "${__SFW_ARG_PARS_JQ_SH__}" ] && return 0 || readonly __SFW_ARG_PARS_JQ_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/json.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/array.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/types.sh"



function __test_parameter_name__( )
{
   local name=${1}

   if [[ ! "${CMD_NAME}" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]]; then
      return 1
   fi
   return 0
}

###############################################################################
# Register a positional argument in the command argument registry.
#
# The function defines a positional argument together with its properties.
# Each argument is stored in the specified registry and can later be used by
# the argument parser for validation and default value assignment.
#
# Supported properties:
#   - argument name;
#   - required/optional flag;
#   - list of allowed values;
#   - list of default values for optional arguments.
#
# If both '--required' and '--default_values' are specified, the default values
# are ignored and a warning is printed.
#
# If both '--allowed_values' and '--default_values' are specified, every
# default value must be present in the list of allowed values.
#
# Parameters:
#   --registry=<name>
#      Name of the registry variable that stores argument definitions.
#
#   --name=<argument_name>
#      Name of the argument.
#      Must match the following pattern:
#         ^[A-Za-z_][A-Za-z0-9_-]*$
#
#   --required
#      Mark the argument as required.
#
#   --allowed_values=<v1,v2,...>
#      Comma-separated list of allowed argument values.
#
#   --default_values=<v1,v2,...>
#      Comma-separated list of default values assigned when the argument is
#      omitted. Ignored for required arguments.
#
# Return values:
#   0  Success.
#   1  Invalid function arguments or registration error.
#   2  One or more default values are not present in the allowed values list.
###############################################################################
function register_argument_help( )
{
   cat << EOF

Description:
   Register a positional argument in the argument registry.

   The registered argument can later be parsed and validated by the argument
   parser. An argument may be required or optional, define a list of allowed
   values and specify one or more default values.

Usage:
   register_argument
      --registry=<registry>
      --name=<argument_name>
      [--required]
      [--allowed_values=<value1,value2,...>]
      [--default_values=<value1,value2,...>]

Options:
   --registry=<registry>
      Name of the registry variable.

   --name=<argument_name>
      Argument name.

      The name must match the following pattern:

         ^[A-Za-z_][A-Za-z0-9_-]*$

   --required
      Mark the argument as required.

   --allowed_values=<value1,value2,...>
      Comma-separated list of allowed values.

      If specified, every parsed value must belong to this list.

   --default_values=<value1,value2,...>
      Comma-separated list of default values.

      Default values are assigned only if the argument is omitted.

      If '--required' is specified, this option is ignored.

Notes:
   • Multiple values are specified as a comma-separated list.

   • If both '--allowed_values' and '--default_values' are specified,
     every default value must also be present in the allowed values list.

Return values:
   0   Success.

   1   Invalid function arguments or registration error.

   2   One or more default values are not present in the allowed values list.

EOF
}

function register_argument( )
{
   local CMD_REGISTRY_NAME=""
   local CMD_NAME=""
   local CMD_DEFAULT_VALUES=""
   local CMD_ALLOWED_VALUES=""
   local CMD_REQUIRED="false"
   for option in "${@}"; do
      case ${option} in
         --registry=*)
            CMD_REGISTRY_NAME="${option#*=}"
         ;;
         --name=*)
            CMD_NAME="${option#*=}"
         ;;
         --default_values=*)
            CMD_DEFAULT_VALUES="${option#*=}"
         ;;
         --allowed_values=*)
            CMD_ALLOWED_VALUES="${option#*=}"
         ;;
         --required)
            CMD_REQUIRED="true"
         ;;
         *)
            log_error "undefined option: '${option}'"
            register_argument_help
            return 1
         ;;
      esac
   done

   if [[ -z "${CMD_REGISTRY_NAME}" ]]; then
      log_error "'--registry' must be defined"
      register_argument_help
      return 1
   fi
   if ! declare -p "${CMD_REGISTRY_NAME}" &>/dev/null; then
      log_error "Registry '${CMD_REGISTRY_NAME}' does not exist"
      register_argument_help
      return 1
   fi
   local -n CMD_REGISTRY_ra_ref="${CMD_REGISTRY_NAME}"

   if [[ -z "${CMD_NAME}" ]]; then
      log_error "'--name' must be defined"
      register_argument_help
      return 1
   fi
   if ! __test_parameter_name__ "${CMD_NAME}"; then
      log_error "Invalid argument name '${CMD_NAME}'"
      log_error "Allowed pattern: ^[A-Za-z_][A-Za-z0-9_-]*$"
      register_argument_help
      return 1
   fi



   json_set_value "${CMD_REGISTRY_ra_ref}" CMD_REGISTRY_ra_ref \
      "${CMD_NAME}" \
      "arguments" "${CMD_NAME}" "name"  \
      || return $?

   json_set_value "${CMD_REGISTRY_ra_ref}" CMD_REGISTRY_ra_ref \
      "${CMD_REQUIRED}" \
      "arguments" "${CMD_NAME}" "required"  \
      || return $?

   if [[ ! -z "${CMD_ALLOWED_VALUES}" ]]; then
      local -a allowed_values=( )
      IFS=',' read -ra allowed_values <<< "${CMD_ALLOWED_VALUES}"

      for i in "${!allowed_values[@]}"; do
         json_set_value "${CMD_REGISTRY_ra_ref}" CMD_REGISTRY_ra_ref \
            "${allowed_values[i]}" \
            "arguments" "${CMD_NAME}" "values" "allowed" ${i}  \
            || return $?
      done
   fi

   if [[ ! -z "${CMD_DEFAULT_VALUES}" ]]; then
      if [[ "true" == "${CMD_REQUIRED}" ]]; then
         log_warning "Ignoring '--default_values' for required parameter"
      else
         local -a default_values=( )
         IFS=',' read -ra default_values <<< "${CMD_DEFAULT_VALUES}"

         for i in "${!default_values[@]}"; do
            local default_value=${default_values[i]}

            if [[ ${#allowed_values[@]} -gt 0 ]]; then
               if ! array_test_element allowed_values "${default_value}"; then
                  log_error "Default value '${default_value}' for the parameter '${CMD_NAME}' is not in the list of the allowed values: '${allowed_values[*]}'"
                  register_argument_help
                  return 2
               fi
            fi

            json_set_value "${CMD_REGISTRY_ra_ref}" CMD_REGISTRY_ra_ref \
               "${default_value}" \
               "arguments" "${CMD_NAME}" "values" "default" ${i}  \
               || return $?
         done
      fi
   fi

   return 0
}



###############################################################################
# Register an option in the command option registry.
#
# The function registers a boolean command-line option in the specified
# registry. An option represents a flag that is either present or absent on
# the command line and therefore does not accept a value.
#
# Each registered option is initialized with the "defined" state set to
# "false". During argument parsing this state is updated to "true" if the
# option is specified on the command line.
#
# Parameters:
#   --registry=<name>
#      Name of the registry variable that stores option definitions.
#
#   --name=<option_name>
#      Name of the option.
#      Must match the following pattern:
#         ^[A-Za-z_][A-Za-z0-9_-]*$
#
# Return values:
#   0  Success.
#   1  Invalid function arguments or registration error.
###############################################################################
function register_option_help( )
{
   cat << EOF

Description:
   Register a boolean command-line option in the option registry.

   An option represents a command-line flag that is either present or absent.
   Unlike arguments, options do not accept values.

   The option is initially marked as undefined. During command-line parsing,
   its state changes to defined if the option is specified.

Usage:
   register_option
      --registry=<registry>
      --name=<option_name>

Options:
   --registry=<registry>
      Name of the registry variable.

   --name=<option_name>
      Option name.

      The name must match the following pattern:

         ^[A-Za-z_][A-Za-z0-9_-]*$

Return values:
   0   Success.

   1   Invalid function arguments or registration error.

EOF
}

function register_option( )
{
   local CMD_REGISTRY_NAME=""
   local CMD_NAME=""
   for option in "${@}"; do
      case ${option} in
         --registry=*)
            CMD_REGISTRY_NAME="${option#*=}"
         ;;
         --name=*)
            CMD_NAME="${option#*=}"
         ;;
         *)
            log_error "undefined option: '${option}'"
            register_option_help
            return 1
         ;;
      esac
   done

   if [[ -z "${CMD_REGISTRY_NAME}" ]]; then
      log_error "'--registry' must be defined"
      register_option_help
      return 1
   fi
   if ! declare -p "${CMD_REGISTRY_NAME}" &>/dev/null; then
      log_error "Registry '${CMD_REGISTRY_NAME}' does not exist"
      register_option_help
      return 1
   fi
   local -n CMD_REGISTRY_ro_ref="${CMD_REGISTRY_NAME}"

   if [[ -z "${CMD_NAME}" ]]; then
      log_error "'--name' must be defined"
      register_option_help
      return 1
   fi
   if ! __test_parameter_name__ "${CMD_NAME}"; then
      log_error "Invalid option name '${CMD_NAME}'"
      log_error "Allowed pattern: ^[A-Za-z_][A-Za-z0-9_-]*$"
      register_option_help
      return 1
   fi



   json_set_value "${CMD_REGISTRY_ro_ref}" CMD_REGISTRY_ro_ref \
      "${CMD_NAME}" \
      "options" "${CMD_NAME}" "name"  \
      || return $?

   json_set_value "${CMD_REGISTRY_ro_ref}" CMD_REGISTRY_ro_ref \
      "false" \
      "options" "${CMD_NAME}" "defined"  \
      || return $?

   return 0
}



###############################################################################
# Parse command-line parameters.
#
# The function parses a list of command-line parameters and updates the
# specified parameter registry.
#
# Supported parameter formats:
#
#   --option
#      Boolean option.
#
#   --argument=value
#      Argument with one or more comma-separated values.
#
# During parsing:
#   - registered options are marked as defined;
#   - argument values are stored in the "defined" values list;
#   - unsupported parameters cause an error in strict mode.
#
# This function performs syntax parsing only. Validation of required
# arguments, allowed values and default values must be performed separately
# by validate_parameters() and apply_default_values().
#
# Parameters:
#   <registry>
#      Name of the registry variable containing registered arguments and
#      options.
#
#   <parameters...>
#      Command-line parameters to parse.
#
# Return values:
#   0  Success.
#   1  Invalid or unsupported parameter.
#   2  Failed to update the parameter registry.
###############################################################################
function parse_parameters_help( )
{
   cat << EOF

Description:
   Parse command-line parameters and update the parameter registry.

   The function parses a sequence of command-line parameters and stores the
   parsed values in the specified registry.

   Supported parameter formats are:

      --option

   and

      --argument=value

   Argument values may contain multiple comma-separated values.

   This function performs parsing only. It does not validate required
   arguments, allowed values or assign default values.

Usage:
   parse_parameters
      <registry>
      [parameter...]

Parameters:
   <registry>
      Name of the registry variable.

   <parameter>
      Command-line parameter in one of the following forms:

         --option

      or

         --argument=value

      Multiple values may be specified as a comma-separated list:

         --target=aosp,kernel,uboot

Notes:
   • Options are marked as defined when present.

   • Argument values are stored exactly as specified.

   • Unknown parameters generate an error in strict mode.

Return values:
   0   Success.

   1   Invalid or unsupported parameter.

   2   Failed to update the parameter registry.

EOF
}

function parse_parameters( )
{
   local mode="strict"

   local -n __parse_parameters_parameters__=${1}
   shift

   for parameter in "${@}"; do
      # Test parameter for pattern '--param=value' or '--option'
      if [[ "${parameter}" != --* ]]; then
         log_error "Invalid parameter: '$parameter' (expected '--name' or '--name=value')"
         parse_parameters_help
         return 1
      fi

      # Get parameter type, name and value
      local parameter_value
      local parameter_type="options"
      local parameter_name="${parameter%%=*}"   # --param
      parameter_name="${parameter_name#--}"     # param
      if [[ "${parameter}" == *=* ]]; then
         parameter_type="arguments"
         parameter_value="${parameter#*=}"      # value
      fi

      # Test parameter for defining in configuration map
      local result_scalar
      if ! json_get_value "${__parse_parameters_parameters__}" result_scalar "${parameter_type}" "${parameter_name}"; then
         if [[ "strict" == "${mode}" ]]; then
            log_error "Unsupported ${parameter_type} '${parameter_name}'"
            parse_parameters_help
            return 2
         else
            log_warning "Unsupported ${parameter_type} '${parameter_name}'"
         fi
      fi

      # Update parameter value
      if [[ "options" == "${parameter_type}" ]]; then
         json_set_value "${__parse_parameters_parameters__}" __parse_parameters_parameters__ \
            "true" \
            "options" "${parameter_name}" "defined" || return 3
      elif [[ "arguments" == "${parameter_type}" ]]; then
         local -a defined_values=( )
         IFS=',' read -ra defined_values <<< "${parameter_value}"

         # Add each value passed with separated ',' to the defined values array
         for i in "${!defined_values[@]}"; do
            json_add_array_value "${__parse_parameters_parameters__}" __parse_parameters_parameters__ \
               "${defined_values[i]}" \
               "arguments" "${parameter_name}" "values" "defined" || return 4
         done
      else
         log_error "Undefined parameter type"
         parse_parameters_help
         return 5
      fi
   done

   return 0
}



###############################################################################
# Validate parsed command-line parameters.
#
# The function validates the current state of the parameter registry after
# command-line parameters have been parsed.
#
# The following checks are performed for every registered argument:
#   - required arguments must be defined;
#   - every defined value must belong to the list of allowed values, if such
#     a list is specified.
#
# The function does not modify the registry.
#
# Parameters:
#   <registry>
#      Name of the registry variable containing parsed command-line
#      parameters.
#
# Return values:
#   0  Validation completed successfully.
#   3  Failed to access the registered arguments.
#   4  A required argument was not specified.
#   5  One or more argument values are not allowed.
###############################################################################
function validate_parameters_help( )
{
   cat << EOF

Description:
   Validate parsed command-line parameters.

   The function verifies that the parameter registry is in a valid state after
   command-line parsing.

   The following checks are performed:

      • Every required argument must be defined.

      • Every defined argument value must belong to the list of allowed
        values, if such a list has been specified.

   The function performs validation only and does not modify the registry.

Usage:
   validate_parameters
      <registry>

Parameters:
   <registry>
      Name of the registry variable containing parsed parameters.

Return values:
   0   Validation completed successfully.

   3   Failed to access the registered arguments.

   4   A required argument was not specified.

   5   One or more argument values are not allowed.

EOF
}

function validate_parameters( )
{
   local -n __validate_parameters_parameters__=${1}

   local arguments_object
   json_get_value "${__validate_parameters_parameters__}" \
      arguments_object \
      "arguments" \
      || return 1

   local -a names
   mapfile -t names < <(
         jq -r 'keys[]' <<< "${arguments_object}"
      )

   for name in "${names[@]}"; do
      # Test if values are passed for the argumnt.
      # If value is not passed for required argument error occures.
      # If passed value is not present in the allowed list values arror occures.
      local -a defined_values=( )
      if ! json_get_value "${arguments_object}" defined_values "${name}" "values" "defined"; then
         local required
         json_get_value "${arguments_object}" required "${name}" "required"
         if [[ "true" == "${required}" ]]; then
            log_error "Required argument '--${name}' was not passed"
            validate_parameters_help
            return 2
         fi
      else
         local -a allowed_values=( )
         if json_get_value "${arguments_object}" allowed_values "${name}" "values" "allowed"; then
            if [[ ${#allowed_values[@]} -gt 0 ]]; then
               for defined_value in "${defined_values[@]}"; do
                  if ! array_test_element allowed_values "${defined_value}"; then
                     log_error "Passed value '${defined_value}' for parameter '${name}' is not allowed"
                     validate_parameters_help
                     return 3
                  fi
               done
            fi
         fi
      fi
   done

   return 0
}



###############################################################################
# Get the effective value of a registered argument.
#
# The function retrieves the first value associated with the specified
# argument.
#
# The returned value is selected according to the following priority:
#
#   1. The first value explicitly specified by the user.
#   2. The first default value registered for the argument.
#
# As a result, the caller does not need to distinguish between explicitly
# provided values and default values.
#
# If neither an explicitly defined value nor a default value exists, the
# function returns an error.
#
# Parameters:
#   --registry=<name>
#      Name of the registry variable.
#
#   --name=<argument_name>
#      Name of the registered argument.
#
#   --result=<variable>
#      Name of the variable that receives the argument value.
#
# Return values:
#   0  Success.
#   1  Invalid function option.
#   2  '--registry' was not specified.
#   3  Registry variable does not exist.
#   4  '--name' was not specified.
#   5  Invalid argument name.
#   6  '--result' was not specified.
#   7  Result variable does not exist.
#   8  The argument has neither a defined value nor a default value.
###############################################################################
function get_argument_help( )
{
   cat << EOF

Description:
   Get the effective value of a registered argument.

   The function returns the first value associated with the specified
   argument.

   The returned value is selected according to the following priority:

      1. The first value explicitly specified by the user.

      2. The first registered default value.

   This allows the caller to access the effective argument value without
   checking whether it was supplied on the command line or obtained from
   the default values.

Usage:
   get_argument
      --registry=<registry>
      --name=<argument_name>
      --result=<variable>

Options:
   --registry=<registry>
      Name of the registry variable.

   --name=<argument_name>
      Name of the registered argument.

      The name must match the following pattern:

         ^[A-Za-z_][A-Za-z0-9_-]*$

   --result=<variable>
      Name of the variable that receives the argument value.

Notes:
   • Only the first value of the argument is returned.

   • If the argument accepts multiple values, only element 0 is retrieved.

   • If neither a defined value nor a default value exists, the function
     returns an error.

Return values:
   0   Success.

   1   Invalid function option.

   2   '--registry' was not specified.

   3   Registry variable does not exist.

   4   '--name' was not specified.

   5   Invalid argument name.

   6   '--result' was not specified.

   7   Result variable does not exist.

   8   The argument has neither a defined value nor a default value.

EOF
}

function get_argument( )
{
   local CMD_REGISTRY_NAME=""
   local CMD_NAME
   local CMD_RESULT_NAME=""
   for option in "${@}"; do
      case ${option} in
         --registry=*)
            CMD_REGISTRY_NAME="${option#*=}"
         ;;
         --name=*)
            CMD_NAME="${option#*=}"
         ;;
         --result=*)
            CMD_RESULT_NAME="${option#*=}"
         ;;
         *)
            log_error "undefined option: '${option}'"
            get_argument_help
            return 1
         ;;
      esac
   done

   if [[ -z "${CMD_REGISTRY_NAME}" ]]; then
      log_error "'--registry' must be defined"
      get_argument_help
      return 2
   fi
   if ! declare -p "${CMD_REGISTRY_NAME}" &>/dev/null; then
      log_error "Registry '${CMD_REGISTRY_NAME}' does not exist"
      get_argument_help
      return 3
   fi
   local -n CMD_REGISTRY_ga_ref="${CMD_REGISTRY_NAME}"

   if [[ -z "${CMD_NAME}" ]]; then
      log_error "'--name' must be defined"
      get_argument_help
      return 4
   fi
   if ! __test_parameter_name__ "${CMD_NAME}"; then
      log_error "Invalid argument name '${CMD_NAME}'"
      log_error "Allowed pattern: ^[A-Za-z_][A-Za-z0-9_-]*$"
      get_argument_help
      return 5
   fi

   if [[ -z "${CMD_RESULT_NAME}" ]]; then
      log_error "'--result' must be defined"
      get_argument_help
      return 6
   fi
   if ! declare -p "${CMD_RESULT_NAME}" &>/dev/null; then
      log_error "Result '${CMD_RESULT_NAME}' does not exist"
      get_argument_help
      return 7
   fi
   local -n CMD_RESULT_ga_ref="${CMD_RESULT_NAME}"



   json_get_value "${CMD_REGISTRY_ga_ref}" \
      CMD_RESULT_ga_ref "arguments" "${CMD_NAME}" "values" "defined" 0
   local rc=$?
   if (( rc != 0 )); then
      json_get_value "${CMD_REGISTRY_ga_ref}" \
         CMD_RESULT_ga_ref "arguments" "${CMD_NAME}" "values" "default" 0 \
         || return 8
   fi

   return 0
}



###############################################################################
# Get the state of a registered option.
#
# The function retrieves the current state of the specified option.
#
# The returned value is one of:
#
#   "true"
#      The option was specified during command-line parsing.
#
#   "false"
#      The option was not specified.
#
# Parameters:
#   --registry=<name>
#      Name of the registry variable.
#
#   --name=<option_name>
#      Name of the registered option.
#
#   --result=<variable>
#      Name of the variable that receives the option state.
#
# Return values:
#   0  Success.
#   1  Invalid function option.
#   2  '--registry' was not specified.
#   3  Registry variable does not exist.
#   4  '--name' was not specified.
#   5  Invalid option name.
#   6  '--result' was not specified.
#   7  Result variable does not exist.
#   8  Failed to retrieve the option state.
###############################################################################
function get_option_help( )
{
   cat << EOF

Description:
   Get the state of a registered command-line option.

   The function returns whether the specified option was present during
   command-line parsing.

   The returned value is one of:

      true
         The option was specified.

      false
         The option was not specified.

Usage:
   get_option
      --registry=<registry>
      --name=<option_name>
      --result=<variable>

Options:
   --registry=<registry>
      Name of the registry variable.

   --name=<option_name>
      Name of the registered option.

      The name must match the following pattern:

         ^[A-Za-z_][A-Za-z0-9_-]*$

   --result=<variable>
      Name of the variable that receives the option state.

Return values:
   0   Success.

   1   Invalid function option.

   2   '--registry' was not specified.

   3   Registry variable does not exist.

   4   '--name' was not specified.

   5   Invalid option name.

   6   '--result' was not specified.

   7   Result variable does not exist.

   8   Failed to retrieve the option state.

EOF
}

function get_option( )
{
   local CMD_REGISTRY_NAME=""
   local CMD_NAME
   local CMD_RESULT_NAME=""
   for option in "${@}"; do
      case ${option} in
         --registry=*)
            CMD_REGISTRY_NAME="${option#*=}"
         ;;
         --name=*)
            CMD_NAME="${option#*=}"
         ;;
         --result=*)
            CMD_RESULT_NAME="${option#*=}"
         ;;
         *)
            log_error "undefined option: '${option}'"
            get_option_help
            return 1
         ;;
      esac
   done

   if [[ -z "${CMD_REGISTRY_NAME}" ]]; then
      log_error "'--registry' must be defined"
      get_option_help
      return 2
   fi
   if ! declare -p "${CMD_REGISTRY_NAME}" &>/dev/null; then
      log_error "Registry '${CMD_REGISTRY_NAME}' does not exist"
      get_option_help
      return 3
   fi
   local -n CMD_REGISTRY_go_ref="${CMD_REGISTRY_NAME}"

   if [[ -z "${CMD_NAME}" ]]; then
      log_error "'--name' must be defined"
      get_option_help
      return 4
   fi
   if ! __test_parameter_name__ "${CMD_NAME}"; then
      log_error "Invalid option name '${CMD_NAME}'"
      log_error "Allowed pattern: ^[A-Za-z_][A-Za-z0-9_-]*$"
      get_option_help
      return 5
   fi

   if [[ -z "${CMD_RESULT_NAME}" ]]; then
      log_error "'--result' must be defined"
      get_option_help
      return 6
   fi
   if ! declare -p "${CMD_RESULT_NAME}" &>/dev/null; then
      log_error "Result '${CMD_RESULT_NAME}' does not exist"
      get_option_help
      return 7
   fi
   local -n CMD_RESULT_go_ref="${CMD_RESULT_NAME}"



   json_get_value "${CMD_REGISTRY_go_ref}" \
      CMD_RESULT_go_ref "options" "${CMD_NAME}" "defined" \
      || return 8

   return 0
}



###############################################################################
# Test whether a registered option is defined.
#
# The function checks whether the specified command-line option was present
# during command-line parsing.
#
# The function is intended to be used directly in shell conditions:
#
#   if test_option --registry=registry --name=verbose; then
#      ...
#   fi
#
# Parameters:
#   --registry=<name>
#      Name of the registry variable.
#
#   --name=<option_name>
#      Name of the registered option.
#
# Return values:
#   0  The option is defined.
#   1  The option is not defined.
#   2  Invalid function option.
#   3  '--registry' was not specified.
#   4  Registry variable does not exist.
#   5  '--name' was not specified.
#   6  Invalid option name.
#   7  Failed to retrieve the option state.
###############################################################################
function test_option_help( )
{
   cat << EOF

Description:
   Test whether a registered command-line option is defined.

   The function checks whether the specified option was present during
   command-line parsing.

   It is intended to be used directly in shell conditions.

Usage:
   test_option
      --registry=<registry>
      --name=<option_name>

Options:
   --registry=<registry>
      Name of the registry variable.

   --name=<option_name>
      Name of the registered option.

      The name must match the following pattern:

         ^[A-Za-z_][A-Za-z0-9_-]*$

Examples:
   if test_option --registry=registry --name=verbose; then
      echo "Verbose mode enabled"
   fi

Return values:
   0   The option is defined.

   1   The option is not defined.

   2   Invalid function option.

   3   '--registry' was not specified.

   4   Registry variable does not exist.

   5   '--name' was not specified.

   6   Invalid option name.

   7   Failed to retrieve the option state.

EOF
}

function test_option( )
{
   local CMD_REGISTRY_NAME=""
   local CMD_NAME
   for option in "${@}"; do
      case ${option} in
         --registry=*)
            CMD_REGISTRY_NAME="${option#*=}"
         ;;
         --name=*)
            CMD_NAME="${option#*=}"
         ;;
         *)
            log_error "undefined option: '${option}'"
            test_option_help
            return 1
         ;;
      esac
   done

   if [[ -z "${CMD_REGISTRY_NAME}" ]]; then
      log_error "'--registry' must be defined"
      test_option_help
      return 2
   fi
   if ! declare -p "${CMD_REGISTRY_NAME}" &>/dev/null; then
      log_error "Registry '${CMD_REGISTRY_NAME}' does not exist"
      test_option_help
      return 3
   fi
   local -n CMD_REGISTRY_to_ref="${CMD_REGISTRY_NAME}"

   if [[ -z "${CMD_NAME}" ]]; then
      log_error "'--name' must be defined"
      test_option_help
      return 4
   fi
   if ! __test_parameter_name__ "${CMD_NAME}"; then
      log_error "Invalid option name '${CMD_NAME}'"
      log_error "Allowed pattern: ^[A-Za-z_][A-Za-z0-9_-]*$"
      test_option_help
      return 5
   fi



   local option_state
   get_option --registry=CMD_REGISTRY_to_ref \
      --name="${CMD_NAME}" --result=option_state || return 6

   if [[ "${option_state}" != "true" ]]; then
      return 7
   fi
   return 0
}



function test( )
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
   get_argument --registry=__PARAMETERS__ --name="project" --result=result
   echo "   $?: ${result}"

   log_info "Get argument 'action'"
   get_argument --registry=__PARAMETERS__ --name="action" --result=result
   echo "   $?: ${result}"

   log_info "Get argument 'target'"
   get_argument --registry=__PARAMETERS__ --name="target" --result=result
   echo "   $?: ${result}"

   log_info "Get argument 'xxxxx'"
   get_argument --registry=__PARAMETERS__ --name="xxxxx" --result=result
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

test "${@}"
exit $?
