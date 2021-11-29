function ssh_command( )
{
   local IP=${1}
   shift 1
   local COMMAND=("$@")

   if [ ${LOCAL_HOST} = ${IP} ]; then
      eval ${COMMAND[*]}
   else
      # ssh -q root@$@
      ssh -q -o 'IPQoS=throughput' root@${IP} ${COMMAND[*]}
   fi
}

function ssh_command_ex( )
{
   local IP=${1}
   local PORT=${2}
   shift 2
   local COMMAND=("$@")

   if [ ${LOCAL_HOST} = ${IP} ]; then
      eval ${COMMAND[*]}
   else
      # ssh -q root@$@
      ssh -q -o 'IPQoS=throughput' -p ${PORT} root@${IP} ${COMMAND[*]}
   fi
}

function check_connection( )
{
   local IP=${1}
   ssh_command_ex ${IP} 22 exit
   if [ "$?" != "0" ]; then
      print_error ${IP} offline
      exit
   else
      print_ok ${IP} online
   fi
}

function calculate_md5( )
{
   local IP=${1}
   local FILE_PATH=${2}

   local MD5_RESULT=( )

   if ssh_command ${IP} stat ${FILE_PATH} \> /dev/null 2\>\&1; then
      local RESULT=`ssh_command ${IP} md5sum ${FILE_PATH}`
      MD5_RESULT=(${RESULT})
   fi

   echo ${MD5_RESULT[0]}
}

function calculate_md5_ex( )
{
   local IP=${1}
   local PORT=${2}
   local FILE_PATH=${3}

   local MD5_RESULT=( )

   if ssh_command_ex ${IP} ${PORT} stat ${FILE_PATH} \> /dev/null 2\>\&1; then
      local RESULT=`ssh_command_ex ${IP} ${PORT} md5sum ${FILE_PATH}`
      MD5_RESULT=(${RESULT})
   fi

   echo ${MD5_RESULT[0]}
}
