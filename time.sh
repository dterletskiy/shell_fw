[ -n "${__SFW_TIME_SH__}" ] && return 0 || readonly __SFW_TIME_SH__=1



function timestamp( )
{
   echo "$(date +'%Y.%m.%d_%H.%M.%S.%3N')"
}
