[ -n "${__SFW_ARG_PARS_SH__}" ] && return 0 || readonly __SFW_ARG_PARS_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



# Description:
# 'parameters_filter' filters a list of command-line arguments and
# returns only those arguments and options whose keys are explicitly allowed.
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
function parameters_filter( )
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

   # log_info "INPUT:  ${_FP_INPUT_[@]}"
   # log_info "FILTER: ${_FP_FILTER_[@]}"
   # log_info "OUTPUT: ${_FP_OUTPUT_[@]}"
}



# Description:
# 'parameters_transform' transforms a list of command-line arguments using 
# a mapping dictionary.
# The function accepts a list of arguments in the form:
#     --option — a standalone flag
#     --arg=value — an option with an inline value
# 
# Each matched argument key is replaced with the corresponding value 
# from the dictionary, while the argument value (if present) is preserved.
# 
# Function Signature:
# parameters_transform <source_array> <mapping_dictionary> <output_array>
# 
# Parameters:
# source_array - Name of the array containing the original
#                command-line arguments.
# mapping_dictionary - Name of an associative array where:
#     - the key is an argument name (e.g. --width)
#     - the value is the string that should replace it in the output (e.g. -w)
# output_array - Name of the array that will receive the filtered and
#                transformed arguments.
# 
# All parameters are passed by reference using Bash namerefs (local -n).
function parameters_transform( )
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

   # log_info "INPUT:  ${_MP_INPUT_[@]}"
   # log_info "MAP:"
   # for key in "${!_MP_MAP_[@]}"; do
   #    log_info "   ${key} = ${_MP_MAP_[$key]}"
   # done
   # log_info "OUTPUT: ${_MP_OUTPUT_[@]}"
}



# Description:
# 'parameters_filter_transform' filters and transforms a list of
# command-line arguments using a mapping dictionary.
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
# source_array - Name of the array containing the original
#                command-line arguments.
# mapping_dictionary - Name of an associative array where:
#     - the key is an allowed argument name (e.g. --width)
#     - the value is the string that should replace it in the output (e.g. -w)
# output_array - Name of the array that will receive the filtered and
#                transformed arguments.
# 
# All parameters are passed by reference using Bash namerefs (local -n).
function parameters_filter_transform( )
{
   local -n _FMP_INPUT_=${1}
   local -n _FMP_MAP_=${2}
   local -n _FMP_OUTPUT_=${3}

   _FMP_OUTPUT_=( )
   _FMP_OUTPUT_TMP_=( )
   filter=( "${!_FMP_MAP_[@]}" )
   parameters_filter _FMP_INPUT_ filter _FMP_OUTPUT_TMP_
   parameters_transform _FMP_OUTPUT_TMP_ _FMP_MAP_ _FMP_OUTPUT_
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
   parameters_filter parameters filter output
   log_warning "map"
   parameters_transform parameters map output
   log_warning "filter and map"
   parameters_filter_transform parameters map output
}
