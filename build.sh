#!/bin/bash

#=================================================#
# USB Live System - Geshem Flasher 2.0            #
#=================================================#
# Author:    S. Reddy (Polar)                     #
#=================================================#
# Purpose:   Install arch on USB with pactsrap    #
# Docs:      https://mags.zone/help/arch-usb.html #
#=================================================#

DEBUG=false
LOG=true
HELPER=false
LOGFILE=$PWD/build.log

# ===============================================
# VARIABLES
# ===============================================
#TARGET=/dev/sdc
TARGET=$1
MNT="/mnt/usb"
BOOT="/mnt/usb/boot"
CHROOT="arch-chroot /mnt/usb"
PACKAGES="linux linux-firmware base vim"
HOSTNAME=flasher

# ===============================================
# CHECKS
# ===============================================
# DEBUG OPTIONS:
# -x = trace complete output
# -e = if one command fails ==> stop script
# -u = no undefined/empty variables allowed
# -o pipefail = stop script if piping to another pipe fails
[ $DEBUG  == true ] && set -x 
[ $HELPER == true ] && set -eu && set -o pipefail

# root check 
[ $(whoami) != root ] && echo "You must be root!" && exit 1

# check if target is passed as argument
[ -z $TARGET ] && echo "You must specify a target. Determine the target USB device name with lsblk first!" && exit 1

# ===============================================
# FUNCTIONS
# ===============================================
function log()
{
    echo "$1"
    [ $LOG == true ] && echo "$1" >> $LOGFILE
}

function error()
{
    echo "$1"
    [ $LOG == true ] && echo "$1" >> $LOGFILE
    exit 1
}


function fullwipe()
{
  # optional - may take time (1 hour+)
  log "Start wiping ..."
  #dd if=/dev/zero of=$TARGET status=progress && sync && log "Wiping done!"
  dd if=/dev/zero of=$TARGET bs=16M status=progress && sync && log "==> Wiping done!"
}

function fastwipe()
{
  log "Start fast wiping ..."
  sgdisk -o -n 1:0:0 -t 1:8300 $TARGET
  mkfs.ext4 $TARGET && log "==> Wiping done!"
}

function partition()
{
  log "Partionining ..."
  
  log "Create 10MB BIOS, 500MB EFI, remaining space for Linux filesystem (8300)" 
  sgdisk -o -n 1:0:+10M -t 1:EF02 -n 2:0:+500M -t 2:EF00 -n 3:0:0 -t 3:8300 $TARGET

  #log "Create 10MB BIOS, 500MB EFI, 3GB for Linux fs and remaining space for image files" 
  sgdisk -o -n 1:0:+10M -t 1:EF02 -n 2:0:+500M -t 2:EF00 -n 3:0:+3G -t 3:8300 -n 4:0:0 -t 4:8300 $TARGET && log "Partioning done!"
}

function format()
{
  # Hint: Do not format the /dev/sdX1 block. This is the BIOS/MBR parition."
  
  # Format the 500MB EFI system partition with a FAT32 filesystem:
  mkfs.fat -F32 ${TARGET}2 && log "Creating ${TARGET}2 fs done!"
  
  # Format the Linux partition with an ext4 filesystem:
  mkfs.ext4 ${TARGET}3 && log "Creating ${TARGET}3 fs done!"

  # Format the data partition with an exfat/ntfs filesystem:
  mkfs.ext4 ${TARGET}4 && log "Creating ${TARGET}4 fs done!"
  
  log "==> Formating done!"
}

function unmounting()
{
  log "==> Unmount first ..."

  if mountpoint -q $BOOT; then
    log "==> $BOOT is still mounted!"
    umount $BOOT && log "Unmount $BOOT sucessfull!" || error "Failed to unmount $BOOT" 
  fi
  
  if mountpoint -q $MNT; then
    log "==> $MNT is still mounted!"
    umount $MNT && log "Unmount $MNT successful!" || error "Failed to unmount $MNT"
  fi

  log "==> Unmounting done!"
}

function mounting()
{
  log "==> Start mounting ..."
  
  log "==> Mount the ext4 formatted partition as the root filesystem"
  mkdir -p "$MNT" && log "Creating mountpoint $MNT done!"
  mount ${TARGET}3 $MNT && log "Mounting ${TARGET}3 on $MNT done!" || error "Mounting ${TARGET}3 on $MNT failed!"

  log "==> Mount the FAT32 formatted EFI partition to /boot"
  mkdir -p "$BOOT" && log "Creating mountpoint $BOOT done!"
  mount ${TARGET}2 $BOOT && log "Mounting ${TARGET}2 on $BOOT done!" || error "Mounting ${TARGET}3 on $BOOT failed! ==> Hint: Reboot if mount fails due to unknow filesystem type »vfat«!"

  log "==> Mounting done!"
}

