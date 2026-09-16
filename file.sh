[ -n "${__SFW_FILE_SH__}" ] && return 0 || readonly __SFW_FILE_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



#
# Print the current working directory.
#
# Output:
#   Absolute or shell-current value of PWD.
#
# Notes:
#   - This function prints the value of the PWD shell variable.
#
function get_current_dir( )
{
   echo ${PWD}
}



#
# Print the basename of the current working directory.
#
# Output:
#   Last path component of PWD.
#
function get_current_dir_name( )
{
   echo ${PWD##*/}
}



#
# Print the name of the invoked script.
#
# Output:
#   Basename of $0, resolving one symlink level when $0 itself is a symlink.
#
function get_current_script_name( )
{
   echo $(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
}



#
# Print the directory of the invoked script.
#
# Output:
#   Physical directory path containing the invoked script.
#
# Notes:
#   - Symlinks in the script path are resolved before the directory is printed.
#
function get_current_script_dir( )
{
   local source="${BASH_SOURCE[-1]}"

   while [ -h "$source" ]
   do
      local dir="$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )"
      source="$( readlink "$source" )"

      [[ "$source" != /* ]] && source="$dir/$source"
   done

   local dir="$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )"
   echo "$dir"
}

#
# Recursively find files with the requested extensions.
#
# Parameters:
#   $1 - Directory to search in.
#   $2 - Name of an array containing extensions without the leading dot.
#   $3 - Name of an array that will receive matching file paths.
#
# Return values:
#   0 - Success.
#   1 - Invalid arguments, invalid directory, or empty extension list.
#
# Notes:
#   - Paths and file names containing spaces are preserved.
#   - Extension values are matched literally, not as regular expressions.
#   - The result array is appended to and is not cleared by this function.
#
# Example:
#   declare -a FILE_LIST=()
#   declare -a EXTENSIONS=( "c" "cpp" "cxx" )
#   find_extensions_in_dir /home EXTENSIONS FILE_LIST
#   printf '%s\n' "${FILE_LIST[@]}"
function find_extensions_in_dir( )
{
   if (( $# != 3 )); then
      log_error "Usage: find_extensions_in_dir <directory> <extensions> <result>"
      return 1
   fi

   local LOCAL_SEARCH_DIR=${1}
   local -n LOCAL_EXTENSIONS=${2}
   local -n LOCAL_FILE_LIST=${3}

   if [[ ! -d "${LOCAL_SEARCH_DIR}" ]]; then
      log_error "'${LOCAL_SEARCH_DIR}' is not a directory"
      return 1
   fi

   if (( ${#LOCAL_EXTENSIONS[@]} == 0 )); then
      log_error "extension list is empty"
      return 1
   fi

   local -a LOCAL_FIND_EXPRESSION=( )
   local LOCAL_EXTENSION
   for LOCAL_EXTENSION in "${LOCAL_EXTENSIONS[@]}" ; do
      [[ -n "${LOCAL_EXTENSION}" ]] || continue
      LOCAL_FIND_EXPRESSION+=( -name "*.${LOCAL_EXTENSION}" -o )
   done

   if (( ${#LOCAL_FIND_EXPRESSION[@]} == 0 )); then
      log_error "extension list is empty"
      return 1
   fi
   unset 'LOCAL_FIND_EXPRESSION[-1]'

   local LOCAL_RESULT_ITEM
   while IFS= read -r -d '' LOCAL_RESULT_ITEM; do
      LOCAL_FILE_LIST+=( "${LOCAL_RESULT_ITEM}" )
   done < <(
      find "${LOCAL_SEARCH_DIR}" \
         -type f \
         \( "${LOCAL_FIND_EXPRESSION[@]}" \) \
         -print0
   )
}

# Get direct visible subdirectory names.
#
# Parameters:
#    $1 - Path to the directory to scan.
#    $2 - Name of an array variable that will receive the list of
#         subdirectory names.
#
# Returns:
#    0 - Success.
#    1 - Invalid arguments or the specified directory does not exist.
#
# Notes:
#    - Only immediate subdirectories are returned.
#    - Only directory names are returned; parent paths are omitted.
#    - Hidden directories (whose names begin with '.') are not included.
#
function get_dir_names_list( )
{
   if (( $# != 2 )); then
      log_error "Usage: get_dir_names_list <directory> <result>"
      return 1
   fi

   local directory="$1"
   local -n result_ref="$2"

   if [[ ! -d "${directory}" ]]; then
      log_error "'${directory}' is not a directory"
      return 1
   fi

   result_ref=( )

   local entry
   for entry in "${directory}"/*; do
      [[ -d "${entry}" ]] || continue
      result_ref+=( "${entry##*/}" )
   done

   return 0
}
