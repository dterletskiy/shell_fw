[ -n "${__SFW_DEVICE_TREE_SH__}" ] && return 0 || readonly __SFW_DEVICE_TREE_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/print.sh"



function dt_compile( )
{
   local IN_DTS=${1}
   local OUT_DTB=${2}

   local COMMAND="dtc -I dts -O dtb -o ${OUT_DTB} ${IN_DTS}"
   execute "${COMMAND}"
   return $?
}

function dt_decompile( )
{
   local IN_DTB=${1}
   local OUT_DTS=${2}

   local COMMAND="dtc -I dtb -O dts -o ${OUT_DTS} ${IN_DTB}"
   execute "${COMMAND}"
   return $?
}
