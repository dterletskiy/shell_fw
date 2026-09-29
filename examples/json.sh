#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "${SCRIPT_DIR}/.." &> /dev/null && pwd )"

source "${REPO_ROOT}/__init__"



function print_section( )
{
   printf "\n== %s ==\n" "${1}"
}



json=$(cat <<'EOF'
{
   "project": {
      "name": "shell_fw",
      "enabled": true,
      "retries": 3,
      "maintainers": [
         {
            "name": "Alice",
            "email": "alice@example.com"
         },
         {
            "name": "Bob",
            "email": "bob@example.com"
         }
      ],
      "features": [
         "json",
         "logging"
      ],
      "settings": {
         "mode": "debug",
         "strict": false
      }
   }
}
EOF
)



print_section "Input JSON"
printf "%s\n" "${json}" | jq .



print_section "Validate JSON"
if json_validate "${json}"; then
   printf "JSON is valid\n"
else
   printf "JSON is invalid\n"
fi



print_section "Get value types"
declare value_type
json_get_type "${json}" value_type project maintainers
printf "project.maintainers type: %s\n" "${value_type}"

if json_test_type "${json}" object project settings; then
   printf "project.settings is an object\n"
fi



print_section "Get scalar values"
declare project_name
json_get_string "${json}" project_name project name
printf "project.name: %s\n" "${project_name}"

declare enabled
json_get_boolean "${json}" enabled project enabled
printf "project.enabled: %s\n" "${enabled}"

declare strict
json_get_boolean "${json}" strict project settings strict
printf "project.settings.strict: %s\n" "${strict}"

declare retries
json_get_number "${json}" retries project retries
printf "project.retries: %s\n" "${retries}"



print_section "Get arrays"
declare -a features
json_get_array "${json}" features project features
printf "project.features:\n"
printf "   %s\n" "${features[@]}"

declare -a maintainers
json_get_array "${json}" maintainers project maintainers
printf "project.maintainers:\n"
printf "   %s\n" "${maintainers[@]}"



print_section "Get object and map"
declare settings_object
json_get_object "${json}" settings_object project settings
printf "project.settings object: %s\n" "${settings_object}"

declare -A settings_map
json_get_map "${json}" settings_map project settings
printf "project.settings map mode: %s\n" "${settings_map[mode]}"
printf "project.settings map strict: %s\n" "${settings_map[strict]}"



print_section "Get lengths"
declare maintainers_count
json_get_length "${json}" maintainers_count project maintainers
printf "project.maintainers length: %s\n" "${maintainers_count}"

declare settings_count
json_get_length "${json}" settings_count project settings
printf "project.settings keys: %s\n" "${settings_count}"



print_section "Generic json_get_value"
declare generic_name
json_get_value "${json}" generic_name project name
printf "project.name through json_get_value: %s\n" "${generic_name}"

declare generic_strict
json_get_value "${json}" generic_strict project settings strict
printf "project.settings.strict through json_get_value: %s\n" "${generic_strict}"

declare -a generic_features
json_get_value "${json}" generic_features project features
printf "project.features through json_get_value:\n"
printf "   %s\n" "${generic_features[@]}"



print_section "Modify JSON"
declare updated_json
json_set_value "${json}" updated_json "release" project settings mode
json_add_array_value "${updated_json}" updated_json "tests" project features

printf "%s\n" "${updated_json}" | jq .
