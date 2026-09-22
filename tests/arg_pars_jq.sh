#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "${SCRIPT_DIR}/.." &> /dev/null && pwd )"

source "${REPO_ROOT}/__init__" sfw-arg_pars_jq

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

function __test_skip__( )
{
   printf "[SKIP] %s\n" "${1}"
}

function __test_assert_success__( )
{
   local test_name="${1}"
   shift

   (( ++__TESTS_TOTAL ))

   if "$@" > /dev/null 2>&1; then
      __test_pass__ "${test_name}"
   else
      __test_fail__ "${test_name}"
   fi
}

function __test_assert_failure__( )
{
   local test_name="${1}"
   shift

   (( ++__TESTS_TOTAL ))

   if "$@" > /dev/null 2>&1; then
      __test_fail__ "${test_name}"
   else
      __test_pass__ "${test_name}"
   fi
}

function __test_assert_eq__( )
{
   local test_name="${1}"
   local expected="${2}"
   local actual="${3}"

   (( ++__TESTS_TOTAL ))

   if [[ "${actual}" == "${expected}" ]]; then
      __test_pass__ "${test_name}"
   else
      __test_fail__ "${test_name}: expected '${expected}', got '${actual}'"
   fi
}

function __test_assert_array_eq__( )
{
   local test_name="${1}"
   local expected_name="${2}"
   local actual_name="${3}"
   local -n expected_ref="${expected_name}"
   local -n actual_ref="${actual_name}"

   (( ++__TESTS_TOTAL ))

   if [[ ${#actual_ref[@]} -ne ${#expected_ref[@]} ]]; then
      __test_fail__ "${test_name}: expected ${#expected_ref[@]} values, got ${#actual_ref[@]}"
      return
   fi

   local i
   for i in "${!expected_ref[@]}"; do
      if [[ "${actual_ref[i]}" != "${expected_ref[i]}" ]]; then
         __test_fail__ "${test_name}: expected '${expected_ref[i]}' at index ${i}, got '${actual_ref[i]}'"
         return
      fi
   done

   __test_pass__ "${test_name}"
}

function __test_create_registry__( )
{
   local -n registry_ref="${1}"

   registry_ref="{}"

   register_argument --registry=registry_ref \
      --name="project" \
      --allowed_values="aosp,kernel,uboot" \
      --note="Project to process" \
      --required \
      || return $?

   register_argument --registry=registry_ref \
      --name="action" \
      --allowed_values="info,sync,config,build,deploy,clean" \
      --default_values="info,sync" \
      || return $?

   register_argument --registry=registry_ref \
      --name="target" \
      || return $?

   register_option --registry=registry_ref \
      --name="help" \
      --note="Print usage information" \
      || return $?

   register_option --registry=registry_ref \
      --name="debug" \
      --note="Enable debug output" \
      || return $?

   return 0
}

declare registry
__test_assert_success__ "create registry with arguments and options" \
   __test_create_registry__ registry

declare project_required
json_get_boolean "${registry}" project_required arguments project required
__test_assert_eq__ "register_argument stores required flag" "true" "${project_required}"

declare action_default
json_get_string "${registry}" action_default arguments action values default 0
__test_assert_eq__ "register_argument stores default value" "info" "${action_default}"

declare project_note
json_get_string "${registry}" project_note arguments project note
__test_assert_eq__ "register_argument stores note" "Project to process" "${project_note}"

declare debug_defined
json_get_boolean "${registry}" debug_defined options debug defined
__test_assert_eq__ "register_option initializes option as false" "false" "${debug_defined}"

declare debug_note
json_get_string "${registry}" debug_note options debug note
__test_assert_eq__ "register_option stores note" "Enable debug output" "${debug_note}"

declare help_note
json_get_string "${registry}" help_note options help note
__test_assert_eq__ "register_option stores note for omitted option" "Print usage information" "${help_note}"

__test_assert_success__ "parse_parameters accepts registered arguments and options" \
   parse_parameters registry --project=aosp --target=testrpi5,testrpi12 --debug

project_note=""
json_get_string "${registry}" project_note arguments project note
__test_assert_eq__ "parse_parameters keeps argument note" "Project to process" "${project_note}"

debug_note=""
json_get_string "${registry}" debug_note options debug note
__test_assert_eq__ "parse_parameters keeps option note" "Enable debug output" "${debug_note}"

__test_assert_success__ "validate_parameters accepts parsed valid registry" \
   validate_parameters registry

declare result
__test_assert_success__ "get_argument_value returns explicitly defined argument" \
   get_argument_value --registry=registry --name=project --result=result
__test_assert_eq__ "get_argument_value project value" "aosp" "${result}"

result=""
__test_assert_success__ "get_argument_value returns first value from multi-value argument" \
   get_argument_value --registry=registry --name=target --result=result
__test_assert_eq__ "get_argument_value target first value" "testrpi5" "${result}"

result=""
__test_assert_success__ "get_argument_value returns indexed defined argument" \
   get_argument_value --registry=registry --name=target --index=1 --result=result
__test_assert_eq__ "get_argument_value target second value" "testrpi12" "${result}"

result=""
__test_assert_success__ "get_argument_value accepts numeric plus index" \
   get_argument_value --registry=registry --name=target --index=+1 --result=result
__test_assert_eq__ "get_argument_value target plus-index value" "testrpi12" "${result}"

result=""
__test_assert_success__ "get_argument_value falls back to default value" \
   get_argument_value --registry=registry --name=action --result=result
__test_assert_eq__ "get_argument_value action default value" "info" "${result}"

result=""
__test_assert_success__ "get_argument_value returns indexed default value" \
   get_argument_value --registry=registry --name=action --index=1 --result=result
__test_assert_eq__ "get_argument_value action second default value" "sync" "${result}"

result=""
__test_assert_failure__ "get_argument_value rejects missing defined index" \
   get_argument_value --registry=registry --name=target --index=2 --result=result

result=""
__test_assert_failure__ "get_argument_value rejects missing default index" \
   get_argument_value --registry=registry --name=action --index=2 --result=result

result=""
__test_assert_failure__ "get_argument_value rejects invalid index" \
   get_argument_value --registry=registry --name=target --index=-1 --result=result

result=""
__test_assert_failure__ "get_argument_value rejects negative zero index" \
   get_argument_value --registry=registry --name=target --index=-0 --result=result

declare -a result_values=( )
declare -a expected_values=( testrpi5 testrpi12 )
__test_assert_success__ "get_argument_values returns all defined values" \
   get_argument_values --registry=registry --name=target --result=result_values
__test_assert_array_eq__ "get_argument_values target values" expected_values result_values

result_values=( )
expected_values=( info sync )
__test_assert_success__ "get_argument_values falls back to all default values" \
   get_argument_values --registry=registry --name=action --result=result_values
__test_assert_array_eq__ "get_argument_values action default values" expected_values result_values

result=""
__test_assert_failure__ "get_argument_values rejects scalar result" \
   get_argument_values --registry=registry --name=target --result=result

declare empty_values_registry
__test_create_registry__ empty_values_registry > /dev/null 2>&1
result_values=( )
__test_assert_failure__ "get_argument_values rejects argument without values" \
   get_argument_values --registry=empty_values_registry --name=target --result=result_values

result_values=( )
__test_assert_failure__ "get_argument_values rejects unknown argument name" \
   get_argument_values --registry=registry --name=unknown --result=result_values

result=""
__test_assert_success__ "get_option returns true for parsed option" \
   get_option --registry=registry --name=debug --result=result
__test_assert_eq__ "get_option debug value" 'true' "${result}"

result=""
__test_assert_success__ "get_option returns false for omitted option" \
   get_option --registry=registry --name=help --result=result
__test_assert_eq__ "get_option help value" 'false' "${result}"

__test_assert_success__ "test_option succeeds for parsed option" \
   test_option --registry=registry --name=debug

__test_assert_failure__ "test_option rejects omitted option" \
   test_option --registry=registry --name=help

declare missing_required_registry
__test_create_registry__ missing_required_registry > /dev/null 2>&1
parse_parameters missing_required_registry --debug > /dev/null 2>&1
__test_assert_failure__ "validate_parameters rejects missing required argument" \
   validate_parameters missing_required_registry

declare disallowed_value_registry
__test_create_registry__ disallowed_value_registry > /dev/null 2>&1
parse_parameters disallowed_value_registry --project=bad --debug > /dev/null 2>&1
__test_assert_failure__ "validate_parameters rejects disallowed argument value" \
   validate_parameters disallowed_value_registry

declare unsupported_parameter_registry
__test_create_registry__ unsupported_parameter_registry > /dev/null 2>&1
__test_assert_failure__ "parse_parameters rejects unsupported argument in strict mode" \
   parse_parameters unsupported_parameter_registry --unknown=value

declare invalid_syntax_registry
__test_create_registry__ invalid_syntax_registry > /dev/null 2>&1
__test_assert_failure__ "parse_parameters rejects non-option syntax" \
   parse_parameters invalid_syntax_registry project=aosp

declare invalid_default_registry="{}"
__test_assert_failure__ "register_argument rejects default outside allowed values" \
   register_argument --registry=invalid_default_registry \
      --name=mode \
      --allowed_values=debug,release \
      --default_values=test

declare invalid_name_registry="{}"
__test_assert_failure__ "register_option rejects invalid option name" \
   register_option --registry=invalid_name_registry --name=1debug

result=""
__test_assert_failure__ "get_argument_value rejects unknown argument name" \
   get_argument_value --registry=registry --name=unknown --result=result

result=""
__test_assert_failure__ "get_option rejects unknown option name" \
   get_option --registry=registry --name=unknown --result=result

printf "\narg_pars_jq tests: %d total, %d failed\n" \
   "${__TESTS_TOTAL}" \
   "${__TESTS_FAILED}"

[[ ${__TESTS_FAILED} -eq 0 ]]
