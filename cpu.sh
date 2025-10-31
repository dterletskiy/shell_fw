[ -n "${__SFW_CPU_SH__}" ] && return 0 || readonly __SFW_CPU_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



function get_cpus_number( )
{
   if command -v nproc &>/dev/null; then
      cores=$(nproc)
   elif command -v getconf &>/dev/null; then
      cores=$(getconf _NPROCESSORS_ONLN)
   else
      cores=1  # fallback
   fi

   echo ${cores}
}

# Make sure virtualization with KVM is available.
function kvm_test( )
{
   grep -c -w "vmx\|svm" /proc/cpuinfo
}
