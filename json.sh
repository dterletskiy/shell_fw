[ -n "${__SFW_JSON_SH__}" ] && return 0 || readonly __SFW_JSON_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/ui.sh"



function json_validate( )
{
   local json=${1}

   # if [[ ! "$json" =~ ^[[:space:]]*[\{\[] ]]; then
   #    return 1
   # fi

   # --------------------------------------------------
   # Strict JSON validation (REAL check via jq)
   # --------------------------------------------------
   if ! jq -e . <<< "$json" > /dev/null 2>&1; then
      return 1
   fi

   return 0
}

#
# Get a value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a value from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success, value stored in output variable
#   1   - path not found or jq evaluation failed
#   2   - invalid JSON (basic validation failed)
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric arguments are treated as array indices.
#   - String arguments are treated as object keys.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   result=""
#   json_get_value "$json" result users 1 contacts email
#
function json_get_value( )
{
   local json="$1"
   local -n out_ref=$2
   shift 2

   out_ref=""

   test_required_util "jq" || return 127
   json_validate "${json}" || return 2

   local jq_expr='.'

   for key in "$@"
   do
      if [[ "$key" =~ ^[0-9]+$ ]]; then
         jq_expr+="[$key]"
      else
         jq_expr+="[\"$key\"]"
      fi
   done

   local value
   value=$(jq -e -r "$jq_expr" <<< "$json" 2> /dev/null)
   local rc=$?

   if [[ $rc -ne 0 ]]; then
      return 1
   fi

   out_ref="$value"
   return 0
}



#
# Set a value in a JSON object by a dynamic path.
#
# Uses jq to update a JSON document and returns a new JSON string.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3  - value to set
#   $4+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success, updated JSON stored in output variable
#   1   - path not found or jq evaluation failed
#   2   - invalid JSON (basic validation failed)
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric arguments are treated as array indices.
#   - String arguments are treated as object keys.
#   - jq may implicitly create missing structures depending on path.
#   - Value is safely passed via jq --argjson.
#
# Warning:
#   Behavior may differ between object and array expansion due to jq rules.
#
# Example:
#   result=""
#   json_set_value "$json" result "Alice" users 0 name
#
function json_set_value( )
{
   local json="$1"
   local -n out_ref=$2
   local value="$3"
   shift 3

   out_ref=""

   test_required_util "jq" || return $?
   json_validate "${json}" || return 2

   local jq_path='.'

   for key in "$@"
   do
      if [[ "$key" =~ ^[0-9]+$ ]]; then
         jq_path+="[$key]"
      else
         jq_path+="[\"$key\"]"
      fi
   done

   local new_json
   new_json=$(jq -e --argjson v "$(jq -Rn --arg x "$value" '$x')" \
      "$jq_path = \$v" <<< "$json" 2> /dev/null)

   local rc=$?

   if [[ $rc -ne 0 ]]; then
      return 1
   fi

   out_ref="$new_json"
   return 0
}



function json_test( )
{
   json='{
      "users": [
         {
            "name": "Alice",
            "contacts": {
               "email": "alice@example.com"
            }
         },
         {
            "name": "Bob",
            "contacts": {
               "email": "bob@example.com"
            }
         }
      ]
   }'

   local result

   if json_get_value "$json" result users 1 contacts email; then
      echo "Found: $result"
   else
      echo "Not found"
   fi

   if json_get_value "$json" result users 2 contacts email; then
      echo "Found: $result"
   else
      echo "Not found"
   fi

   json_set_value "$json" result "xxx@yyy.com" users 2 contacts email
   json=${result}

   if json_get_value "$json" result users 2 contacts email; then
      echo "Found: $result"
   else
      echo "Not found"
   fi

   json_set_value "$json" result "TITLE_0" title 0 "name"
   json=${result}

   if json_get_value "$json" result title 0 "name"; then
      echo "Found: $result"
   else
      echo "Not found"
   fi
}
