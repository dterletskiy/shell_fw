[ -n "${__SFW_JSON_SH__}" ] && return 0 || readonly __SFW_JSON_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/ui.sh"



#
# Build a jq path expression from a JSON path.
#
# Constructs a jq expression that can be used to access a JSON value
# by a variable-length path.
#
# Arguments:
#   $1  - output variable name (nameref)
#   $2+ - path (keys and/or numeric indices)
#
# Return codes:
#   0 - success
#
# Notes:
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#
# Example:
#   declare jq_expr
#
#   __json_build_jq_expr__ \
#      jq_expr \
#      arguments project values allowed 0
#
#   echo "$jq_expr"
#   # .["arguments"]["project"]["values"]["allowed"][0]
#
function __json_build_jq_expr__( )
{
   local -n out_ref=$1
   shift

   out_ref='.'

   local key
   for key in "$@"; do
      if [[ "$key" =~ ^[0-9]+$ ]]; then
         out_ref+="[$key]"
      else
         out_ref+="[\"$key\"]"
      fi
   done

   return 0
}



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
# Get the type of a JSON value by a dynamic path.
#
# Uses jq to determine the type of a value located at the specified
# path in a JSON document.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not a scalar
#   3   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Returned types:
#   object
#   array
#   string
#   number
#   boolean
#   null
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare type
#
#   json_get_type \
#      "$json" \
#      type \
#      arguments project values allowed
#
#   echo "$type"
#   # array
#
function json_get_type( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   local variable_type
   get_variable_type "$out_name" variable_type

   if [[ "$variable_type" != "scalar" ]]; then
      return 2
   fi

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=$( jq -e -r "$jq_expr | type" <<< "$json" 2> /dev/null ) || return 3

   return 0
}



#
# Test the type of a JSON value.
#
# Determines the type of a JSON value located at the specified path
# and compares it with the expected type.
#
# Arguments:
#   $1  - JSON string
#   $2  - expected JSON type
#   $3+ - path (keys and/or numeric indices)
#
# Supported JSON types:
#   object
#   array
#   string
#   number
#   boolean
#   null
#
# Return codes:
#   0   - JSON value has the expected type
#   1   - invalid JSON (basic validation failed)
#   2   - path not found or jq evaluation failed
#   3   - JSON value type does not match the expected type
#   127 - required utility (jq) is not available
#
# Example:
#   if json_test_type "$json" string arguments action value; then
#      echo "It's a string."
#   fi
#
#   if json_test_type "$json" array arguments project values allowed; then
#      echo "It's an array."
#   fi
#
function json_test_type( )
{
   local json="$1"
   local expected_type="$2"
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   local json_type
   json_get_type "$json" json_type "$@" || return 2

   [[ "$json_type" == "$expected_type" ]] || return 3

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
   json_validate "$json" || return 1

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
   json_get_type "${json}" json_type || return 2

   local decl
   get_variable_type "${out_name}" decl

   # log_info "processing:"
   # log_info "   json_type: ${json_type}"
   # log_info "   jq_expr: ${jq_expr}"
   # log_info "   decl: ${decl}"

   case "$json_type" in

      array)
         if [[ "$decl" != "array" ]]; then
            return 3
         fi
         local tmp
         tmp=$( jq -e -c "$jq_expr[]" <<< "$json" ) || return 4
         out_ref=( )
         mapfile -t out_ref <<< "$tmp"
         # mapfile -t out_ref < <( jq -e -c "$jq_expr[]" <<< "$json" ) || return 1
      ;;

      object)
         if [[ "$decl" == "array" ]]; then
            return 5
         fi
         out_ref=""
         out_ref=$( jq -e -c "$jq_expr" <<< "$json" 2> /dev/null ) || return 6
      ;;

      null)
         return 7
      ;;

      *)
         if [[ "$decl" == "array" ]]; then
            return 8
         fi
         out_ref=""
         out_ref=$( jq -e -r "$jq_expr" <<< "$json" 2> /dev/null ) || return 9
      ;;

   esac

   return 0
}



#
# Get a string value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a string value from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not a scalar
#   3   - JSON value is not a string
#   4   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Only JSON values of type "string" are accepted.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare value
#
#   json_get_string \
#      "$json" \
#      value \
#      artifacts dom0_kernel source file
#
#   echo "$value"
#
function json_get_string( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   test_variable_type "$out_name" scalar || return 2

   json_test_type "$json" "string" "$@" || return 3

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=$( jq -e -r "$jq_expr" <<< "$json" 2> /dev/null ) || return 4

   return 0
}



#
# Get an array value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a JSON array from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# Each array element is returned as a compact JSON string in the output
# Bash indexed array.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not an indexed array
#   3   - JSON value is not an array
#   4   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Only JSON values of type "array" are accepted.
#   - Each element is returned in compact JSON form.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare -a jump
#
#   json_get_array \
#      "$json" \
#      jump \
#      artifacts dom0_kernel jump
#
#   printf '%s\n' "${jump[@]}"
#
function json_get_array( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   test_variable_type "$out_name" array || return 2

   json_test_type "$json" "array" "$@" || return 3

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=()

   local tmp
   tmp=$( jq -e -c "$jq_expr[]" <<< "$json" 2> /dev/null ) || return 4
   mapfile -t out_ref <<< "$tmp"

   return 0
}