function basesystem()
{
  log "==> Download and install the Arch Linux base packages using pacstrap."
  pacstrap $MNT $PACKAGES
  log "==> Installing base system done!"
}

function fstabgen()
{
  log "==> Generate a new /etc/fstab using UUIDs as source identifiers"
  genfstab -U /mnt/usb > /mnt/usb/etc/fstab 
  log "==> Generating fstab done!"
}

#================ CONFIGURE ===================#

function locale_cfg()
{
log "==> Set timezone"
cat << EOF | $CHROOT
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
EOF

log "==> Generate /etc/adjtime (hwclock)"
cat << EOF | $CHROOT
hwclock --systohc
EOF

# Edit /etc/locale.gen and uncomment the desired language (for US English, uncomment en_US.UTF-8 UTF-8):
cat << EOF | $CHROOT 
sed -i 's/#de_DE ISO-8859-1/de_DE ISO-8859-1/g' /etc/locale.gen
locale-gen
EOF

log "Set the LANG variable in /etc/locale.conf to de_DE.UTF-8" 
cat << EOF | $CHROOT
echo LANG=de_DE.UTF-8 > /etc/locale.conf
EOF
}

function hostname_cfg()
{
  locale HOSTNAME=gflash
log "==> Change hostname to ${HOSTNAME}"  
cat << EOF | $CHROOT
echo ${HOSTNAME} > /etc/hostname
EOF

  local PATH=/etc/hosts
  #TODO: failed due to path!
cat << EOF | "${CHROOT}/${PATH}"
127.0.0.1  localhost
::1        localhost
127.0.1.1  ${HOSTNAME}.localdomain  ${HOSTNAME}
EOF
}

function setrootpw()
{
  #TODO: check if works!
  log "==> Set root password!"
cat << EOF | $CHROOT
passwd -q "evis32"
EOF
}

function bootloader()
{
cat << EOF | $CHROOT
#Install grub and efibootmgr:
pacman -S grub efibootmgr

#Install GRUB for both BIOS and UEFI booting modes:
grub-install --target=i386-pc --recheck ${TARGET}
grub-install --target=x86_64-efi --efi-directory /boot --recheck --removable

#Generate a GRUB configuration:
grub-mkconfig -o /boot/grub/grub.cfg   
EOF
}

function networking()
{
log "Create network configuration file for automatically establish wired connections"
local PATH=/etc/systemd/network/10-ethernet.network

#TODO: failed due to path!
log "PATH: ${CHROOT}/${PATH} or '${CHROOT}/${PATH}'"
cat << EOF | "${CHROOT}/${PATH}"
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes

[DHCPv4]
RouteMetric=10

[IPv6AcceptRA]
RouteMetric=10
EOF

# HINT: you can add wireless config here:
# https://mags.zone/help/arch-usb.html

log "==> Enable networking"
cat << EOF | $CHROOT
systemctl enable systemd-networkd.service
EOF

log "==> Enable resolved and create link to /run/systmed/resolve/stub-resolv.conf"
cat << EOF | $CHROOT
systemctl enable systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 
EOF

log "==> Enable timesyncd"
cat << EOF | $CHROOT
systemctl enable systemd-timesyncd.service
EOF
}



function setuser()
{
  log "==> Set username and password."
cat << EOF | $CHROOT
useradd -m polar
passwd polar
EOF
}

function addwheelgrp()
{
  log "==> Ensure the wheel group exists and add user to it."
cat << EOF | $CHROOT
groupadd wheel
usermod -aG wheel user
EOF
}


function sudocfg()
{
  log "==> Configure sudo"
cat << EOF | $CHROOT
pacman -S sudo
EOF

local PATH=/etc/sudoers.d/10-sudo
#TODO: failed due to path!
cat << EOF | ${CHROOT}/${PATH}
%sudo ALL=(ALL) ALL
EOF

cat << EOF | $CHROOT
groupadd sudo
usermod -aG sudo user
pacman -S polkit 
EOF
}

### TODO: optional steps, journal

function template()
{
cat << EOF | $CHROOT

EOF
}

# ===========================
# MAIN
# ===========================
log ""
log "Starting build $(date +"%D %T")"
### prepare
unmounting
#fullwipe
partition
format
mounting

### base system
basesystem
fstabgen

### config
locale_cfg
hostname_cfg
setrootpw
bootloader
networking

setuser
addwheelgrp
#sudocfg

