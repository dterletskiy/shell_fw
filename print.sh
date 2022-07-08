function action_begin( )
{
   local LOCAL_MESSAGE=$@
   echo -e ${ECHO_HEADER}
   echo "/***********************"
   echo " * ${LOCAL_MESSAGE}"
   echo " **********************/"
   echo -e ${ECHO_RESET}
   #press_any_key
}
function action_end( )
{
   echo ""
   #press_any_key
}

function print( )
{
   local LOCAL_FORMAT=$1
   local LOCAL_MESSAGE=("${!2}")
   echo -e ${LOCAL_FORMAT}${LOCAL_MESSAGE[@]}${ECHO_RESET}
}

function print_and_run( )
{
   echo ${1}
   time eval ${1}
}


function print_header( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_HEADER} LOCAL_MESSAGE[@]
}
function print_info( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_INFO} LOCAL_MESSAGE[@]
}
function print_ok( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_OK} LOCAL_MESSAGE[@]
}
function print_error( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_ERROR} LOCAL_MESSAGE[@]
}
function print_warning( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_WARNING} LOCAL_MESSAGE[@]
}

function print_question( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_QUESTION} LOCAL_MESSAGE[@]
}

function print_promt( )
{
   local LOCAL_MESSAGE=$@
   print  ${ECHO_PROMT} LOCAL_MESSAGE[@]
}

# LIST=( "A" "B" "C" )
# print_list "${LIST[@]}" "OPTIONAL_NAME"
function print_list( )
{
   local LOCAL_LIST=("$@")
   local NAME="list"

   if [ -z ${2+x} ]; then
      NAME="list"
   else
      NAME=$2
   fi

   echo "${NAME} [${#LOCAL_ARRAY[@]}]"
   echo "{"
   for LOCAL_ITEM in ${LOCAL_LIST[*]} ; do
      echo "   ${LOCAL_ITEM}"
   done
   echo "}"
}

# This function do the same and 'print_list' but should be called similar to 'print_map'
# ARRAY=( "A" "B" "C" )
# print_array ARRAY "OPTIONAL_NAME"
function print_array( )
{
   local -n LOCAL_ARRAY=${1}
   local NAME="array"

   if [ -z ${2+x} ]; then
      NAME="array"
   else
      NAME=$2
   fi

   echo "${NAME} [${#LOCAL_ARRAY[@]}]"
   echo "{"
   for LOCAL_ITEM in "${LOCAL_ARRAY[@]}"; do
      echo "   ${LOCAL_ITEM}"
   done
   echo "}"
   # print_list "${LOCAL_ARRAY[@]}"
}

# declare -A MAP=( [one]=111 [two]=222 [three]=333 )
# print_map MAP "OPTIONAL_NAME"
function print_map( )
{
   local -n LOCAL_MAP=$1
   local NAME="map"

   if [ -z ${2+x} ]; then
      NAME="map"
   else
      NAME=$2
   fi

   echo "${NAME} [${#LOCAL_MAP[@]}]"
   echo "{"
   for KEY in "${!LOCAL_MAP[@]}"; do
      echo "   { ${KEY} -> ${LOCAL_MAP[${KEY}]} }"
   done
   echo "}"
}
