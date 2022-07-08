# Make sure virtualization with KVM is available.
function kvm_test( )
{
   grep -c -w "vmx\|svm" /proc/cpuinfo
}
