readonly K1024=1024
readonly KB=1024
readonly MB=$((KB * KB))
readonly GB=$((MB * KB))

readonly FS_VFAT="vfat"
readonly FS_FAT12="fat12"
readonly FS_FAT16="fat16"
readonly FS_FAT32="fat32"
readonly FS_EXT2="ext2"
readonly FS_EXT3="ext3"
readonly FS_EXT4="ext4"
readonly FS_EXT4_64="ext4_64"
readonly FS_SWAP="swap"
readonly FS_UNDEFINED="undefined"
readonly -A FS_ACTION_MAP=(
      [${FS_VFAT}]="mkfs.vfat"
      [${FS_FAT12}]="mkfs.vfat -F12"
      [${FS_FAT16}]="mkfs.vfat -F16"
      [${FS_FAT32}]="mkfs.vfat -F32"
      [${FS_EXT2}]="mkfs.ext2"
      [${FS_EXT3}]="mkfs.ext3"
      [${FS_EXT4}]="mkfs.ext4"
      [${FS_EXT4_64}]="mkfs.ext4 -O ^64bit"
      [${FS_SWAP}]="swap"
   )



# Usage:
#  build_hdd_map HDD_MAP
function build_hdd_map( )
{
   local -n MAP=$1
   MAP=( )

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
function build_hdd_map_names( )
{
   local -n MAP=$1
   MAP=( )

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
function print_hdd_map( )
{
   local -n MAP=$1

   local DRIVE=""
   for DRIVE in "${!MAP[@]}"; do
      local DRIVE_SIZE=$( get_drive_size_gb ${DRIVE} )
      local PARTITIONS=${MAP[$DRIVE]}
      echo ${DRIVE} "(" ${DRIVE_SIZE} "GB ):"
      for PARTITION in ${PARTITIONS[*]}; do
         local PARTITION_SIZE=$( get_drive_size_gb ${PARTITION} )
         echo "   -" ${PARTITION} "(" ${PARTITION_SIZE} "GB)"
      done
   done
}

# Usage:
#  RESULT=$( get_drive_size_kb /dev/sda1 )
function get_drive_size_kb( )
{
   local DRIVE=$1
   local DRIVE_SIZE=$( sudo fdisk -s $DRIVE )
   # bc <<< "scale=2; $DRIVE_SIZE*1.00"
   echo $DRIVE_SIZE
}

# Usage:
#  RESULT=$( get_drive_size_mb /dev/sda1 )
function get_drive_size_mb( )
{
   local DRIVE=$1
   local DRIVE_SIZE=$( get_drive_size_kb $DRIVE )
   bc <<< "scale=2; $DRIVE_SIZE/($K1024)"
}

# Usage:
#  RESULT=$( get_drive_size_gb /dev/sda1 )
function get_drive_size_gb( )
{
   local DRIVE=$1
   local DRIVE_SIZE=$( get_drive_size_kb $DRIVE )
   bc <<< "scale=2; $DRIVE_SIZE/($K1024*$K1024)"
}

# Usage:
#  RESULT=$( get_partition_format /dev/sda1 )
function get_partition_format( )
{
   local LOCAL_PARTITION=$1
   echo $( sudo blkid -o export ${LOCAL_PARTITION} | grep '^TYPE' | cut -d"=" -f2 )
}

# Usage:
#  RESULT=$( get_partition_label /dev/sda1 )
function get_partition_label( )
{
   local LOCAL_PARTITION=$1
   echo $( sudo blkid -o export ${LOCAL_PARTITION} | grep '^LABEL' | cut -d"=" -f2 )
}

# Usage:
#  RESULT=$( get_partition_label /dev/sda1 )
function get_partition_mount_point( )
{
   local LOCAL_PARTITION=$1
   local LOCAL_UUID=$( sudo blkid -o export ${LOCAL_PARTITION} | grep '^UUID' | cut -d"=" -f2 )
   lsblk -o MOUNTPOINT "/dev/disk/by-uuid/$LOCAL_UUID" | awk 'NR==2'
}

# Usage:
#  RESULT=$( get_drive_type /dev/sda )
function get_drive_type( )
{
   local LOCAL_DRIVE=$1
   echo $( sudo blkid -o export ${LOCAL_DRIVE} | grep '^PTTYPE' | cut -d"=" -f2 )
}

# Usage:
#  format_partition /dev/sda1 ${FS_EXT4} "root"
#  echo $?
function format_partition( )
{
   if [ $# -lt 2 ]; then
      print_error "There must be at least 2 arguments"
      return 1;
   fi

   local PARTITION=${1}
   local FORMAT=${2}
   local LABEL=${3}
   if [ -z ${LABEL} ]; then
      LABEL=$( get_partition_label ${PARTITION} );
   fi

   # Unmount if already mounted
   local MOUNT_POINT=$( get_partition_mount_point ${PARTITION} )
   if [[ -n ${MOUNT_POINT} ]]; then
      print_warning "Partition \'${PARTITION}\' mounted to \'${MOUNT_POINT}\' => unmount"
      umount ${PARTITION}
   fi

   # ${FS_ACTION_MAP[${FORMAT}]} ${PARTITION} -L ${LABEL}

   if [ ${FS_VFAT} == ${FORMAT} ]; then
      print_info "Formatting to vfat..."
      mkfs.vfat ${PARTITION} -n ${LABEL}
   elif [ ${FS_FAT12} == ${FORMAT} ]; then
      print_info "Formatting to fat12..."
      mkfs.vfat -F12 ${PARTITION} -n ${LABEL}
   elif [ ${FS_FAT16} == ${FORMAT} ]; then
      print_info "Formatting to fat16..."
      mkfs.vfat -F16 ${PARTITION} -n ${LABEL}
   elif [ ${FS_FAT32} == ${FORMAT} ]; then
      print_info "Formatting to fat32..."
      mkfs.vfat -F32 ${PARTITION} -n ${LABEL}
   elif [ ${FS_EXT2} == ${FORMAT} ]; then
      print_info "Formatting to ext2..."
      mkfs.ext2 ${PARTITION} -L ${LABEL}
   elif [ ${FS_EXT3} == ${FORMAT} ]; then
      print_info "Formatting to ext3..."
      mkfs.ext3 ${PARTITION} -L ${LABEL}
   elif [ ${FS_EXT4} == ${FORMAT} ]; then
      print_info "Formatting to ext4..."
      mkfs.ext4 ${PARTITION} -L ${LABEL}
   elif [ ${FS_EXT4_64} == ${FORMAT} ]; then
      print_info "Formatting to ext4 64bit..."
      mkfs.ext4 -O ^64bit ${PARTITION} -L ${LABEL}
   elif [ ${FS_SWAP} == ${FORMAT} ]; then
      print_info "Formatting to swap..."
      mkswap ${PARTITION} -L ${LABEL}
   fi

   return $?
}

# Usage:
#  mount_partition <file> <mount_point>
#  echo $?
function mount_partition( )
{
   if [ $# -lt 2 ]; then
      print_error "There must be at least 2 arguments"
      return 1;
   fi

   local PARTITION=${1}
   local MOUNT_POINT=${2}

   # Unmount if already mounted
   local PRE_MOUNT_POINT=$( get_partition_mount_point ${PARTITION} )
   if [[ -n ${PRE_MOUNT_POINT} ]]; then
      print_warning "Partition \'${PARTITION}\' mounted to \'${PRE_MOUNT_POINT}\' => unmount"
      sudo umount ${PARTITION}
      if [ $? -ne 0 ]; then return $?; fi
   fi

   # Check if mount point directory exists and create if not
   if [ ! -d ${MOUNT_POINT} ]; then
      mkdir -p ${MOUNT_POINT}
      if [ $? -ne 0 ]; then
         print_error "Can't create mount point directory: \'${MOUNT_POINT}\'"
         return $?;
      fi
   fi

   # Mount partition
   sudo mount ${PARTITION} ${MOUNT_POINT}
   if [ $? -ne 0 ]; then
      print_error "Can't mount \'${PARTITION}\' to \'${MOUNT_POINT}\'"
      return $?
   fi

   return 0;
}

# Usage:
#  umount_partition <mount_point>
#  or
#  umount_partition <file>
#  echo $?
function umount_partition( )
{
   if [ $# -lt 1 ]; then
      print_error "There must be at least 1 arguments"
      return 1;
   fi

   local MOUNT_POINT=${1}

   if [[ -n ${MOUNT_POINT} ]]; then
      sudo umount ${MOUNT_POINT}
      if [ $? -ne 0 ]; then
         print_error "Can't umount \'${MOUNT_POINT}\'"
      fi
   fi

   return $?
}


# Usage:
#  create_partition_image ~/partition.img 1024 ${FS_EXT4} "kernel"
#  echo $?
function create_partition_image( )
{
   local FILE=${1}
   local SIZE=${2}
   local FS=${3}
   local LABEL=${4}

   dd if=/dev/zero of=${FILE} bs=${MB} count=${SIZE}
   if [ $? -ne 0 ]; then
      print_error "Can't create file \'${FILE}\' with size \'${SIZE}\'MB"
      return $?
   fi

   format_partition ${FILE} ${FS} ${LABEL}

   return 0
}

function create_drive_image( )
{
   return 0
}
