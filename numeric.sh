[ -n "${__SFW_NUMERIC_SH__}" ] && return 0 || readonly __SFW_NUMERIC_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



function is_positive_integer( )
{
   local value="$1"

   [[ "$value" =~ ^[1-9][0-9]*$ ]]
}

function is_negative_integer( )
{
   local value="$1"

   [[ "$value" =~ ^-[1-9][0-9]*$ ]]
}

function is_integer( )
{
   local value="$1"

   [[ "$value" =~ ^-?[0-9]+$ ]]
}

function is_non_positive_integer( )
{
   local value="$1"

   is_integer "${value}" && ! is_positive_integer "${value}"
}

function is_non_negative_integer( )
{
   local value="$1"

   is_integer "${value}" && ! is_negative_integer "${value}"
}

function is_positive_float( )
{
   local value="$1"

   [[ "${value}" =~ ^[0-9]+\.[0-9]+$ ]] && \
      [[ ! "${value}" =~ ^0+\.0+$ ]] && \
         return 0 || \
            return 1
}

function is_negative_float( )
{
   local value="$1"

   [[ "${value}" =~ ^-[0-9]+\.[0-9]+$ ]] && \
      [[ ! "${value}" =~ ^-0+\.0+$ ]] && \
         return 0 || \
            return 1
}

function is_float( )
{
   local value="$1"

   [[ "$value" =~ ^-?[0-9]+\.[0-9]+$ ]]
}

function is_non_positive_float( )
{
   local value="$1"

   is_float "${value}" && ! is_positive_float "${value}"
}

function is_non_negative_float( )
{
   local value="$1"

   is_float "${value}" && ! is_negative_float "${value}"
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
