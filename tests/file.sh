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



function __test_assert_no_bash_diagnostics__( )
{
   local name="${1}"
   shift

   (( ++__TESTS_TOTAL ))

   local output
   output=$( "$@" 2>&1 )

   if [[ "${output}" == *"local:"* || "${output}" == *"substring expression"* ]]; then
      __test_fail__ "${name}: got Bash diagnostic '${output}'"
      return
   fi

   __test_pass__ "${name}"
}



function __test_array_has__( )
{
   local name="${1}"
   local array_name="${2}"
   local expected="${3}"
   local -n array_ref="${array_name}"

   (( ++__TESTS_TOTAL ))

   local value
   for value in "${array_ref[@]}"; do
      if [[ "${value}" == "${expected}" ]]; then
         __test_pass__ "${name}"
         return
      fi
   done

   __test_fail__ "${name}: '${expected}' not found"
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



tmp_dir="$( mktemp -d )"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/current dir"
pushd "${tmp_dir}/current dir" > /dev/null
__test_assert_eq__ "get_current_dir returns current working directory" \
   "${tmp_dir}/current dir" \
   "$( get_current_dir )"
__test_assert_eq__ "get_current_dir_name returns current directory basename" \
   "current dir" \
   "$( get_current_dir_name )"
popd > /dev/null

mkdir -p "${tmp_dir}/script dir"
script_path="${tmp_dir}/script dir/called script.sh"
{
   printf '#!/bin/bash\n'
   printf 'mode="${1}"\n'
   printf 'shift\n'
   printf 'source "%s/__init__"\n' "${REPO_ROOT}"
   printf 'case "${mode}" in\n'
   printf '   name) get_current_script_name ;;\n'
   printf '   dir) get_current_script_dir ;;\n'
   printf 'esac\n'
} > "${script_path}"
chmod +x "${script_path}"

__test_assert_eq__ "get_current_script_name returns invoked script basename" \
   "called script.sh" \
   "$( "${script_path}" name )"
__test_assert_eq__ "get_current_script_dir returns invoked script directory" \
   "${tmp_dir}/script dir" \
   "$( "${script_path}" dir )"

mkdir -p "${tmp_dir}/dir with spaces/sub dir"
touch "${tmp_dir}/dir with spaces/root file.c"
touch "${tmp_dir}/dir with spaces/sub dir/nested file.cpp"
touch "${tmp_dir}/dir with spaces/sub dir/regex literal.c+"
touch "${tmp_dir}/dir with spaces/sub dir/not-a-match.cx"

declare -a extensions=( c cpp )
declare -a files=( )
__test_assert_success__ "find_extensions_in_dir accepts paths with spaces" \
   find_extensions_in_dir "${tmp_dir}/dir with spaces" extensions files
__test_assert_eq__ "find_extensions_in_dir returns two c/cpp files" \
   "2" \
   "${#files[@]}"
__test_array_has__ "find_extensions_in_dir preserves root file path with spaces" \
   files \
   "${tmp_dir}/dir with spaces/root file.c"
__test_array_has__ "find_extensions_in_dir preserves nested file path with spaces" \
   files \
   "${tmp_dir}/dir with spaces/sub dir/nested file.cpp"

declare -a literal_extensions=( "c+" )
declare -a literal_files=( )
find_extensions_in_dir "${tmp_dir}/dir with spaces" literal_extensions literal_files
__test_assert_eq__ "find_extensions_in_dir treats extension as literal value" \
   "1" \
   "${#literal_files[@]}"
__test_array_has__ "find_extensions_in_dir matches literal regex character" \
   literal_files \
   "${tmp_dir}/dir with spaces/sub dir/regex literal.c+"

declare -a empty_extensions=( )
declare -a empty_result=( )
__test_assert_failure__ "find_extensions_in_dir rejects empty extension list" \
   find_extensions_in_dir "${tmp_dir}/dir with spaces" empty_extensions empty_result

__test_assert_no_bash_diagnostics__ "find_extensions_in_dir rejects missing args without Bash diagnostics" \
   find_extensions_in_dir

declare -a dir_names=( )
mkdir -p "${tmp_dir}/visible" "${tmp_dir}/.hidden"
get_dir_names_list "${tmp_dir}" dir_names
__test_array_has__ "get_dir_names_list returns visible directory" \
   dir_names \
   "visible"
__test_assert_failure__ "get_dir_names_list rejects missing arguments" \
   get_dir_names_list
__test_assert_failure__ "get_dir_names_list rejects non-directory path" \
   get_dir_names_list "${tmp_dir}/missing" dir_names

printf "\nfile tests: %d total, %d failed\n" \
   "${__TESTS_TOTAL}" \
   "${__TESTS_FAILED}"

[[ ${__TESTS_FAILED} -eq 0 ]]
