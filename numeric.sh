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
# 'get_constant' prints a mathematical constant with the requested number of
# digits after the decimal point.
#
# Parameters:
# $1 - Name of the mathematical constant. Supported values:
#      pi    - Pi (3.14159...).
#      e     - Euler's number (2.71828...).
#      phi   - Golden ratio (1.61803...).
#      sqrt2 - Square root of 2 (1.41421...).
#      sqrt3 - Square root of 3 (1.73205...).
# $2 - Number of digits after the decimal point. Must be a non-negative integer.
#
# Behavior:
# - Uses 'bc -l' to calculate the requested mathematical constant.
# - Calculates with 10 extra decimal digits of precision.
# - Truncates the fractional part to the requested number of digits without
#   rounding.
# - Disables line wrapping in 'bc' using BC_LINE_LENGTH=0.
# - If the requested number of digits is 0, prints only the integer part.
# - Prints the result to standard output.
# - Returns 0 on success.
# - Returns 1 and logs an error if the number of arguments is incorrect, the
#   constant name is unknown, the number of digits is invalid, 'bc' is missing,
#   or the calculation fails.
#
# Examples:
# get_constant pi 5
# # 3.14159
#
# get_constant e 5
# # 2.71828
#
# get_constant phi 5
# # 1.61803
#
# get_constant sqrt2 5
# # 1.41421
#
# get_constant sqrt3 5
# # 1.73205
#
# get_constant pi 0
# # 3
function get_constant( )
{
   if [[ 2 -ne $# ]]; then
      log_error "Usage: get_constant <constant-name> <non-negative-integer>"
      return 1
   fi

   local constant_name="${1}"
   local digits="${2}"

   if ! is_non_negative_integer "${digits}"; then
      log_error "Usage: get_constant <constant-name> <non-negative-integer>"
      return 1
   fi

   digits="$( normalize_integer ${digits} )"

   if ! command -v bc &> /dev/null; then
      log_error "'bc' is required"
      return 1
   fi

   local expression
   case "${constant_name}" in
      pi)
         expression="4*a(1)"
      ;;
      e)
         expression="e(1)"
      ;;
      phi)
         expression="(1 + sqrt(5)) / 2"
      ;;
      sqrt2)
         expression="sqrt(2)"
      ;;
      sqrt3)
         expression="sqrt(3)"
      ;;
      *)
         log_error "Unknown constant: '${constant_name}'"
         return 1
      ;;
   esac

   local scale=$(( digits + 10 ))

   local value
   if ! value="$( BC_LINE_LENGTH=0 bc -l <<< "scale=${scale}; ${expression}" 2> /dev/null )"; then
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



function normalize_integer( )
{
   local value="${1}"

   value="${value#"${value%%[!0]*}"}"

   printf "%s\n" "${value:-0}"
}
