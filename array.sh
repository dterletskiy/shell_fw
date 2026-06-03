[ -n "${__SFW_ARRAY_SH__}" ] && return 0 || readonly __SFW_ARRAY_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"



# array_add_element( )
#
# Appends a single element to a Bash array by reference.
#
# This function uses a nameref (local -n) to operate directly on the
# target array without copying it or using eval.
#
# Parameters:
#   $1 - Name of the target array (passed by reference)
#   $2 - Element to append
#
# Behavior:
#   - Appends the element to the end of the array
#   - Returns 1 if fewer than 2 arguments are provided
#   - Modifies the array in-place
#   - Preserves spaces and special characters in the element
#
# Requirements:
#   - Bash 4.3+ (nameref support)
#
# Example:
#   my_array=(a b c)
#   array_add_element my_array "hello world"
#   array_add_element my_array 42
#
#   printf '%s\n' "${my_array[@]}"
function array_add_element( )
{
   local -n arr__array_add_element=$1
   local elem=$2

   [[ $# -lt 2 ]] && return 1

   arr__array_add_element+=( "$elem" )
}



# array_remove_element( )
#
# Removes all occurrences of a given element from a Bash array
# using an in-place compaction algorithm.
#
# This implementation avoids full array reconstruction and instead
# uses a write-index strategy to compact the array in a single pass.
#
# Parameters:
#   $1 - Name of the target array (passed by reference via nameref)
#   $2 - Element to remove (all matching values will be removed)
#
# Behavior:
#   - Removes all occurrences of the specified element
#   - Preserves the order of remaining elements
#   - Performs a single-pass O(n) iteration over the array
#   - Compacts the array in-place without full reallocation
#   - Truncates leftover elements at the end of the array
#
# Performance:
#   - Time complexity: O(n)
#   - Avoids full array reconstruction (no arr=( "${arr[@]}" ))
#   - Efficient for large arrays due to in-place updates
#
# Requirements:
#   - Bash 4.3+ (nameref support via local -n)
#
# Example:
#   my_array=(a b c b d b)
#   array_remove_element my_array "b"
#
#   printf '%s\n' "${my_array[@]}"
#   # Output:
#   # a
#   # c
#   # d
function array_remove_element( )
{
   local -n arr__array_test_element=$1
   local elem=$2

   local i write

   write=0

   for i in "${!arr__array_test_element[@]}"; do
      if [[ "${arr__array_test_element[i]}" != "$elem" ]]; then
         arr__array_test_element[write]="${arr__array_test_element[i]}"
         ((write++))
      fi
   done

   # truncate remaining tail
   unset 'arr__array_test_element[@]:write'
}



# array_test_element( )
#
# Checks whether a given element exists in a Bash array.
#
# This function performs a linear search over the array and
# returns a status code indicating whether the element was found.
#
# Parameters:
#   $1 - Name of the target array (passed by reference via nameref)
#   $2 - Element to search for
#
# Behavior:
#   - Iterates over all elements in the array
#   - Compares each element with the provided value
#   - Returns immediately when a match is found
#
# Return values:
#   0 - Element found in the array
#   1 - Element not found
#
# Complexity:
#   - Time complexity: O(n)
#   - Space complexity: O(1)
#
# Notes:
#   - Comparison is exact (string equality)
#   - Preserves POSIX-style return conventions (0 = success)
#   - Safe for values containing spaces and special characters
#
# Example:
#   my_array=(a b c)
#
#   if array_test_element my_array "b"; then
#      echo "found"
#   else
#      echo "not found"
#   fi
function array_test_element( )
{
   local -n list__array_test_element=$1
   local item=$2

   local v

   for v in "${list__array_test_element[@]}"; do
      if [[ "$v" == "$item" ]]; then
         return 0
      fi
   done

   return 1
}



# map_test_key( )
#
# Checks whether a given key exists in a Bash associative array.
#
# This function uses Bash's built-in key existence test (-v) to
# perform an efficient O(1) lookup without iterating over all keys.
#
# Parameters:
#   $1 - Name of the associative array (passed by reference via nameref)
#   $2 - Key to check for existence
#
# Behavior:
#   - Tests whether the specified key exists in the map
#   - Does not iterate over the array
#   - Does not access or modify values
#
# Return values:
#   0 - Key exists in the associative array
#   1 - Key does not exist
#
# Complexity:
#   - Time complexity: O(1)
#   - Space complexity: O(1)
#
# Notes:
#   - Requires Bash 4.2+ for associative arrays
#   - Uses [[ -v map["key"] ]] for reliable key existence checking
#   - Works regardless of the value stored under the key (including empty values)
#
# Example:
#   declare -A map=(
#      [foo]=1
#      [bar]=2
#   )
#
#   if map_test_key map "foo"; then
#      echo "key exists"
#   else
#      echo "key not found"
#   fi
function map_test_key( )
{
   local -n map__map_test_key=$1
   local key=$2

   [[ -v map__map_test_key["$key"] ]]
}



# map_test_key_not_empty()
#
# Checks whether a given key exists in an associative array and
# whether its associated value is not an empty string.
#
# This function combines a key existence test with a value length
# check. A key is considered valid only if it exists in the map and
# its value contains at least one character.
#
# Parameters:
#   $1 - Name of the associative array (passed by reference via nameref)
#   $2 - Key to test
#
# Behavior:
#   - Verifies that the specified key exists in the map
#   - Verifies that the corresponding value is not empty
#   - Does not modify the map
#
# Return values:
#   0 - Key exists and its value is not an empty string
#   1 - Key does not exist or its value is empty
#
# Complexity:
#   - Time complexity: O(1)
#   - Space complexity: O(1)
#
# Notes:
#   - Requires Bash 4.3+ (nameref support via local -n)
#   - Uses [[ -v map["key"] ]] to distinguish between a missing key
#     and an existing key with an empty value
#   - Values containing whitespace characters are considered non-empty
#
# Example:
#   declare -A map=(
#      [user]="admin"
#      [password]=""
#   )
#
#   if map_test_key_not_empty map "user"; then
#      echo "user is set"
#   fi
#
#   if ! map_test_key_not_empty map "password"; then
#      echo "password is not set"
#   fi
function map_test_key_not_empty( )
{
   local -n map__map_test_key_not_empty=$1
   local key=$2

   [[ -v map__map_test_key_not_empty["$key"] && -n "${map__map_test_key_not_empty["$key"]}" ]]
}



# map_test_value( )
#
# Searches for all keys in an associative array that map to a given value
# and returns them via an output array (by reference).
#
# This function performs a linear search over all key-value pairs in the
# associative array and collects all keys whose values match the provided
# target value.
#
# Parameters:
#   $1 - Name of the associative array (passed by reference via nameref)
#   $2 - Value to search for
#   $3 - Name of the output array (passed by reference via nameref)
#
# Behavior:
#   - Clears the output array before use
#   - Iterates over all keys in the map
#   - Compares each value against the target value
#   - Appends matching keys to the output array
#
# Return values:
#   0 - At least one key with the specified value was found
#   1 - No matching values were found
#
# Complexity:
#   - Time complexity: O(n)
#   - Space complexity: O(k), where k is the number of matches
#
# Notes:
#   - Requires Bash 4.3+ (nameref support via local -n)
#   - Matching is based on exact string equality
#   - Order of keys in the output array depends on hash iteration order
#
# Example:
#   declare -A map=(
#      [a]=10
#      [b]=20
#      [c]=10
#      [d]=30
#   )
#
#   declare -a keys
#
#   if map_test_value map "10" keys; then
#      printf '%s\n' "${keys[@]}"
#   fi
#
# Output:
#   a
#   c
function map_test_value( )
{
   local -n map__map_test_value=$1
   local value=$2
   local -n out_keys__map_test_value=$3

   local k

   out_keys__map_test_value=( )

   for k in "${!map__map_test_value[@]}"; do
      if [[ "${map__map_test_value[$k]}" == "$value" ]]; then
         out_keys__map_test_value+=( "$k" )
      fi
   done

   [[ ${#out_keys__map_test_value[@]} -gt 0 ]]
}



# copy_map( )
#
# Copies all key-value pairs from one associative array to another.
#
# This function performs a shallow copy of an associative array using
# namerefs. Each key-value pair from the source map is duplicated into
# the destination map.
#
# Parameters:
#   $1 - Name of the destination associative array (passed by reference)
#   $2 - Name of the source associative array (passed by reference)
#
# Behavior:
#   - Iterates over all keys in the source map
#   - Copies each key and its associated value into the destination map
#   - Overwrites existing keys in the destination if they already exist
#   - Does not modify the source map
#
# Notes:
#   - This is a shallow copy (values are copied, not references)
#   - Requires Bash 4.3+ (nameref support via local -n)
#   - Order of iteration is not guaranteed (associative array behavior)
#
# Complexity:
#   - Time complexity: O(n)
#   - Space complexity: O(n)
#
# Example:
#   declare -A src=(
#      [a]=1
#      [b]=2
#   )
#
#   declare -A dst
#
#   copy_map dst src
#
#   printf '%s\n' "${!dst[@]}"
#   printf '%s\n' "${dst[@]}"
function copy_map( )
{
   local -n copy_map__dst=$1
   local -n copy_map__src=$2

   local key

   for key in "${!copy_map__src[@]}"; do
      copy_map__dst["$key"]="${copy_map__src["$key"]}"
   done
}
