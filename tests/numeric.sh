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

   if "$@" > /dev/null 2>&1; then
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

   if "$@" > /dev/null 2>&1; then
      __test_fail__ "${name}"
   else
      __test_pass__ "${name}"
   fi
}



function __test_assert_output__( )
{
   local name="${1}"
   local expected="${2}"
   shift 2

   (( ++__TESTS_TOTAL ))

   local output
   if ! output=$( "$@" 2> /dev/null ); then
      __test_fail__ "${name}: command failed"
      return
   fi

   if [[ "${output}" == "${expected}" ]]; then
      __test_pass__ "${name}"
   else
      __test_fail__ "${name}: expected '${expected}', got '${output}'"
   fi
}



__test_assert_success__ "is_number accepts leading-dot decimals" \
   is_number .5
__test_assert_success__ "is_number accepts negative leading-dot decimals" \
   is_number -.5
__test_assert_success__ "is_number accepts trailing-dot decimals" \
   is_number 1.
__test_assert_success__ "is_number accepts explicit plus sign" \
   is_number +1
__test_assert_success__ "is_positive_number accepts explicit plus decimal" \
   is_positive_number +.5

__test_assert_failure__ "is_non_negative_integer rejects negative zero" \
   is_non_negative_integer -0
__test_assert_failure__ "get_pi_digits rejects negative zero" \
   get_pi_digits -0
__test_assert_failure__ "get_e_digits rejects negative zero" \
   get_e_digits -0
__test_assert_failure__ "get_phi_digits rejects negative zero" \
   get_phi_digits -0

__test_assert_failure__ "get_pi_digits rejects extra arguments" \
   get_pi_digits 2 ignored
__test_assert_failure__ "get_e_digits rejects extra arguments" \
   get_e_digits 2 ignored
__test_assert_failure__ "get_phi_digits rejects extra arguments" \
   get_phi_digits 2 ignored

__test_assert_output__ "add_numbers adds leading-dot decimals" \
   "0.75" \
   add_numbers .5 .25
__test_assert_output__ "add_numbers adds explicit plus values" \
   "1.5" \
   add_numbers +1 +.5
__test_assert_output__ "get_pi_digits returns requested precision" \
   "3.14159" \
   get_pi_digits 5
__test_assert_output__ "get_e_digits returns requested precision" \
   "2.71828" \
   get_e_digits 5
__test_assert_output__ "get_phi_digits returns requested precision" \
   "1.61803" \
   get_phi_digits 5

fake_bin="$( mktemp -d )"
trap 'rm -rf "${fake_bin}"' EXIT
printf '#!/bin/sh\nexit 42\n' > "${fake_bin}/bc"
chmod +x "${fake_bin}/bc"

__test_assert_failure__ "add_numbers fails when bc calculation fails" \
   env PATH="${fake_bin}:${PATH}" bash -c \
      'source "'"${REPO_ROOT}"'/numeric.sh"; add_numbers 1 2'
__test_assert_failure__ "get_pi_digits fails when bc calculation fails" \
   env PATH="${fake_bin}:${PATH}" bash -c \
      'source "'"${REPO_ROOT}"'/numeric.sh"; get_pi_digits 2'
__test_assert_failure__ "get_e_digits fails when bc calculation fails" \
   env PATH="${fake_bin}:${PATH}" bash -c \
      'source "'"${REPO_ROOT}"'/numeric.sh"; get_e_digits 2'
__test_assert_failure__ "get_phi_digits fails when bc calculation fails" \
   env PATH="${fake_bin}:${PATH}" bash -c \
      'source "'"${REPO_ROOT}"'/numeric.sh"; get_phi_digits 2'

printf "\nnumeric tests: %d total, %d failed\n" \
   "${__TESTS_TOTAL}" \
   "${__TESTS_FAILED}"

[[ ${__TESTS_FAILED} -eq 0 ]]
