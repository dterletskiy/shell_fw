if [ -n "${__SFW_VIRTUALIZATION_SH__}" ]; then
   return 0
fi
__SFW_VIRTUALIZATION_SH__=1



# Make sure virtualization with KVM is available.
function kvm_test( )
{
   grep -c -w "vmx\|svm" /proc/cpuinfo
}
