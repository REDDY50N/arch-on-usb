#!/bin/bash

#=================================================#
# USB Live System - Geshem Flasher 2.0            #
#=================================================#
# Author:    S. Reddy (Polar)                     #
#=================================================#
# Purpose:   Install arch on USB with pactsrap    #
# Docs:      https://mags.zone/help/arch-usb.html #
#=================================================#

VERSION=0.1
DEBUG=false
HELPER=false
LOG=true
LOGFILE=$PWD/build.log

# ===============================================
# VARIABLES
# ===============================================
#TARGET=/dev/sdc
MNT="/mnt/usb"
BOOT="/mnt/usb/boot"

# doppelt MNT
ROOTFSPATH="/mnt/usb"

CHROOT="arch-chroot /mnt/usb"
CHROOTCMD="arch-chroot"


HOSTNAME=flasher
PACKAGES="linux linux-firmware base vim"
# BASE PACKAGES
PACKAGESADD="sudo libnewt"

# ===============================================
# CLI INTERFACE
# ===============================================

# OPTIONS (DEFAULT)
WIPE="NO"
ENTER_CHROOT="NO"
TARGET=""

function about() {
  echo""  
  echo "┌──────────────────────────────────────────┐"
  echo "│ Arch Live on USB Creator                 │"
  echo "│ ---------------------------------------- │"
  echo "│ Author:   S. Reddy                       │"
  echo "│ Version:  ${VERSION}                     │"
  echo "│ ---------------------------------------- │"
  echo "│ (c) Adolf Mohr Maschinenfabrik           │"
  echo "└──────────────────────────────────────────┘"
  echo""
}

function usage() {
    echo "Usage: $(basename $0) <options>"
    echo ""
    echo "Options:"
    echo "  --target <device-path> :"
    echo "      Sets target drive /mnt/<sdX>"
    echo ""
    echo "  --wipe"
    echo "      Wipe USB drive before building the LiveCD."
    echo ""
    echo "  --enter-chroot"
    echo "      Starts a chroot environment after build."
    echo ""
    echo "  -h|--help"
    echo "      This help dialog."
    echo ""
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --target)
            TARGET="$2"
            shift
            shift
            ;;
        --wipe)
            WIPE="YES"
            shift
            ;;
        --enter-chroot)
            ENTER_CHROOT="YES"
            shift
            ;;
        -h|--help)
            about
            usage
            exit 0
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            echo "Unknown argument: ${POSITIONAL}"
            usage
            exit 1
            shift
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


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
[ -z $TARGET ] && echo -e "You must specify a target. Determine the target USB device name with lsblk first!\n" && usage && exit 1

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

#================ PREPARE ===================#
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

  log "" && log "==> Unmounting done!"
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

  log "" && log "==> Mounting done!"
}



#================ BASE SYSTEM ===================#

function basesystem()
{
  log "==> Download and install the Arch Linux base packages using pacstrap."
  pacstrap $MNT $PACKAGES
  log "" && log "==> Installing base system done!"
}

function fstabgen()
{
  log "==> Generate a new /etc/fstab using UUIDs as source identifiers"
  genfstab -U /mnt/usb > /mnt/usb/etc/fstab 
  log "" && log "==> Generating fstab done!"
}

#================ CONFIGURE ===================#

function localecfg()
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

function hostnamecfg()
{
log "==> Change hostname to ${HOSTNAME}"  
cat << EOF | $CHROOT
echo ${HOSTNAME} > /etc/hostname
EOF
}

function hostscfg()
{
  local PATH=/etc/hosts

cat << EOF | $CHROOT
printf " \
\n127.0.0.1  localhost \
\n::1        localhost \
\n127.0.1.1  ${HOSTNAME}.localdomain  ${HOSTNAME}" > $PATH
EOF
}

function rootpwcfg()
{
  #TODO: check if works!
  log "" && log "==> Set root password!"
cat << EOF | $CHROOT
usermod --password evis32 root
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


function networkcfg()
{
log "" && log "==> Create network configuration file for automatically establish wired connections"
local PATH=/etc/systemd/network/10-ethernet.network

# TODO:
# printf 'line1\nline2\nline3\n'
# echo -e ""

cat << EOF | $CHROOT
printf "[Match] \
\nName=en* \     
\nName=en* \
\nName=eth* \
\n \
\n[Network] \
\nDHCP=yes \
\nIPv6PrivacyExtensions=yes \  
\n \
\n[DHCPv4] \
\nRouteMetric=10 \ 
\n \
\n[IPv6AcceptRA] \
\nRouteMetric=10" > $PATH
EOF

# HINT: you can add wireless config here:
# https://mags.zone/help/arch-usb.html
}

function networkenable()
{
log "==> Enable systemd networking service"
cat << EOF | $CHROOT
systemctl enable systemd-networkd.service

systemctl enable systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 

systemctl enable systemd-timesyncd.service
EOF
}

function usercfg()
{
  log "==> Set username and password."
cat << EOF | $CHROOT
useradd -m polar
usermod --password evis32 polar
EOF
}

function wheelgrpcfg()
{
  log "==> Ensure the wheel group exists and add user to it."
cat << EOF | $CHROOT
groupadd wheel
usermod -aG wheel polar
EOF
}

function sudocfg()
{
  log "==> Configure sudo ..."
  local PATH=/etc/sudoers.d/10-sudo

cat << EOF | $CHROOT
echo "%sudo ALL=(ALL) ALL" > $PATH
groupadd sudo
usermod -aG sudo user
pacman -S polkit 
EOF
}

function copytui()
{
  $CHROOTCMD $MNT 
  
}
function changepw()
{
  echo -e "${IMAGE_PASSWORD}\n${IMAGE_PASSWORD}\n" | $CHROOTCMD ${ROOTFSPATH} passwd root 
}

if [ "${ENTER_CHROOT}" = "YES" ]
then
    $CHROOTCMD "${MNT}"
fi


### TODO: optional steps, journal

function template()
{
cat << EOF | $CHROOT

EOF
}

# ===========================
# MAIN
# ===========================
about
log "Starting build $(date +"%D %T")"
sleep 2

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
localecfg
hostnamecfg
hostscfg
rootpwcfg

bootloader

networkcfg
networkenable
usercfg
wheelgrpcfg
sudocfg



