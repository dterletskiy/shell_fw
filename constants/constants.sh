if [ -n "${__SFW_CONSTANTS_CONSTANTS_SH__}" ]; then
   return 0
fi
__SFW_CONSTANTS_CONSTANTS_SH__=1



readonly LOCAL_HOST="127.0.0.1"

# Exit codes
readonly EXIT_STATUS_OK=0
readonly EXIT_STATUS_CANCEL=1
readonly EXIT_STATUS_CONTINUE=0
readonly EXIT_STATUS_BACK=2

# Debugging
readonly DEBUG_ON="set -x"
readonly DEBUG_OFF="set +x"
