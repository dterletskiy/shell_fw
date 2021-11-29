function get_current_dir( )
{
   # echo $(cd -P -- "$(dirname -- "$0")" && pwd -P)
   # echo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
   echo ${PWD}
}

function get_current_dir_name( )
{
   echo ${PWD##*/}
}

function remove_dir( )
{
   if [ $# -lt 1 ]; then return 2; fi

   local DIR_PATH=$1
   if [ -d "${DIR_PATH}" ]; then
      echo removing ${DIR_PATH}
      rm -rf ${DIR_PATH}
   fi
}

function check_execute_result( )
{
   local EXECUTE_RESULT=$?

   if [ ${EXECUTE_RESULT} -eq 0 ]; then
      print_ok "Execute OK"
      return 0
   fi

   while [ 1 ]; do
      print_error "Execute error: ${EXECUTE_RESULT}"
      read -p "$( print_question Continue installation [y/N]? )" is_continue
      case ${is_continue} in
         y|Y|yes|Yes|YES)
            echo "continue"
            return 1
         ;;
         n|N|no|No|NO|"")
            echo "interrupt"
            exit ${EXECUTE_RESULT}
         ;;
         * ) echo "Please type 'Y' or 'N'" ;;
      esac
   done
}

function check_is_number( )
{
   if [ $# -lt 1 ]; then return 2; fi

   # links: https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
   local NUMBER_PATTERN='^[0-9]+$'
   #local NUMBER_PATTERN='^[0-9]+([.][0-9]+)?$'
   #local NUMBER_PATTERN='^[+-]?[0-9]+([.][0-9]+)?$'
   local LOCAL_NUMBER="$1"

   if [[ $LOCAL_NUMBER =~ $NUMBER_PATTERN ]] ; then
      return 0
   fi
   return 1
}

function check_root( )
{
   if [ "$(id -u)" != "0" ]; then
      echo "This script must be run as root" 1>&2
      exit 1
   fi
}


# declare -a ARRAY=(0 1 2 3 4 5)
# array_add ARRAY 6
function array_add( )
{
   local -n LOCAL_ARRAY=${1}
   local LOCAL_ELEMENT=${2}

   LOCAL_ARRAY=("${LOCAL_ARRAY[@]}" ${LOCAL_ELEMENT})
}

# declare -a ARRAY=(0 1 2 3 4 5)
# array_remove ARRAY 3
function array_remove( )
{
   local -n LOCAL_ARRAY=${1}
   local LOCAL_ELEMENT=${2}

   for LOCAL_INDEX in ${!LOCAL_ARRAY[@]}; do
      if [ ${LOCAL_ELEMENT} == ${LOCAL_ARRAY[${LOCAL_INDEX}]} ] ; then
         break
      fi
   done
   # echo ${LOCAL_INDEX}

   LOCAL_ARRAY=( "${LOCAL_ARRAY[@]:0:${LOCAL_INDEX}}" "${LOCAL_ARRAY[@]:${LOCAL_INDEX}+1}" )
}

# This function recurcively searches all files in gived directory with given
# extentiones.
# Example:
#  declare -a FILE_LIST=()
#  declare -a EXTENTIONS=( "c" "cpp" "cxx" )
#  find_extentions_in_dir /home EXTENTIONS FILE_LIST
#  echo "FILE_LIST: " ${FILE_LIST[@]}
#  echo "FILE_LIST size: " ${#FILE_LIST[@]}
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


