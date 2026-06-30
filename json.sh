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
# The output depends on the JSON value type:
#   - scalar values are stored in a scalar variable;
#   - objects are stored as compact JSON strings;
#   - arrays are stored in an indexed Bash array.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - path not found or jq evaluation failed
#   2   - invalid JSON (basic validation failed)
#   3   - output variable type does not match JSON value type
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - JSON arrays require the output variable to be declared with
#     'declare -a'.
#   - JSON objects are returned as compact JSON strings.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare email
#   json_get_value "$json" email users 1 contacts email
#
#   declare user
#   json_get_value "$json" user users 0
#
#   declare -a users
#   json_get_value "$json" users users
#
function json_get_value( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 2

   local jq_expr='.'

   local key
   for key in "$@"; do
      if [[ "$key" =~ ^[0-9]+$ ]]; then
         jq_expr+="[$key]"
      else
         jq_expr+="[\"$key\"]"
      fi
   done

   local json_type
   json_type=$( jq -e -r "$jq_expr | type" <<< "$json" 2> /dev/null ) || return 1

   local decl
   decl=$( declare -p "$out_name" 2> /dev/null )

   case "$json_type" in

      array)
         if [[ "$decl" != "declare -a "* ]]; then
            return 3
         fi
         out_ref=()
         mapfile -t out_ref < <( jq -e -c "$jq_expr[]" <<< "$json" ) || return 1
      ;;

      object)
         if [[ "$decl" == "declare -a "* ]]; then
            return 3
         fi
         out_ref=$( jq -e -c "$jq_expr" <<< "$json" 2> /dev/null ) || return 1
      ;;

      *)
         if [[ "$decl" == "declare -a "* ]]; then
            return 3
         fi
         out_ref=$( jq -e -r "$jq_expr" <<< "$json" 2> /dev/null ) || return 1
      ;;

   esac

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



   declare -a users
   if json_get_value "$json" users users; then
      echo "Found: $users"
      echo "Iteration"
      for user in "${users[@]}"; do
         echo ${user}
      done
   else
      echo "Not found"
   fi



   local user
   if json_get_value "$json" user users 1; then
      echo "Found: $user"
   else
      echo "Not found"
   fi



   local user_email
   if json_get_value "$json" user_email users 1 contacts email; then
      echo "Found: $user_email"
   else
      echo "Not found"
   fi



   local user_email
   if json_get_value "$json" user_email users 2 contacts email; then
      echo "Found: $user_email"
   else
      echo "Not found"
   fi



   local result
   json_set_value "$json" result "xxx@yyy.com" users 2 contacts email
   json=${result}



   local user_email
   if json_get_value "$json" user_email users 2 contacts email; then
      echo "Found: $user_email"
   else
      echo "Not found"
   fi



   local result
   json_set_value "$json" result "TITLE_0" title 0 "name"
   json=${result}



   local result
   if json_get_value "$json" result title 0 "name"; then
      echo "Found: $result"
   else
      echo "Not found"
   fi
}
