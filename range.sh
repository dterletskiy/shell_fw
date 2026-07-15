[ -n "${__SFW_RANGE_SH__}" ] && return 0 || readonly __SFW_RANGE_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



function __parse_range_help__( )
{
   cat << EOF

Description:
   Parse a list of numbers and numeric ranges into an array.

   The input string consists of comma-separated items.
   Each item can be either:
      - a single non-negative integer;
      - a numeric range in the form '<begin>-<end>'.

   Every parsed number is appended to the output array.
   Ranges are expanded into all numbers within the specified
   interval, inclusive.

Usage:
   parse_range "<range_list>" <output_array>

Parameters:
   <range_list>
      Comma-separated list of numbers and ranges.

      Examples:
         1
         1,7,9
         0-7
         1-3,6,7
         0,2-7,9

   <output_array>
      Name of the array that will receive the parsed numbers.

Return value:
   0
      Parsing completed successfully.

   1
      Invalid input format or invalid range.

Notes:
   - Only non-negative integers are supported.
   - Range boundaries are inclusive.
   - The output array is cleared before new values are written.
   - A range where the end value is less than the begin value
     is considered invalid.

Examples:
   declare -a ARRAY

   parse_range "1" ARRAY
   # ARRAY=(1)

   parse_range "1,7,9" ARRAY
   # ARRAY=(1 7 9)

   parse_range "0-3" ARRAY
   # ARRAY=(0 1 2 3)

   parse_range "1-3,6,7" ARRAY
   # ARRAY=(1 2 3 6 7)

   parse_range "0,2-4,9" ARRAY
   # ARRAY=(0 2 3 4 9)

EOF
}

# This function parses list of numbers and ranges of numbers passed in the string
# and fills an array of numbers passed as a second argument.
# List of numbers and ranges must be passed as a string and separated by ','.
# Ranges is the two numbers separated by '-'.
# Examples:
#     declare -a ARRAY
#     parse_range "1" ARRAY
#     parse_range "1,7,9" ARRAY
#     parse_range "0-7" ARRAY
#     parse_range "1-3,6,7" ARRAY
#     parse_range "0,2-7,9" ARRAY
function parse_range( )
{
   if [[ $# -ne 2 ]]; then
      log_error "Usage: parse_range \"<range_list>\" <output_array>"
      __parse_range_help__
      return 1
   fi

   if [[ -z "$1" ]]; then
      log_error "Input range list is empty"
      return 1
   fi

   if [[ -z "$2" ]]; then
      log_error "Output array name is empty"
      return 1
   fi

   if [[ ! "$2" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      log_error "Invalid array name: '$2'"
      return 1
   fi



   local INPUT_STRING="${1}"
   local -n _PARSE_RANGE_RESULT_ARRAY_=${2}

   _PARSE_RANGE_RESULT_ARRAY_=( )

   IFS=',' read -r -a tokens <<< "${INPUT_STRING}"

   for token in "${tokens[@]}"; do
      if [[ "${token}" =~ ^[0-9]+$ ]]; then
         _PARSE_RANGE_RESULT_ARRAY_+=("${token}")
      elif [[ "${token}" =~ ^([0-9]+)-([0-9]+)$ ]]; then
         start=${BASH_REMATCH[1]}
         end=${BASH_REMATCH[2]}
         if (( start <= end )); then
            for (( i=start; i<=end; i++ )); do
               _PARSE_RANGE_RESULT_ARRAY_+=("${i}")
            done
         else
            log_error "Error: invalid range '${token}' (end is less then begin)"
            return 1
         fi
      else
            log_error "Error: invalid '${token}'"
            return 1
      fi
   done

   return 0
}

function test_parse_range( )
{
   declare -a ARRAY

   local STRING="1"
   parse_range ${STRING} ARRAY
   log_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="1,7,9"
   parse_range ${STRING} ARRAY
   log_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="0-7"
   parse_range ${STRING} ARRAY
   log_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="1-3,6,7"
   parse_range ${STRING} ARRAY
   log_info "'${STRING}' ->"
   print_array ARRAY

   local STRING="0,2-7,9"
   parse_range ${STRING} ARRAY
   log_info "'${STRING}' ->"
   print_array ARRAY
}
