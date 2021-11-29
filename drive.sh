readonly K1024=1024
readonly KB=1024
readonly MB=$KB*$KB
readonly GB=$MB*$KB



# Usage:
#  build_hdd_map HDD_MAP
function build_hdd_map()
{
   local -n MAP=$1
   MAP=()

   local DRIVES=""
   local DRIVE=""
   local PARTITIONS=""

   mapfile -t DRIVES <<< $( ls /dev | grep -e "^sd[a-z]$" | sort -n -k3 )
   # echo "${DRIVES[*]}"
   for DRIVE in ${DRIVES[*]}; do
      mapfile -t PARTITIONS <<< $( find /dev -name "$DRIVE[0-9]" | sort -n -k3 )
      MAP["/dev/"${DRIVE}]=${PARTITIONS[*]}
      # echo "/dev/${DRIVE}: ${PARTITIONS[*]}"
   done
}

# Usage:
#  build_hdd_map_names HDD_MAP
function build_hdd_map_names()
{
   local -n MAP=$1
   MAP=()

   local DRIVES=""
   local DRIVE=""
   local PARTITIONS=""

   mapfile -t DRIVES <<< $( ls /dev | grep -e "^sd[a-z]$" | sort -n -k3 )
   echo "${DRIVES[*]}"
   for DRIVE in ${DRIVES[*]}; do
      mapfile -t PARTITIONS <<< $( ls /dev | grep -e "^$DRIVE[0-9]$" | sort -n -k3 )
      MAP[${DRIVE}]=${PARTITIONS[*]}
      echo "${PARTITIONS[*]}"
   done
}

# Usage:
#  print_hdd_map HDD_MAP
function print_hdd_map()
{
   local -n MAP=$1

   local DRIVE=""
   for DRIVE in "${!MAP[@]}"; do
      local DRIVE_SIZE=$( get_drive_size_gb $DRIVE )
      local PARTITIONS=${MAP[$DRIVE]}
      echo $DRIVE "(" $DRIVE_SIZE "GB ):"
      for PARTITION in ${PARTITIONS[*]}; do
         local PARTITION_SIZE=$( get_drive_size_gb $PARTITION )
         echo "   -" $PARTITION "(" $PARTITION_SIZE "GB)"
      done
   done
}

# Usage:
#  RESULT=$( get_drive_size_kb /dev/sda1 )
function get_drive_size_kb()
{
   local DRIVE=$1
   local DRIVE_SIZE=$( sudo fdisk -s $DRIVE )
   # bc <<< "scale=2; $DRIVE_SIZE*1.00"
   echo $DRIVE_SIZE
}

# Usage:
#  RESULT=$( get_drive_size_mb /dev/sda1 )
function get_drive_size_mb()
{
   local DRIVE=$1
   local DRIVE_SIZE=$( get_drive_size_kb $DRIVE )
   bc <<< "scale=2; $DRIVE_SIZE/($K1024)"
}

# Usage:
#  RESULT=$( get_drive_size_gb /dev/sda1 )
function get_drive_size_gb()
{
   local DRIVE=$1
   local DRIVE_SIZE=$( get_drive_size_kb $DRIVE )
   bc <<< "scale=2; $DRIVE_SIZE/($K1024*$K1024)"
}

# Usage:
#  RESULT=$( get_partition_format /dev/sda1 )
function get_partition_format()
{
   local LOCAL_PARTITION=$1
   echo $( sudo blkid -o export ${LOCAL_PARTITION} | grep '^TYPE' | cut -d"=" -f2 )
}

# Usage:
#  RESULT=$( get_partition_label /dev/sda1 )
function get_partition_label()
{
   local LOCAL_PARTITION=$1
   echo $( sudo blkid -o export ${LOCAL_PARTITION} | grep '^LABEL' | cut -d"=" -f2 )
}

