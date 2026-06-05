#
# Function Parameter Processing Framework
#
# This module provides a unified mechanism for passing, validating and
# resolving function parameters using associative arrays.
#
# The main goal is to simplify shell function interfaces by avoiding
# long positional argument lists and replacing them with named
# parameters.
#
# Features:
#    - Named function parameters.
#    - Validation of required parameters.
#    - Default value assignment.
#    - Parameter dependency resolution.
#    - Placeholder substitution.
#
# Parameter Passing
# -----------------
#
# Functions receive a single associative array containing all
# parameters:
#
#    declare -A PARAMS=(
#       [SOURCE_DIR]="/project/source"
#       [BUILD_TYPE]="Release"
#    )
#
#    my_function PARAMS
#
# Inside the function the parameter map is accessed through a nameref:
#
#    declare -n CMD_PARAMETERS_MAP=${1}
#
#
# Required Parameters
# -------------------
#
# Required parameters are described using an indexed array:
#
#    local -r REQUIRED_PARAMETERS=(
#       "SOURCE_DIR"
#       "BUILD_TYPE"
#    )
#
# The validation function ensures that every required parameter:
#
#    - Exists in the parameter map.
#    - Contains a non-empty value.
#
#
# Default Parameters
# ------------------
#
# Optional parameters may be assigned default values using an
# associative array:
#
#    declare -A DEFAULT_PARAMETERS=(
#       [BUILD_DIR]="build"
#       [INSTALL_DIR]="install"
#    )
#
# If a parameter is missing or empty, the default value is copied into
# the parameter map.
#
#
# Placeholder Resolution
# ----------------------
#
# Default values may reference other parameters using placeholders:
#
#    __PARAMETER_NAME__
#
# Example:
#
#    declare -A DEFAULT_PARAMETERS=(
#       [BUILD_DIR]="__SOURCE_DIR__/build"
#       [INSTALL_DIR]="__BUILD_DIR__/install"
#    )
#
# For:
#
#    SOURCE_DIR=/project/source
#
# the resulting values become:
#
#    BUILD_DIR=/project/source/build
#    INSTALL_DIR=/project/source/build/install
#
# Placeholder resolution is performed repeatedly until all dependent
# values are resolved.
#
#
# Typical Usage
# -------------
#
#    function build_project( )
#    {
#       declare -n CMD_PARAMETERS_MAP=${1}
#
#       local -A PARAMETERS
#       copy_map PARAMETERS CMD_PARAMETERS_MAP
#
#       local -r REQUIRED_PARAMETERS=(
#          "SOURCE_DIR"
#       )
#
#       validate_require_function_params \
#          PARAMETERS REQUIRED_PARAMETERS || return $?
#
#       declare -A DEFAULT_PARAMETERS=(
#          [BUILD_DIR]="__SOURCE_DIR__/build"
#          [INSTALL_DIR]="__BUILD_DIR__/install"
#       )
#
#       validate_default_function_params \
#          PARAMETERS DEFAULT_PARAMETERS
#
#       ...
#    }
#
# This approach provides self-documenting function interfaces,
# centralized parameter validation and consistent default value
# handling across all shell modules.
#

[ -n "${__SFW_ARG_PARS_FUNCTIONS_SH__}" ] && return 0 || readonly __SFW_ARG_PARS_FUNCTIONS_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/array.sh"



#
# Validate that all required parameters are present in the parameter map
# and contain non-empty values.
#
# Arguments:
#    $1 - Name of associative array containing function parameters.
#    $2 - Name of array containing required parameter names.
#
# Return values:
#    0 - All required parameters are present and non-empty.
#    1 - Required parameter is missing.
#    2 - Required parameter is empty.
#
# Example:
#    local -A params=(
#       [SOURCE_DIR]="/tmp/source"
#    )
#
#    local -a required=(
#       "SOURCE_DIR"
#    )
#
#    validate_require_function_params params required
#
function validate_require_function_params( )
{
   local -n map=${1}
   local -n required=${2}

   local key

   for key in "${required[@]}"; do

      if [[ ! -v map["${key}"] ]]; then
         log_error "${key} is required"
         return 1
      fi

      if [[ -z ${map["${key}"]} ]]; then
         log_error "${key} must not be empty"
         return 2
      fi

   done

   return 0
}



