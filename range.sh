[ -n "${__SFW_RANGE_SH__}" ] && return 0 || readonly __SFW_RANGE_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



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