# Usage:
#  RESULT=$( get_partition_label /dev/sda1 )
function get_partition_mount_point()
{
   local LOCAL_PARTITION=$1
   local LOCAL_UUID=$( sudo blkid -o export ${LOCAL_PARTITION} | grep '^UUID' | cut -d"=" -f2 )
   lsblk -o MOUNTPOINT "/dev/disk/by-uuid/$LOCAL_UUID" | awk 'NR==2'
}

# Usage:
#  RESULT=$( get_drive_type /dev/sda )
function get_drive_type()
{
   local LOCAL_DRIVE=$1
   echo $( sudo blkid -o export ${LOCAL_DRIVE} | grep '^PTTYPE' | cut -d"=" -f2 )
}

# Usage:
#  format_partition /dev/sda1 ${TYPE_EXT4} "root"
#  echo $?
readonly TYPE_VFAT="vfat"
readonly TYPE_EXT2="ext2"
readonly TYPE_EXT3="ext3"
readonly TYPE_EXT4="ext4"
readonly TYPE_SWAP="swap"
readonly TYPE_UNDEFINED="undefined"
readonly -A FS_ACTION_MAP=(
      [${TYPE_VFAT}]="mkfs.vfat"
      [${TYPE_EXT2}]="mkfs.ext2"
      [${TYPE_EXT3}]="mkfs.ext3"
      [${TYPE_EXT4}]="mkfs.ext4"
      [${TYPE_SWAP}]="swap"
   )
format_partition()
{
   if [ $# -lt 2 ]; then return 1; fi

   local PARTITION=$1
   local FORMAT=$2
   local LABEL=$3
   if [ -z ${LABEL} ]; then LABEL=$( get_partition_label ${PARTITION} ); fi

   # Unmount if already mounted
   if [[ -n $( get_partition_mount_point ${PARTITION} ) ]]; then
      umount ${PARTITION}
   fi

   # ${FS_ACTION_MAP[${FORMAT}]} ${PARTITION} -L ${LABEL}
   return $?

   # case ${FORMAT} in
   #    ${TYPE_VFAT} )
   #          mkfs.vfat ${PARTITION} -L ${LABEL}
   #          if [ $? -ne 0 ]; then return $?; fi
   #       ;;
   #    ${TYPE_EXT2} )
   #          mkfs.ext2 ${PARTITION} -L ${LABEL}
   #          if [ $? -ne 0 ]; then return $?; fi
   #       ;;
   #    ${TYPE_EXT3} )
   #          mkfs.ext3 ${PARTITION} -L ${LABEL}
   #          if [ $? -ne 0 ]; then return $?; fi
   #       ;;
   #    ${TYPE_EXT4} )
   #          mkfs.ext4 ${PARTITION} -L ${LABEL}
   #          if [ $? -ne 0 ]; then return $?; fi
   #       ;;
   #    ${TYPE_SWAP} )
   #          mkswap ${PARTITION} -L ${LABEL}
   #          if [ $? -ne 0 ]; then return $?; fi
   #       ;;
   #    * ) return 2 ;;
   # esac
   # return 0
}

# Usage:
#  mount_partition /dev/sda1 /boot
#  echo $?
function mount_partition()
{
   if [ $# -lt 2 ]; then return 1; fi

   local PARTITION=$1
   local MOUNT_POINT=$2

   # Unmount if already mounted
   if [[ -n $( get_partition_mount_point ${PARTITION} ) ]]; then
      umount ${PARTITION}
      if [ $? -ne 0 ]; then return $?; fi
   fi

   # Check if mount point directory exists and create if not
   if [ ! -d ${MOUNT_POINT} ]; then
      mkdir -p ${MOUNT_POINT}
      if [ $? -ne 0 ]; then return $?; fi
   fi

   # Mount partition
   mount ${PARTITION} ${MOUNT_POINT}
   if [ $? -ne 0 ]; then return $?; fi

   return 0;
}




# BLOCK_SIZE=$(stat -f --format="%S" /dev/sda)
# BLOCKS=$(stat -f --format="%b" /dev/sda)
# SIZE=$(( ${BLOCK_SIZE}*${BLOCKS} ))
# echo $SIZE