#
# Get an object value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a JSON object from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# Each object member is returned as a key/value pair in the output
# Bash associative array. Values are returned as compact JSON strings.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not an associative array
#   3   - JSON value is not an object
#   4   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Only JSON values of type "object" are accepted.
#   - Values are returned in compact JSON form.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare -A source
#
#   json_get_map \
#      "$json" \
#      source \
#      artifacts dom0_kernel source
#
#   echo "${source[type]}"
#   echo "${source[file]}"
#
function json_get_map( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   test_variable_type "$out_name" map || return 2

   json_test_type "$json" "object" "$@" || return 3

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=()

   local line
   while IFS=$'\t' read -r key value; do
      out_ref["$key"]="$value"
   done < <(
      jq -e -r "$jq_expr | to_entries[] | [.key, (.value|tojson)] | @tsv" \
         <<< "$json" 2> /dev/null
   ) || return 4

   return 0
}



#
# Get an object value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a JSON object from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# The object is returned as a compact JSON string.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not a scalar
#   3   - JSON value is not an object
#   4   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Only JSON values of type "object" are accepted.
#   - The returned object is serialized as compact JSON.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare source
#
#   json_get_object \
#      "$json" \
#      source \
#      artifacts dom0_kernel source
#
#   echo "$source"
#
#   declare file
#   json_get_string "$source" file file
#
#   echo "$file"
#
function json_get_object( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   test_variable_type "$out_name" scalar || return 2

   json_test_type "$json" "object" "$@" || return 3

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=$( jq -e -c "$jq_expr" <<< "$json" 2> /dev/null ) || return 4

   return 0
}



#
# Get a boolean value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a boolean value from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not a scalar
#   3   - JSON value is not a boolean
#   4   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Only JSON values of type "boolean" are accepted.
#   - The returned value is either "true" or "false".
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare root
#
#   json_get_boolean \
#      "$json" \
#      root \
#      artifacts dom0_kernel source root
#
#   echo "$root"
#
function json_get_boolean( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   test_variable_type "$out_name" scalar || return 2

   json_test_type "$json" "boolean" "$@" || return 3

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=$( jq -e -r "$jq_expr" <<< "$json" 2> /dev/null ) || return 4

   return 0
}



#
# Get a number value from a JSON object by a dynamic path.
#
# Uses jq to safely extract a number value from nested JSON structures
# (objects and arrays) using a variable-length path.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - output variable is not a scalar
#   3   - JSON value is not a number
#   4   - path not found or jq evaluation failed
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - Only JSON values of type "number" are accepted.
#   - The returned value is the textual representation of the JSON number.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare timeout
#
#   json_get_number \
#      "$json" \
#      timeout \
#      settings timeout
#
#   echo "$timeout"
#
function json_get_number( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   test_variable_type "$out_name" scalar || return 2

   json_test_type "$json" "number" "$@" || return 3

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=$( jq -e -r "$jq_expr" <<< "$json" 2> /dev/null ) || return 4

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

   test_required_util "jq" || return 127
   json_validate "${json}" || return 1

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   local new_json
   new_json=$(jq -e --argjson v "$(jq -Rn --arg x "$value" '$x')" \
      "$jq_expr = \$v" <<< "$json" 2> /dev/null)

   local rc=$?

   if [[ $rc -ne 0 ]]; then
      return 2
   fi

   out_ref="$new_json"
   return 0
}



#
# Append a value to an existing JSON array.
#
# Uses jq to append a new element to a JSON array located at the
# specified path. The original JSON is not modified; the updated
# JSON document is returned in the output variable.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3  - value to append
#   $4+ - path to the target array (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - target path not found, target is not an array,
#         or jq evaluation failed
#   2   - invalid JSON (basic validation failed)
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - The target JSON value must already exist and be an array.
#   - The appended value is treated as a JSON string.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare updated_json
#
#   json_add_array_value \
#      "$json" \
#      updated_json \
#      "recovery" \
#      arguments project values allowed
#
function json_add_array_value( )
{
   local json="$1"
   local out_name="$2"
   local value="$3"
   local -n out_ref=$out_name
   shift 3

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   local jq_expr
   __json_build_jq_expr__ jq_expr "$@"

   out_ref=$(
         jq \
            --arg value "$value" \
            "$jq_expr += [ \$value ]" \
            <<< "$json" \
            2> /dev/null
      ) || return 2

   return 0
}



#
# Get the length of a JSON value.
#
# Uses jq to determine the length of a JSON array, object, or string
# located at the specified path.
#
# Arguments:
#   $1  - JSON string
#   $2  - output variable name (nameref)
#   $3+ - path (keys and/or numeric indices)
#
# Return codes:
#   0   - success
#   1   - invalid JSON (basic validation failed)
#   2   - path not found or jq evaluation failed
#   3   - output variable is not a scalar
#   127 - required utility (jq) is not available
#
# Notes:
#   - Requires jq to be installed.
#   - Numeric path elements are treated as array indices.
#   - String path elements are treated as object keys.
#   - For arrays, returns the number of elements.
#   - For objects, returns the number of keys.
#   - For strings, returns the number of characters.
#   - Performs only a simple JSON sanity check.
#
# Example:
#   declare count
#
#   json_get_length \
#      "$json" \
#      count \
#      artifacts dom0_kernel jump
#
#   echo "$count"
#
function json_get_length( )
{
   local json="$1"
   local out_name="$2"
   local -n out_ref=$out_name
   shift 2

   test_required_util "jq" || return 127
   json_validate "$json" || return 1

   local variable_type
   get_variable_type "$out_name" variable_type

   if [[ "$variable_type" != "scalar" ]]; then
      return 3
   fi

   local jq_expr='.'

   local key
   for key in "$@"; do
      if [[ "$key" =~ ^[0-9]+$ ]]; then
         jq_expr+="[$key]"
      else
         jq_expr+="[\"$key\"]"
      fi
   done

   out_ref=$(
      jq -e -r "$jq_expr | length" <<< "$json" 2> /dev/null
   ) || return 2

   return 0
}



# json_remove_array_value
# json_remove_key
# json_has_key
# json_get_keys



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
