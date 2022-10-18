#!/bin/bash

# Simple helper script to mount and enter chroot
# to test if everthing in build.sh was done correctly.

TARGET=$1
MNT="/mnt/usb"
BOOT="/mnt/usb/boot"
CHROOT="arch-chroot /mnt/usb"

# root check 
[ $(whoami) != root ] && echo "You must be root!" && exit 1

# terget empty check
[ -z $TARGET ] && echo "You must specify a target. Determine the target USB device name with lsblk first!" && exit 1

function mounting()
{
  if 
    mountpoint -q $MNT; then 
      echo "Mountpoint $MNT exists!" 
  else
    # Mount the ext4 formatted partition as the root filesystem:
    mkdir -p "$MNT" && echo "Creating mountpoint $MNT done!"
    mount ${TARGET}3 $MNT && echo "Mounting ${TARGET}3 on $MNT done!" || echo "Mounting ${TARGET}3 on $MNT  failed!" && exit 1
  fi

  # Mount the FAT32 formatted EFI partition to /boot:
  #mkdir -p "$BOOT" && log "Creating mountpoint $BOOT done!"
  #mount ${TARGET}2 $BOOT && log "Mounting ${TARGET}2 on $BOOT done!" || error "Mounting ${TARGET}3 on $BO │ OT failed!"
}
 
function enter_chroot()
{
  arch-chroot $MNT
}


### MAIN ###
mounting
enter_chroot

