[ -n "${__SFW_NUMERIC_SH__}" ] && return 0 || readonly __SFW_NUMERIC_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



function is_positive_integer( )
{
   local value="$1"

   [[ "$value" =~ ^\+?[1-9][0-9]*$ ]]
}

function is_negative_integer( )
{
   local value="$1"

   [[ "$value" =~ ^-[1-9][0-9]*$ ]]
}

function is_integer( )
{
   local value="$1"

   [[ "$value" =~ ^[+-]?[0-9]+$ ]]
}

function is_non_positive_integer( )
{
   local value="$1"

   is_integer "${value}" && ! is_positive_integer "${value}"
}

function is_non_negative_integer( )
{
   local value="$1"

   is_integer "${value}" && [[ ! "${value}" =~ ^- ]]
}

function is_positive_float( )
{
   local value="$1"

   [[ "${value}" =~ ^\+?(([0-9]+\.[0-9]*)|(\.[0-9]+))$ ]] && \
      [[ ! "${value}" =~ ^\+?0*\.?0*$ ]] && \
         return 0 || \
            return 1
}

function is_negative_float( )
{
   local value="$1"

   [[ "${value}" =~ ^-(([0-9]+\.[0-9]*)|(\.[0-9]+))$ ]] && \
      [[ ! "${value}" =~ ^-0*\.?0*$ ]] && \
         return 0 || \
            return 1
}

function is_float( )
{
   local value="$1"

   [[ "$value" =~ ^[+-]?(([0-9]+\.[0-9]*)|(\.[0-9]+))$ ]]
}

function is_non_positive_float( )
{
   local value="$1"

   is_float "${value}" && ! is_positive_float "${value}"
}

function is_non_negative_float( )
{
   local value="$1"

   is_float "${value}" && [[ ! "${value}" =~ ^- ]]
}

function is_positive_number( )
{
   local value="$1"

   if is_positive_integer "${value}" || is_positive_float "${value}"; then
      return 0
   else
      return 1
   fi
}

function is_negative_number( )
{
   local value="$1"

   if is_negative_integer "${value}" || is_negative_float "${value}"; then
      return 0
   else
      return 1
   fi
}

function is_number( )
{
   local value="$1"

   if is_integer "${value}" || is_float "${value}"; then
      return 0
   else
      return 1
   fi
}

function is_non_positive_number( )
{
   local value="$1"

   is_number "${value}" && ! is_positive_number "${value}"
}

function is_non_negative_number( )
{
   local value="$1"

   is_number "${value}" && ! is_negative_number "${value}"
}



