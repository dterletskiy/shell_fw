#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "${SCRIPT_DIR}/.." &> /dev/null && pwd )"

source "${REPO_ROOT}/__init__"



function print_section( )
{
   printf "\n== %s ==\n" "${1}"
}



print_section "Indexed arrays"

declare -a boards=( testrpi5 testrpi12 )
printf "Initial boards:\n"
printf "   %s\n" "${boards[@]}"

array_add_element boards "carla"
array_add_element boards "defrans"
array_add_element boards "carla"

printf "After adding elements:\n"
printf "   %s\n" "${boards[@]}"

array_remove_element boards "carla"

printf "After removing all 'carla' elements:\n"
printf "   %s\n" "${boards[@]}"

if array_test_element boards "testrpi12"; then
   printf "testrpi12 is present\n"
else
   printf "testrpi12 is absent\n"
fi

if array_test_element boards "carla"; then
   printf "carla is present\n"
else
   printf "carla is absent\n"
fi



print_section "Associative arrays"

declare -A board_ip=(
   [testrpi5]="10.13.64.228"
   [testrpi12]="10.17.84.49"
   [defrans]=""
)

if map_test_key board_ip "testrpi5"; then
   printf "testrpi5 key exists\n"
fi

if map_test_key_not_empty board_ip "defrans"; then
   printf "defrans ip: %s\n" "${board_ip[defrans]}"
else
   printf "defrans ip is empty or missing\n"
fi

declare -a matching_boards
map_test_value board_ip "10.17.84.49" matching_boards

printf "Boards with ip 10.17.84.49:\n"
printf "   %s\n" "${matching_boards[@]}"

declare -A copied_board_ip=(
   [legacy]="192.168.0.10"
   [testrpi5]="0.0.0.0"
)
copy_map copied_board_ip board_ip

printf "Copied map with overlay behavior:\n"
for board in "${!copied_board_ip[@]}"; do
   printf "   %s -> %s\n" "${board}" "${copied_board_ip[${board}]}"
done
