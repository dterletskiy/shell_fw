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
   echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
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