# Description:
# 'add_numbers' adds two numeric values and prints the result.
#
# Parameters:
# $1 - First number. May be an integer or a decimal value.
# $2 - Second number. May be an integer or a decimal value.
#
# Behavior:
# - Validates both arguments with 'is_number'.
# - Uses 'bc' to add integer and decimal values.
# - Uses the maximum fractional length of the input values as the output scale.
# - Normalizes results such as '.5' and '-.5' to '0.5' and '-0.5'.
# - Accepts signed integers and decimal values such as '+1', '.5', '-.5',
#   '1.', and '-1.25'.
# - Returns 1 and logs an error if the number of arguments is invalid, an
#   argument is not numeric, 'bc' is missing, or the calculation fails.
#
# Examples:
# add_numbers 1 2
# # 3
#
# add_numbers 1.2 3.4
# # 4.6
#
# add_numbers -1.5 0.25
# # -1.25
#
# add_numbers "$(get_pi_digits 100)" "$(get_e_digits 100)"
# # 5.8598744820488384738229308546321653819544164930750653959419122200318930366397565931994170038672834953
function add_numbers( )
{
   if [[ 2 -ne $# ]]; then
      log_error "Usage: add_numbers <number> <number>"
      return 1
   fi

   local left="${1}"
   local right="${2}"

   if ! is_number "${left}" || ! is_number "${right}"; then
      log_error "Usage: add_numbers <number> <number>"
      return 1
   fi

   if ! command -v bc &> /dev/null; then
      log_error "'bc' is required"
      return 1
   fi

   local left_fraction=""
   local right_fraction=""

   if [[ "${left}" == *.* ]]; then
      left_fraction="${left#*.}"
   fi
   if [[ "${right}" == *.* ]]; then
      right_fraction="${right#*.}"
   fi

   local scale=${#left_fraction}
   if [[ ${scale} -lt ${#right_fraction} ]]; then
      scale=${#right_fraction}
   fi

   local result
   local bc_left="${left#+}"
   local bc_right="${right#+}"

   if ! result="$( BC_LINE_LENGTH=0 bc <<< "scale=${scale}; ${bc_left} + ${bc_right}" 2> /dev/null )"; then
      log_error "'bc' calculation failed"
      return 1
   fi

   if [[ "${result}" == .* ]]; then
      result="0${result}"
   elif [[ "${result}" == -.* ]]; then
      result="-0${result#-}"
   fi

   printf "%s\n" "${result}"
}



# Description:
# 'get_pi_digits' prints pi with the requested number of digits after the
# decimal point.
#
# Parameters:
# $1 - Number of digits after the decimal point. Must be a non-negative integer.
#
# Behavior:
# - Uses 'bc -l' to calculate pi as 4*a(1).
# - Calculates with extra precision and then truncates the fractional part to
#   the requested length.
# - If the requested length is 0, prints only the integer part: 3.
# - Returns 1 and logs an error if the number of arguments is invalid, the
#   argument is invalid, 'bc' is missing, or the calculation fails.
#
# Example:
# get_pi_digits 5
# # 3.14159
function get_pi_digits( )
{
   if [[ 1 -ne $# ]]; then
      log_error "Usage: get_pi_digits <non-negative-integer>"
      return 1
   fi

   local digits="${1}"

   if ! is_non_negative_integer "${digits}"; then
      log_error "Usage: get_pi_digits <non-negative-integer>"
      return 1
   fi

   if ! command -v bc &> /dev/null; then
      log_error "'bc' is required"
      return 1
   fi

   local scale=$(( digits + 10 ))
   local value
   if ! value="$( BC_LINE_LENGTH=0 bc -l <<< "scale=${scale}; 4*a(1)" 2> /dev/null )"; then
      log_error "'bc' calculation failed"
      return 1
   fi
   local integer="${value%%.*}"

   if [[ 0 -eq ${digits} ]]; then
      printf "%s\n" "${integer}"
      return 0
   fi

   local fraction="${value#*.}"
   printf "%s.%s\n" "${integer}" "${fraction:0:${digits}}"
}



# Description:
# 'get_e_digits' prints Euler's number with the requested number of digits
# after the decimal point.
#
# Parameters:
# $1 - Number of digits after the decimal point. Must be a non-negative integer.
#
# Behavior:
# - Uses 'bc -l' to calculate Euler's number as e(1).
# - Calculates with extra precision and then truncates the fractional part to
#   the requested length.
# - If the requested length is 0, prints only the integer part: 2.
# - Returns 1 and logs an error if the number of arguments is invalid, the
#   argument is invalid, 'bc' is missing, or the calculation fails.
#
# Example:
# get_e_digits 5
# # 2.71828
function get_e_digits( )
{
   if [[ 1 -ne $# ]]; then
      log_error "Usage: get_e_digits <non-negative-integer>"
      return 1
   fi

   local digits="${1}"

   if ! is_non_negative_integer "${digits}"; then
      log_error "Usage: get_e_digits <non-negative-integer>"
      return 1
   fi

   if ! command -v bc &> /dev/null; then
      log_error "'bc' is required"
      return 1
   fi

   local scale=$(( digits + 10 ))
   local value
   if ! value="$( BC_LINE_LENGTH=0 bc -l <<< "scale=${scale}; e(1)" 2> /dev/null )"; then
      log_error "'bc' calculation failed"
      return 1
   fi
   local integer="${value%%.*}"

   if [[ 0 -eq ${digits} ]]; then
      printf "%s\n" "${integer}"
      return 0
   fi

   local fraction="${value#*.}"
   printf "%s.%s\n" "${integer}" "${fraction:0:${digits}}"
}



# Description:
# 'get_phi_digits' prints the golden ratio with the requested number of digits
# after the decimal point.
#
# Parameters:
# $1 - Number of digits after the decimal point. Must be a non-negative integer.
#
# Behavior:
# - Uses 'bc -l' to calculate the golden ratio as (1 + sqrt(5)) / 2.
# - Calculates with extra precision and then truncates the fractional part to
#   the requested length.
# - If the requested length is 0, prints only the integer part: 1.
# - Returns 1 and logs an error if the number of arguments is invalid, the
#   argument is invalid, 'bc' is missing, or the calculation fails.
#
# Example:
# get_phi_digits 5
# # 1.61803
function get_phi_digits( )
{
   if [[ 1 -ne $# ]]; then
      log_error "Usage: get_phi_digits <non-negative-integer>"
      return 1
   fi

   local digits="${1}"

   if ! is_non_negative_integer "${digits}"; then
      log_error "Usage: get_phi_digits <non-negative-integer>"
      return 1
   fi

   if ! command -v bc &> /dev/null; then
      log_error "'bc' is required"
      return 1
   fi

   local scale=$(( digits + 10 ))
   local value
   if ! value="$( BC_LINE_LENGTH=0 bc -l <<< "scale=${scale}; (1 + sqrt(5)) / 2" 2> /dev/null )"; then
      log_error "'bc' calculation failed"
      return 1
   fi
   local integer="${value%%.*}"

   if [[ 0 -eq ${digits} ]]; then
      printf "%s\n" "${integer}"
      return 0
   fi

   local fraction="${value#*.}"
   printf "%s.%s\n" "${integer}" "${fraction:0:${digits}}"
}



function __test_numeric__( )
{
   declare -a VALUES=( 1 0 -0 -1 1.0 0.0 -0.0 -1.0 )

   for VALUE in "${VALUES[@]}"; do
      log_info "------------------------------------------------"

      is_positive_integer "${VALUE}" && \
         log_debug "'${VALUE}' - is positive integer" || \
         log_error "'${VALUE}' - is not positive integer"

      is_negative_integer "${VALUE}" && \
         log_debug "'${VALUE}' - is negative integer" || \
         log_error "'${VALUE}' - is not negative integer"

      is_integer "${VALUE}" && \
         log_debug "'${VALUE}' - is integer" || \
         log_error "'${VALUE}' - is not integer"

      is_positive_float "${VALUE}" && \
         log_debug "'${VALUE}' - is positive float" || \
         log_error "'${VALUE}' - is not positive float"

      is_negative_float "${VALUE}" && \
         log_debug "'${VALUE}' - is negative float" || \
         log_error "'${VALUE}' - is not negative float"

      is_float "${VALUE}" && \
         log_debug "'${VALUE}' - is float" || \
         log_error "'${VALUE}' - is not float"

      is_positive_number "${VALUE}" && \
         log_debug "'${VALUE}' - is positive number" || \
         log_error "'${VALUE}' - is not positive number"

      is_negative_number "${VALUE}" && \
         log_debug "'${VALUE}' - is negative number" || \
         log_error "'${VALUE}' - is not negative number"

      is_number "${VALUE}" && \
         log_debug "'${VALUE}' - is number" || \
         log_error "'${VALUE}' - is not number"
   done
}
