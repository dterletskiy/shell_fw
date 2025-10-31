[ -n "${__SFW_ARRAY_SH__}" ] && return 0 || readonly __SFW_ARRAY_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"



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

function array_find( )
{
   local -n LOCAL_LIST=${1}
   local LOCAL_ITEM=${2}

   for __ITEM__ in "${LOCAL_LIST[@]}"; do
      if [ "${__ITEM__}" == "${LOCAL_ITEM}" ]; then
         return 1
      fi
   done

   return 0
}

function map_find_key( )
{
   local -n LOCAL_MAP=${1}
   local LOCAL_KEY=${2}


   for __KEY__ in "${!LOCAL_MAP[@]}"; do
      if [ "${__KEY__}" == "${LOCAL_KEY}" ]; then
         return 1
      fi
   done

   return 0
}

function map_find_value( )
{
   local -n LOCAL_MAP=${1}
   local LOCAL_VALUE=${2}

   for __KEY__ in "${!LOCAL_MAP[@]}"; do
      if [ "${LOCAL_MAP[${__KEY__}]}" == "${LOCAL_VALUE}" ]; then
         return 1
      fi
   done

   return 0
}

function map_find_key_value( )
{
   local -n LOCAL_MAP=${1}
   local LOCAL_KEY=${2}


   for __KEY__ in "${!LOCAL_MAP[@]}"; do
      if [ "${__KEY__}" == "${LOCAL_KEY}" ]; then
         if [ "${LOCAL_MAP[${__KEY__}]}" == "${LOCAL_VALUE}" ]; then
            return 1
         fi
         return 0
      fi
   done

   return 0
}
