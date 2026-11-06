#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "${SCRIPT_DIR}/.." &> /dev/null && pwd )"

source "${REPO_ROOT}/__init__"

declare -i __TESTS_TOTAL=0
declare -i __TESTS_FAILED=0

function __test_pass__( )
{
   printf "[PASS] %s\n" "${1}"
}

function __test_fail__( )
{
   printf "[FAIL] %s\n" "${1}"
   (( ++__TESTS_FAILED ))
}

function __test_assert_success__( )
{
   local name="${1}"
   shift

   (( ++__TESTS_TOTAL ))

   if "$@"; then
      __test_pass__ "${name}"
   else
      __test_fail__ "${name}"
   fi
}

function __test_assert_failure__( )
{
   local name="${1}"
   shift

   (( ++__TESTS_TOTAL ))

   if "$@"; then
      __test_fail__ "${name}"
   else
      __test_pass__ "${name}"
   fi
}

function __test_assert_eq__( )
{
   local name="${1}"
   local expected="${2}"
   local actual="${3}"

   (( ++__TESTS_TOTAL ))

   if [[ "${actual}" == "${expected}" ]]; then
      __test_pass__ "${name}"
   else
      __test_fail__ "${name}: expected '${expected}', got '${actual}'"
   fi
}

function __test_assert_array_eq__( )
{
   local name="${1}"
   local expected_name="${2}"
   local actual_name="${3}"
   local -n expected_ref="${expected_name}"
   local -n actual_ref="${actual_name}"

   (( ++__TESTS_TOTAL ))

   if [[ ${#actual_ref[@]} -ne ${#expected_ref[@]} ]]; then
      __test_fail__ "${name}: expected ${#expected_ref[@]} elements, got ${#actual_ref[@]}"
      return
   fi

   local index
   for index in "${!expected_ref[@]}"; do
      if [[ "${actual_ref[$index]}" != "${expected_ref[$index]}" ]]; then
         __test_fail__ "${name}: at ${index}, expected '${expected_ref[$index]}', got '${actual_ref[$index]}'"
         return
      fi
   done

   __test_pass__ "${name}"
}

function __test_assert_map_value__( )
{
   local name="${1}"
   local map_name="${2}"
   local key="${3}"
   local expected="${4}"
   local -n map_ref="${map_name}"

   (( ++__TESTS_TOTAL ))

   if [[ "${map_ref[$key]}" == "${expected}" ]]; then
      __test_pass__ "${name}"
   else
      __test_fail__ "${name}: expected '${expected}', got '${map_ref[$key]}'"
   fi
}

json='{
   "title": "shell_fw",
   "enabled": true,
   "disabled": false,
   "count": 3,
   "users": [
      {
         "name": "Alice",
         "age": 30,
         "contacts": {
            "email": "alice@example.com"
         }
      },
      {
         "name": "Bob",
         "age": 41,
         "contacts": {
            "email": "bob@example.com"
         }
      }
   ],
   "settings": {
      "mode": "debug",
      "timeout": 15,
      "features": [
         "json",
         "shell"
      ]
   }
}'

invalid_json='{ "title": '

declare jq_expr
__json_build_jq_expr__ jq_expr users 1 contacts email
__test_assert_eq__ "__json_build_jq_expr__ builds nested object/array path" \
   '.["users"][1]["contacts"]["email"]' \
   "${jq_expr}"

__test_assert_success__ "json_validate accepts valid JSON" \
   json_validate "${json}"
__test_assert_failure__ "json_validate rejects invalid JSON" \
   json_validate "${invalid_json}"

declare value_type
json_get_type "${json}" value_type users 0 contacts
__test_assert_eq__ "json_get_type returns object type" "object" "${value_type}"

__test_assert_success__ "json_test_type accepts matching type" \
   json_test_type "${json}" array users
__test_assert_failure__ "json_test_type rejects mismatched type" \
   json_test_type "${json}" string users

declare title
json_get_string "${json}" title title
__test_assert_eq__ "json_get_string returns string value" "shell_fw" "${title}"

declare email
json_get_string "${json}" email users 1 contacts email
__test_assert_eq__ "json_get_string returns nested string value" "bob@example.com" "${email}"

declare enabled
json_get_boolean "${json}" enabled enabled
__test_assert_eq__ "json_get_boolean returns boolean value" "true" "${enabled}"

declare disabled
json_get_boolean "${json}" disabled disabled
__test_assert_eq__ "json_get_boolean returns false boolean value" "false" "${disabled}"

declare count
json_get_number "${json}" count count
__test_assert_eq__ "json_get_number returns number value" "3" "${count}"

declare -a features
json_get_array "${json}" features settings features
declare -a expected_features=( '"json"' '"shell"' )
__test_assert_array_eq__ "json_get_array returns compact JSON array elements" \
   expected_features \
   features

declare -A settings
json_get_map "${json}" settings settings
__test_assert_map_value__ "json_get_map returns string member as JSON string" \
   settings \
   mode \
   '"debug"'
__test_assert_map_value__ "json_get_map returns array member as compact JSON" \
   settings \
   features \
   '["json","shell"]'

declare user_object
json_get_object "${json}" user_object users 0
__test_assert_eq__ "json_get_object returns compact JSON object" \
   '{"name":"Alice","age":30,"contacts":{"email":"alice@example.com"}}' \
   "${user_object}"

declare users_count
json_get_length "${json}" users_count users
__test_assert_eq__ "json_get_length returns array length" "2" "${users_count}"

declare settings_count
json_get_length "${json}" settings_count settings
__test_assert_eq__ "json_get_length returns object key count" "3" "${settings_count}"

declare updated_json
json_set_value "${json}" updated_json "release" settings mode
declare updated_mode
json_get_string "${updated_json}" updated_mode settings mode
__test_assert_eq__ "json_set_value updates nested string value" "release" "${updated_mode}"

declare ticker_json='{"ticker":{}}'
declare added_json
__test_assert_success__ "json_add_object creates an empty ticker object" \
   json_add_object "$ticker_json" added_json '{}' ticker SPY
__test_assert_success__ "json_add_object stores an object, not a string" \
   json_test_type "$added_json" object ticker SPY
__test_assert_eq__ "json_add_object preserves the original document" \
   '{"ticker":{}}' "$ticker_json"

declare spy_object='{"date":{"period":"max","interval":"1d"},"category":"ETF"}'
__test_assert_success__ "json_add_object stores a populated object" \
   json_add_object "$ticker_json" added_json "$spy_object" ticker SPY
declare spy_period
json_get_string "$added_json" spy_period ticker SPY date period
__test_assert_eq__ "json_add_object preserves nested values" "max" "$spy_period"

declare unchanged_json='unchanged'
json_add_object "$added_json" unchanged_json '{}' ticker SPY
__test_assert_eq__ "json_add_object rejects an existing key" "4" "$?"
__test_assert_eq__ "json_add_object leaves output unchanged on duplicate" \
   'unchanged' "$unchanged_json"
json_add_object "$ticker_json" unchanged_json '{}' missing SPY
__test_assert_eq__ "json_add_object rejects a missing parent" "3" "$?"
json_add_object '{"ticker":[]}' unchanged_json '{}' ticker SPY
__test_assert_eq__ "json_add_object rejects a non-object parent" "3" "$?"
json_add_object "$ticker_json" unchanged_json '[]' ticker SPY
__test_assert_eq__ "json_add_object rejects a non-object value" "2" "$?"
json_add_object "$ticker_json" unchanged_json '{' ticker SPY
__test_assert_eq__ "json_add_object rejects invalid JSON value" "2" "$?"
json_add_object "$invalid_json" unchanged_json '{}' ticker SPY
__test_assert_eq__ "json_add_object rejects invalid source JSON" "1" "$?"
__test_assert_eq__ "json_add_object preserves output on errors" \
   'unchanged' "$unchanged_json"

__test_assert_success__ "json_add_object treats numeric key as object key" \
   json_add_object "$ticker_json" added_json '{}' ticker 123
__test_assert_eq__ "json_add_object stores numeric key under ticker" \
   'object' "$(jq -r '.ticker["123"] | type' <<< "$added_json")"
__test_assert_success__ "json_add_object accepts quoted object keys" \
   json_add_object "$ticker_json" added_json '{}' ticker 'SPY"Q'
__test_assert_eq__ "json_add_object escapes quoted object keys" \
   'object' "$(jq -r --arg key 'SPY"Q' '.ticker[$key] | type' <<< "$added_json")"
declare in_place_json='{"ticker":{}}'
__test_assert_success__ "json_add_object supports same input and output variable" \
   json_add_object "$in_place_json" in_place_json '{}' ticker SPY
__test_assert_eq__ "json_add_object updates caller variable in place" \
   '{"ticker":{"SPY":{}}}' "$in_place_json"

__test_assert_success__ "json_set_json_value inserts an object" \
   json_set_json_value "$ticker_json" added_json "$spy_object" ticker SPY
__test_assert_success__ "json_set_json_value preserves object type" \
   json_test_type "$added_json" object ticker SPY
__test_assert_success__ "json_set_json_value replaces an existing object" \
   json_set_json_value "$added_json" added_json '{"category":"Index"}' ticker SPY
declare spy_category
json_get_string "$added_json" spy_category ticker SPY category
__test_assert_eq__ "json_set_json_value writes replacement object" \
   'Index' "$spy_category"
__test_assert_success__ "json_set_json_value writes JSON boolean false" \
   json_set_json_value "$added_json" added_json 'false' ticker SPY enabled
__test_assert_eq__ "json_set_json_value keeps boolean type" \
   'boolean' "$(jq -r '.ticker.SPY.enabled | type' <<< "$added_json")"
__test_assert_success__ "json_set_json_value writes JSON null" \
   json_set_json_value "$added_json" added_json 'null' ticker SPY note
__test_assert_eq__ "json_set_json_value keeps null type" \
   'null' "$(jq -r '.ticker.SPY.note | type' <<< "$added_json")"
__test_assert_success__ "json_set_json_value writes an array" \
   json_set_json_value "$added_json" added_json '[1,2]' ticker SPY values
__test_assert_eq__ "json_set_json_value keeps array elements" \
   '[1,2]' "$(jq -c '.ticker.SPY.values' <<< "$added_json")"
__test_assert_success__ "json_set_json_value escapes path keys" \
   json_set_json_value "$ticker_json" added_json '42' ticker 'SPY"Q' count
__test_assert_eq__ "json_set_json_value writes numeric value at quoted key" \
   '42' "$(jq -r --arg key 'SPY"Q' '.ticker[$key].count' <<< "$added_json")"
__test_assert_success__ "json_set_json_value supports same input and output variable" \
   json_set_json_value "$in_place_json" in_place_json '1' ticker SPY count
__test_assert_eq__ "json_set_json_value updates caller variable in place" \
   '{"ticker":{"SPY":{"count":1}}}' "$in_place_json"
__test_assert_success__ "json_set_json_value creates missing nested objects" \
   json_set_json_value "$ticker_json" added_json '"max"' ticker SPY date period
__test_assert_eq__ "json_set_json_value preserves JSON string type" \
   'string' "$(jq -r '.ticker.SPY.date.period | type' <<< "$added_json")"
declare unchanged_value='unchanged'
json_set_json_value "$ticker_json" unchanged_value 'not JSON' ticker SPY
__test_assert_eq__ "json_set_json_value rejects invalid value" "2" "$?"
json_set_json_value "$invalid_json" unchanged_value '{}' ticker SPY
__test_assert_eq__ "json_set_json_value rejects invalid source JSON" "1" "$?"
__test_assert_eq__ "json_set_json_value preserves output on error" \
   'unchanged' "$unchanged_value"

declare array_json
json_add_array_value "${json}" array_json "tests" settings features
declare -a updated_features
json_get_array "${array_json}" updated_features settings features
declare -a expected_updated_features=( '"json"' '"shell"' '"tests"' )
__test_assert_array_eq__ "json_add_array_value appends string value" \
   expected_updated_features \
   updated_features

declare generic_title
json_get_value "${json}" generic_title title
__test_assert_eq__ "json_get_value returns compact scalar representation" \
   "shell_fw" \
   "${generic_title}"

declare generic_user
json_get_value "${json}" generic_user users 0
__test_assert_eq__ "json_get_value returns compact object representation" \
   '{"name":"Alice","age":30,"contacts":{"email":"alice@example.com"}}' \
   "${generic_user}"

declare -a generic_features
json_get_value "${json}" generic_features settings features
__test_assert_array_eq__ "json_get_value returns nested array by target path type" \
   expected_features \
   generic_features

declare generic_email
json_get_value "${json}" generic_email users 1 contacts email
__test_assert_eq__ "json_get_value returns nested scalar by target path type" \
   "bob@example.com" \
   "${generic_email}"

declare generic_contact
json_get_value "${json}" generic_contact users 0 contacts
__test_assert_eq__ "json_get_value returns nested object by target path type" \
   '{"email":"alice@example.com"}' \
   "${generic_contact}"

declare generic_disabled
json_get_value "${json}" generic_disabled disabled
__test_assert_eq__ "json_get_value returns false boolean without failure" \
   "false" \
   "${generic_disabled}"

printf "\nJSON tests: %d total, %d failed\n" \
   "${__TESTS_TOTAL}" \
   "${__TESTS_FAILED}"

[[ ${__TESTS_FAILED} -eq 0 ]]
