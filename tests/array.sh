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
      if [[ "${actual_ref[index]}" != "${expected_ref[index]}" ]]; then
         __test_fail__ "${name}: element ${index}: expected '${expected_ref[index]}', got '${actual_ref[index]}'"
         return
      fi
   done

   __test_pass__ "${name}"
}



function __test_assert_silent_failure__( )
{
   local name="${1}"
   shift

   (( ++__TESTS_TOTAL ))

   local output
   if output=$( "$@" 2>&1 ); then
      __test_fail__ "${name}: expected failure"
      return
   fi

   if [[ -n "${output}" ]]; then
      __test_fail__ "${name}: expected no output, got '${output}'"
      return
   fi

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

   if [[ ! -v map_ref["${key}"] ]]; then
      __test_fail__ "${name}: key '${key}' is missing"
      return
   fi

   if [[ "${map_ref[${key}]}" != "${expected}" ]]; then
      __test_fail__ "${name}: expected '${expected}', got '${map_ref[${key}]}'"
      return
   fi

   __test_pass__ "${name}"
}



declare -a values=( a b c b d )
array_remove_element values b
declare -a expected_values=( a c d )
__test_assert_array_eq__ "array_remove_element removes all matching middle values" \
   expected_values \
   values

declare -a all_values=( b b )
array_remove_element all_values b
declare -a expected_empty=( )
__test_assert_array_eq__ "array_remove_element removes all elements" \
   expected_empty \
   all_values

declare -a unchanged_values=( a c d )
array_remove_element unchanged_values b
declare -a expected_unchanged=( a c d )
__test_assert_array_eq__ "array_remove_element keeps array when value is absent" \
   expected_unchanged \
   unchanged_values

declare -a spaced_values=( "hello world" keep "hello world" )
array_remove_element spaced_values "hello world"
declare -a expected_spaced=( keep )
__test_assert_array_eq__ "array_remove_element handles values with spaces" \
   expected_spaced \
   spaced_values

declare -a empty_values=( )
array_remove_element empty_values missing
__test_assert_array_eq__ "array_remove_element handles empty array" \
   expected_empty \
   empty_values

declare -a sparse_values=( [2]=keep [5]=drop [9]=tail )
array_remove_element sparse_values drop
declare -a expected_sparse=( keep tail )
__test_assert_array_eq__ "array_remove_element compacts sparse arrays" \
   expected_sparse \
   sparse_values

__test_assert_silent_failure__ "array_add_element rejects missing arguments without diagnostics" \
   array_add_element

__test_assert_silent_failure__ "array_remove_element rejects missing arguments without diagnostics" \
   array_remove_element

__test_assert_silent_failure__ "array_test_element rejects missing arguments without diagnostics" \
   array_test_element

__test_assert_silent_failure__ "map_test_key rejects missing arguments without diagnostics" \
   map_test_key

__test_assert_silent_failure__ "map_test_key_not_empty rejects missing arguments without diagnostics" \
   map_test_key_not_empty

__test_assert_silent_failure__ "map_test_value rejects missing arguments without diagnostics" \
   map_test_value

__test_assert_silent_failure__ "copy_map rejects missing arguments without diagnostics" \
   copy_map

declare -A source_map=(
   [a]="new"
   [b]="2"
)
declare -A destination_map=(
   [old]="keep"
   [a]="old"
)
copy_map destination_map source_map
__test_assert_map_value__ "copy_map keeps destination-only keys" \
   destination_map \
   old \
   keep
__test_assert_map_value__ "copy_map overwrites matching destination keys" \
   destination_map \
   a \
   new
__test_assert_map_value__ "copy_map adds source-only keys" \
   destination_map \
   b \
   2

printf "\narray tests: %d total, %d failed\n" \
   "${__TESTS_TOTAL}" \
   "${__TESTS_FAILED}"

[[ ${__TESTS_FAILED} -eq 0 ]]