#
# Apply default values for missing or empty parameters.
#
# The function processes a map of default values and copies unresolved
# entries into the destination parameter map. Default values may contain
# placeholders in the form:
#
#    __PARAM_NAME__
#
# Placeholders are replaced with values from the destination parameter
# map. Resolution is performed repeatedly until no parameter changes.
#
# Arguments:
#    $1 - Name of associative array containing function parameters.
#    $2 - Name of associative array containing default values.
#
# Notes:
#    - Existing non-empty parameters are preserved.
#    - Missing or empty parameters are replaced with defaults.
#    - Placeholder references may depend on other parameters.
#
# Example:
#    declare -A defaults=(
#       [BUILD_DIR]="__SOURCE_DIR__/build"
#       [INSTALL_DIR]="__BUILD_DIR__/install"
#    )
#
#    validate_default_function_params params defaults
#
function validate_default_function_params( )
{
   local -n map=$1
   local -n defs=$2

   local key value old_value k

   # Test if parameter defined in passed parameters map
   for key in "${!defs[@]}"; do
      if map_test_key_not_empty map ${key}; then
         unset "defs[${key}]"
      else
         value="${defs[$key]}"
         log_warning "'${key}' is not defined or empty => ${value} will be used"
      fi
   done

   local -r max_iterations=32
   local iteration=0
   local changed=1

   # Recurcive change placeholders
   while [[ $changed -eq 1 ]]; do

      (( iteration++ ))
      if (( iteration > max_iterations )); then
         log_error "Default parameter resolution loop detected"
         return 1
      fi

      changed=0

      for key in "${!defs[@]}"; do
         value="${defs[$key]}"
         old_value="${map[$key]}"

         # Resolve placeholders
         for k in "${!map[@]}"; do
            if [[ -n ${map[$k]} ]]; then
               value="${value//__${k}__/${map[$k]}}"
            fi
         done

         if [[ "${map[$key]}" != "$value" ]]; then
            log_warning "'$key' updated => $value will be used"
            map[$key]="$value"
            changed=1
         fi
      done
   done
}



#
# Example demonstrating parameter validation and default value handling.
#
# Expected parameters:
#    SOURCE_DIR - Source directory path (required).
#
# Generated parameters:
#    BUILD_DIR   - "__SOURCE_DIR__/build"
#    INSTALL_DIR - "__BUILD_DIR__/install"
#
# Arguments:
#    $1 - Name of associative array containing function parameters.
#
# The function:
#    1. Copies the input parameter map.
#    2. Validates required parameters.
#    3. Applies default values.
#    4. Prints the resulting parameter map.
#
function function_params_example( )
{
   declare -n CMD_PARAMETERS_MAP=${1}

   local -A PARAMETERS
   copy_map PARAMETERS CMD_PARAMETERS_MAP

   local -r REQUIRED_PARAMETERS=(
         "SOURCE_DIR"
      )
   validate_require_function_params PARAMETERS REQUIRED_PARAMETERS || return $?

   declare -A DEFAULT_PARAMETERS=(
         [INSTALL_DIR]="__BUILD_DIR__/install"
         [BUILD_DIR]="__SOURCE_DIR__/build"
      )
   validate_default_function_params PARAMETERS DEFAULT_PARAMETERS

   print_map PARAMETERS



   return 0
}

function test_function_params_example( )
{
   declare -A _PARAMETERS=(
      )
   function_params_example _PARAMETERS

   declare -A _PARAMETERS=(
         [SOURCE_DIR]=""
      )
   function_params_example _PARAMETERS

   declare -A _PARAMETERS=(
         [SOURCE_DIR]="XXXXX"
      )
   function_params_example _PARAMETERS

   declare -A _PARAMETERS=(
         [SOURCE_DIR]="XXXXX"
         [BUILD_DIR]="YYYYY"
      )
   function_params_example _PARAMETERS
}
