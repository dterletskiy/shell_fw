# whiptail_yes_no "BACKTITLE" "TITLE" "TEXT" )
# if [[ 0 -eq $? ]]; then
#    echo "YES"
# else
#    echo "NO"
# fi
function whiptail_yes_no( )
{
   local LOCAL_BACKTITLE=${1}
   local LOCAL_TITLE=${2}
   local LOCAL_TEXT=${3}

   whiptail --backtitle "${LOCAL_BACKTITLE}" --title "${LOCAL_TITLE}" --yesno "${LOCAL_TEXT}" --fb 10 60 8 --defaultno 0 0
   return $?
}



# declare -A MAP=( [one]=1 [two]=2 [three]=3 )
# RESULT=$( whiptail_choose_from_map "BACKTITLE" "TITLE" "TEXT" MAP )
function whiptail_choose_from_map( )
{
   local LOCAL_BACKTITLE=${1}
   local LOCAL_TITLE=${2}
   local LOCAL_TEXT=${3}
   local -n LOCAL_MAP=${4}

   local options=()
   for KEY in "${!LOCAL_MAP[@]}"; do
      options+=("${KEY}" " | ${LOCAL_MAP[${KEY}]}")
   done
   local OPTIONS_NUMBER=$(( ${#options[@]}/2 ))

   local CHOICE=$( whiptail \
         --backtitle "${LOCAL_BACKTITLE}" \
         --title "${LOCAL_TITLE}" \
         --menu "${LOCAL_TEXT}" \
         --cancel-button "Cancel" \
         --default-item "${options[0]}" \
         --fb $(( 10 + ${OPTIONS_NUMBER} )) 60 ${OPTIONS_NUMBER} "${options[@]}" 3>&1 1>&2 2>&3 )

   echo ${CHOICE}
}


