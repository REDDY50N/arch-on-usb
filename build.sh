#!/bin/bash

###################################################
# Project:   USB Live System - Geshem Flasher 2.0 #
# Author:    S. Reddy (Polar)                     #
# Purpose:   Install arch on USB with pactsrap    #
# Docs:      https://mags.zone/help/arch-usb.html #
###################################################


DEBUG=true
LOG=true
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
# ===============================================
# CHECKS
# ===============================================
# DEBUG OPTIONS:
# -x = trace complete output
# -e = if one command fails ==> stop script
# -u = no undefined/empty variables allowed
# -o pipefail = stop script if piping to another pipe fails
[ $DEBUG == true  ] && set -x && set -eu && set -o pipefail

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


function wipe()
{
  # optional - may take time (1 hour+)
  log "Start wiping ..."
  dd if=/dev/zero of=$TARGET status=progress && sync && log "Wiping done!"
}

function partition()
{
  # create 10MB BIOS, 500MB EFI, remaining space for Linux filesystem (8300) 
  sgdisk -o -n 1:0:+10M -t 1:EF02 -n 2:0:+500M -t 2:EF00 -n 3:0:0 -t 3:8300 $TARGET
  log "Partionining ..."
  #sgdisk -o -n 1:0:+10M -t 1:EF02 -n 2:0:+500M -t 2:EF00 -n 3:0:+3G -t 3:8300 -n 4:0:0 -t 4:8300 $TARGET && log "Partinongning done!"
}

function format()
{
  # Hint: Do not format the /dev/sdX1 block. This is the BIOS/MBR parition."
  
  # Format the 500MB EFI system partition with a FAT32 filesystem:
  mkfs.fat -F32 ${TARGET}2 && log "Creating ${TARGET}2 fs done!"
  
  # Format the Linux partition with an ext4 filesystem:
  mkfs.ext4 ${TARGET}3 && log "Creating ${TARGET}3 fs done!"

  # Format the data partition with an exfat/ntfs filesystem:
  #mkfs.exfat ${TARGET}4 && log "Creating ${TARGET}4 fs done!"
  log "Formating done!"
}

function mounting()
{
  log "Start mounting ..."
  
  if mountpoint -q $BOOT; then umount $BOOT && log "Unmount $BOOT done!"; fi
  if mountpoint -q $MNT; then umount $MNT && log "Unmount $MNT done!"; fi

  # Mount the ext4 formatted partition as the root filesystem:
  mkdir -p "$MNT" && log "Creating mountpoint $MNT done!"
  mount ${TARGET}3 $MNT && log "Mounting ${TARGET}3 on $MNT done!" || error "Mounting ${TARGET}3 on $MNT failed!"

  # Mount the FAT32 formatted EFI partition to /boot:
  mkdir -p "$BOOT" && log "Creating mountpoint $BOOT done!"
  mount ${TARGET}2 $BOOT && log "Mounting ${TARGET}2 on $BOOT done!" || error "Mounting ${TARGET}3 on $BOOT failed!"

  log "Mounting done!"
}

function basesystem()
{
  log "Starting pacstrap to install the base system."
  # Download and install the Arch Linux base packages:
  pacstrap $MNT $PACKAGES
  log "Installing base system done!"
}

function fstabgen()
{
  # Generate a new /etc/fstab using UUIDs as source identifiers:
  genfstab -U /mnt/usb > /mnt/usb/etc/fstab 
  log "Generating fstab done!"
}

function locale_cfg()
{
  echo "All configuration is done within chroot: $CHROOT"

  # locale
cat << EOF | $CHROOT
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
EOF

# Generate /etc/adjtime:
cat << EOF | $CHROOT
hwclock --systohc
EOF

# Edit /etc/locale.gen and uncomment the desired language (for US English, uncomment en_US.UTF-8 UTF-8):
cat << EOF | $CHROOT 
sed -i 's/#de_DE ISO-8859-1/de_DE ISO-8859-1/g' /etc/locale.gen
locale-gen
EOF

# Set the LANG variable in /etc/locale.conf (for US English, localeline is en_US.UTF-8):
cat << EOF | $CHROOT
echo LANG=localeline > /etc/locale.conf
EOF
}

function hostname_cfg()
{
cat << EOF | $CHROOT
echo polar > /etc/hostname
EOF

local PATH=/etc/hosts
cat << EOF | $CHROOT
127.0.0.1  localhost
::1        localhost
127.0.1.1  hostname.localdomain  hostname
EOF
}

function passwd_cfg()
{
  #TODO: check if works!
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
local PATH=/etc/systemd/network/10-ethernet.network

cat << EOF | $CHROOT
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
}


function template()
{
cat << EOF | $CHROOT

EOF
}

# ===========================
# MAIN
# ===========================
partition
format
mounting
basesystem
fstabgen
locale_cfg
hostname_cfg
passwd_cfg
bootloader

