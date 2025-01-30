if [ -n "${__SFW_GIT_SH__}" ]; then
   return 0
fi
__SFW_GIT_SH__=1



USER=
EMAIL=
URL=

SOURCE_DIR=${PWD}



function setup( )
{
   if [[ $# -lt 2 ]]; then
      echo "Pass at least two parameters:"
      echo "   - user name (essential)"
      echo "   - e-mail address (essential)"
      echo "   - global/local (optional) (global by default)"

      echo "Current:"
      echo "   global:"
      echo "      user:    $( git config --global user.name )"
      echo "      e-mail:  $( git config --global user.email )"
      echo "   local:"
      echo "      user:    $( git config user.name )"
      echo "      e-mail:  $( git config user.email )"
      return 255
   fi

   local LOCAL_USER=${1}
   local LOCAL_EMAIL=${2}
   local LOCAL_TYPE="--global"

   if [[ ${3} == "local" ]]; then
      LOCAL_TYPE=""
   fi


   echo "user name:  ${LOCAL_USER}"
   echo "e-mail:     ${LOCAL_EMAIL}"
   echo "type:       ${LOCAL_TYPE}"

   git config ${LOCAL_TYPE} user.name ${1}
   git config ${LOCAL_TYPE} user.email ${2}

   return 0
}

function clone( )
{
   local LOCAL_URL=${1}
   local LOCAL_SOURCE_DIR=${PWD}

   if [[ -z ${2+x} ]]; then
      echo "Destination directory is unset => current one '${LOCAL_SOURCE_DIR}' will be used"
   else
      if [[ ! -d ${2} ]]; then
         echo "Destination directory '${2}' does not exist and will be created"
         mkdir -p ${2}
         if [[ 0 -ne ${?} ]]; then
            echo "Destination directory '${2}' does not exist and can't be created"
            return 254
         fi
         echo "Destination directory '${2}' exists"
      fi
      LOCAL_SOURCE_DIR=${2}
   fi

   git clone ${LOCAL_URL} ${LOCAL_SOURCE_DIR}
}



function __git_example__( )
{
   setup ${USER} ${EMAIL}
   setup
   clone ${URL}
}
