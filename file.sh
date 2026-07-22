[ -n "${__SFW_FILE_SH__}" ] && return 0 || readonly __SFW_FILE_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



# 'get_current_dir' - return the full path to the current location
function get_current_dir( )
{
   # echo $(cd -P -- "$(dirname -- "$0")" && pwd -P)
   # echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
   echo ${PWD}
}

# 'get_current_dir_name' - return the current location directory name
function get_current_dir_name( )
{
   echo ${PWD##*/}
}

# 'get_current_script_dir' - returns the name of called script file
function get_current_script_name( )
{
   # https://stackoverflow.com/a/192337
   echo $(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
}

# 'get_current_script_dir' - returns directory where called script file is placed
function get_current_script_dir( )
{
   # echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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

# This function recurcively searches all files in given directory with given
# extentiones.
# Example:
#     declare -a FILE_LIST=()
#     declare -a EXTENTIONS=( "c" "cpp" "cxx" )
#     find_extentions_in_dir /home EXTENTIONS FILE_LIST
#     echo "FILE_LIST: " ${FILE_LIST[@]}
#     echo "FILE_LIST size: " ${#FILE_LIST[@]}
function find_extentions_in_dir( )
{
   local LOCAL_SEARCH_DIR=${1}
   local -n LOCAL_EXTENTIONS=${2}
   local -n LOCAL_FILE_LIST=${3}

   local LOCAL_PATTERN=""
   for LOCAL_EXTENTION in ${LOCAL_EXTENTIONS[@]} ; do
      LOCAL_PATTERN+="${LOCAL_EXTENTION}|"
   done
   LOCAL_PATTERN=${LOCAL_PATTERN::-1}

   local -a LOCAL_RESULT_LIST=()
   local LOCAL_RESULT_LIST=$( find ${LOCAL_SEARCH_DIR} -regextype posix-extended -regex ".*\.(${LOCAL_PATTERN})" )

   for LOCAL_RESULT_ITEM in ${LOCAL_RESULT_LIST[@]} ; do
      LOCAL_FILE_LIST+=( ${LOCAL_RESULT_ITEM} )
   done
}

#
# Get the names of all subdirectories located directly inside a specified
# directory.
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
