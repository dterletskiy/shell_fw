#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "${SCRIPT_DIR}/.." &> /dev/null && pwd )"

source "${REPO_ROOT}/__init__" sfw-arg_pars_jq



function print_section( )
{
   printf "\n== %s ==\n" "${1}"
}



function print_usage( )
{
   cat << EOF
Usage:
   ${0} --project=<name> [--action=<name>] [--target=<name>[,<name>]] [--debug] [--help]

Arguments:
   --project=<name>
      Required. Allowed values: aosp, kernel, uboot.

   --action=<name>
      Optional. Allowed values: info, sync, config, build, deploy, clean.
      Default value: info.

   --target=<name>[,<name>]
      Optional. Accepts one or more comma-separated values.

Options:
   --debug
      Enables debug mode.

   --help
      Prints this help.

Examples:
   ${0} --project=aosp --target=testrpi5,testrpi12 --debug
   ${0} --project=kernel --action=build --target=testrpi5
EOF
}



function create_registry( )
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
      --note="Action to execute for the selected project" \
      --default_values="info,sync" \
      || return $?

   register_argument --registry=registry_ref \
      --name="target" \
      --note="Target board names as a comma-separated list" \
      || return $?

   register_option --registry=registry_ref \
      --name="help" \
      --note="Print usage information" \
      || return $?

   register_option --registry=registry_ref \
      --name="debug" \
      --note="Enable debug output" \
      || return $?
}



function show_registered_notes( )
{
   local -n registry_ref="${1}"
   local result

   print_section "Registered notes"

   json_get_string "${registry_ref}" result arguments project note
   printf "project: %s\n" "${result}"

   json_get_string "${registry_ref}" result arguments action note
   printf "action: %s\n" "${result}"

   json_get_string "${registry_ref}" result arguments target note
   printf "target: %s\n" "${result}"

   json_get_string "${registry_ref}" result options debug note
   printf "debug: %s\n" "${result}"

   json_get_string "${registry_ref}" result options help note
   printf "help: %s\n" "${result}"
}



function show_effective_parameters( )
{
   local -n registry_ref="${1}"
   local result
   local -a results=( )

   print_section "Effective arguments"

   get_argument_value --registry=registry_ref --name="project" --result=result
   printf "project: %s\n" "${result}"

   get_argument_value --registry=registry_ref --name="action" --result=result
   printf "action: %s\n" "${result}"

   if get_argument_value --registry=registry_ref --name="action" --index=1 --result=result > /dev/null 2>&1; then
      printf "fallback action[1]: %s\n" "${result}"
   else
      printf "fallback action[1]: <not available>\n"
   fi

   if get_argument_value --registry=registry_ref --name="target" --result=result; then
      printf "first target: %s\n" "${result}"
   else
      printf "first target: <not set>\n"
   fi

   if get_argument_value --registry=registry_ref --name="target" --index=1 --result=result > /dev/null 2>&1; then
      printf "second target: %s\n" "${result}"
   else
      printf "second target: <not set>\n"
   fi

   if get_argument_values --registry=registry_ref --name="action" --result=results; then
      printf "all action values: %s\n" "${results[*]}"
   else
      printf "all action values: <not set>\n"
   fi

   if get_argument_values --registry=registry_ref --name="target" --result=results; then
      printf "all target values: %s\n" "${results[*]}"
   else
      printf "all target values: <not set>\n"
   fi

   print_section "Options"

   get_option --registry=registry_ref --name="debug" --result=result
   printf "debug: %s\n" "${result}"

   get_option --registry=registry_ref --name="help" --result=result
   printf "help: %s\n" "${result}"

   if test_option --registry=registry_ref --name="debug"; then
      printf "debug option is enabled\n"
   else
      printf "debug option is disabled\n"
   fi
}



declare PARAMETERS
create_registry PARAMETERS || exit $?

if [[ ${#} -eq 0 ]]; then
   set -- --project=aosp --target=testrpi5,testrpi12 --debug
   print_section "No arguments passed, using demo input"
   printf "%s\n" "$*"
fi

print_section "Registry before parsing"
printf "%s\n" "${PARAMETERS}" | jq .

parse_parameters PARAMETERS "${@}" || exit $?

if test_option --registry=PARAMETERS --name="help"; then
   print_usage
   exit 0
fi

validate_parameters PARAMETERS || exit $?

print_section "Registry after parsing"
printf "%s\n" "${PARAMETERS}" | jq .

show_registered_notes PARAMETERS
show_effective_parameters PARAMETERS
