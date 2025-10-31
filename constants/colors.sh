[ -n "${__SFW_CONSTANTS_COLORS_SH__}" ] && return 0 || readonly __SFW_CONSTANTS_COLORS_SH__=1



readonly ECHO_PREFIX="\e["
###############
# Formatting
###############
readonly ECHO_FORMAT_Bold=$ECHO_PREFIX"1m"
readonly ECHO_FORMAT_Dim=$ECHO_PREFIX"2m"
readonly ECHO_FORMAT_Underlined=$ECHO_PREFIX"4m"
readonly ECHO_FORMAT_Blink=$ECHO_PREFIX"5m"
# invert the foreground and background colors
readonly ECHO_FORMAT_Reverse=$ECHO_PREFIX"7m"
# useful for passwords
readonly ECHO_FORMAT_Hidden=$ECHO_PREFIX"8m"
readonly ECHO_FORMAT_Reset=$ECHO_PREFIX"0m"
###############
# 8/16 Colors
# Foreground (text)
###############
readonly ECHO_FG_Default=$ECHO_PREFIX"39m"
readonly ECHO_FG_Black=$ECHO_PREFIX"30m"
readonly ECHO_FG_Red=$ECHO_PREFIX"31m"
readonly ECHO_FG_Green=$ECHO_PREFIX"32m"
readonly ECHO_FG_Yellow=$ECHO_PREFIX"33m"
readonly ECHO_FG_Blue=$ECHO_PREFIX"34m"
readonly ECHO_FG_Magenta=$ECHO_PREFIX"35m"
readonly ECHO_FG_Cyan=$ECHO_PREFIX"36m"
readonly ECHO_FG_LightGray=$ECHO_PREFIX"37m"
readonly ECHO_FG_DarkGray=$ECHO_PREFIX"90m"
readonly ECHO_FG_LightRed=$ECHO_PREFIX"91m"
readonly ECHO_FG_LightGreen=$ECHO_PREFIX"92m"
readonly ECHO_FG_LightYellow=$ECHO_PREFIX"93m"
readonly ECHO_FG_LightBlue=$ECHO_PREFIX"94m"
readonly ECHO_FG_LightMagenta=$ECHO_PREFIX"95m"
readonly ECHO_FG_LightCyan=$ECHO_PREFIX"96m"
readonly ECHO_FG_White=$ECHO_PREFIX"97m"
###############
# 8/16 Colors
# Background (text)
###############
readonly ECHO_BG_Default=$ECHO_PREFIX"49m"
readonly ECHO_BG_Black=$ECHO_PREFIX"40m"
readonly ECHO_BG_Red=$ECHO_PREFIX"41m"
readonly ECHO_BG_Green=$ECHO_PREFIX"42m"
readonly ECHO_BG_Yellow=$ECHO_PREFIX"43m"
readonly ECHO_BG_Blue=$ECHO_PREFIX"44m"
readonly ECHO_BG_Magenta=$ECHO_PREFIX"45m"
readonly ECHO_BG_Cyan=$ECHO_PREFIX"46m"
readonly ECHO_BG_LightGray=$ECHO_PREFIX"47m"
readonly ECHO_BG_DarkGray=$ECHO_PREFIX"100m"
readonly ECHO_BG_LightRed=$ECHO_PREFIX"101m"
readonly ECHO_BG_LightGreen=$ECHO_PREFIX"102m"
readonly ECHO_BG_LightYellow=$ECHO_PREFIX"103m"
readonly ECHO_BG_LightBlue=$ECHO_PREFIX"104m"
readonly ECHO_BG_LightMagenta=$ECHO_PREFIX"105m"
readonly ECHO_BG_LightCyan=$ECHO_PREFIX"106m"
readonly ECHO_BG_White=$ECHO_PREFIX"107m"



readonly ECHO_RESET=${ECHO_BG_Default}${ECHO_FG_Default}${ECHO_FORMAT_Reset}
