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
WORK="$(dirname $(readlink -f $0))"
MNT="/mnt/usb"
BOOT="/mnt/usb/boot"

# doppelt MNT
ROOTFSPATH="/mnt/usb"

CHROOT="arch-chroot /mnt/usb"
CHROOTCMD="arch-chroot"

HOSTNAME=flasher
USER=polar
ROOTPW="evis32"

# TUI
TUI="/opt/tui/menu.sh"

# BASE PACKAGES
PACKAGES="linux linux-firmware base grub efibootmgr polkit vim sudo libnewt fff ranger tmux"

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
  echo "│ Version:  ${VERSION}                            │"
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
    echo "  --fullwipe"
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
        --fullwipe)
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

# check for empty target
[ -z $TARGET ] && echo -e "You must specify a target. Determine the target USB device name with lsblk first!\n" && usage && exit 1

# clean log 
[ $LOG == true ] && rm $WORK/build.log

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

#================ PARTITIONING ===================#
function partioning()
{
  log "Create 10MB BIOS, 500MB EFI, 3GB for Linux fs and remaining space for image files"
  sgdisk -Z ${TARGET}
  sgdisk -o -n 1:0:+10M -t 1:EF02 -n 2:0:+500M -t 2:EF00 -n 3:0:+3G -t 3:8300 -n 4:0:0 -t 4:8300 $TARGET

  wipefs -a ${TARGET}2
  wipefs -a ${TARGET}3
  wipefs -a ${TARGET}4

  # Hint: Do not format the /dev/sdX1 block. This is the BIOS/MBR parition."

  # Format the 500MB EFI system partition with a FAT32 filesystem:
  mkfs.fat -F32 ${TARGET}2 && log "Creating ${TARGET}2 fs done!"

  # Format the Linux partition with an ext4 filesystem:
  mkfs.ext4 -q ${TARGET}3 && log "Creating ${TARGET}3 fs done!"

  # Format the data partition with an exfat/ntfs filesystem:
  mkfs.ext4 -q ${TARGET}4 && log "Creating ${TARGET}4 fs done!"
}



function fullwipe()   # optional
{
  log "Start full wipe ..."
  log "This may take long time depending on disk size (1 hour+)"
  dd if=/dev/zero of=$TARGET status=progress && sync && log "Wiping done!"
  #dd if=/dev/zero of=$TARGET bs=16M status=progress && sync && log "==> Wiping done!"
}


#================ MOUNTING ===================#

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

  log "==> Unmounting done!" && log ""
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

  log "==> Mounting done!" && log ""
}



#================ BASE SYSTEM ===================#

function basesystem()
{
  log "==> Download and install the Arch Linux base packages using pacstrap."
  pacstrap $MNT $PACKAGES && \
  log "==> Installing base system done!" && log ""
}

function fstabgen()
{
  log "==> Generate a new /etc/fstab using UUIDs as source identifiers"
  genfstab -U /mnt/usb > /mnt/usb/etc/fstab && \
  log "==> Generating fstab done!" && log ""
}

#================ CONFIGURE ===================#

function localecfg()
{
  log "==> Set timezone"
  $CHROOT ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

  log "==> Generate /etc/adjtime (hwclock)"
  $CHROOT  hwclock --systohc

  LANG=de_DE.UTF-8
  log "set language to ${LANG}"
  # Uncomment desired language in /etc/locale.gen:
  #$CHROOT sed -i 's/#de_DE ISO-8859-1/de_DE ISO-8859-1/g' /etc/locale.gen
  $CHROOT sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /etc/locale.gen
  $CHROOT locale-gen
  $CHROOT echo "LANG=de_DE.UTF-8" > /etc/locale.conf
}

#================ USER-CFG ===================#

function hostcfg()
{
  $CHROOT echo ${HOSTNAME} > /etc/hostname && log "==> set hostname to ${HOSTNAME}" 

cat <<EOF > ${MNT}/etc/fstab
127.0.0.1  localhost
::1        localhost
127.0.1.1  ${HOSTNAME}.localdomain  ${HOSTNAME}"
EOF
}

function usercfg()
{
  log "==> Set username and password."
  
  $CHROOT useradd -m $USER && log "==> Created user $USER" || error "==> Failed to create user $USER"
  $CHROOT  usermod --password $ROOTPW polar && log "==> Password for $USER changed to $ROOTPW!" || error "==> Failed to change Password for $USER!"
}



#================ BOOTLAODER ===================#

function bootloader()
{
#cat << EOF | $CHROOT
#grub-install --target=i386-pc --recheck ${TARGET} && \
#grub-install --target=x86_64-efi --efi-directory /boot --recheck --removable && \
#grub-mkconfig -o /boot/grub/grub.cfg
#EOF

  $CHROOTCMD ${MNT} grub-install --force --target=i386-pc --recheck ${TARGET}
  $CHROOTCMD ${MNT} grub-install --force --target=x86_64-efi --efi-directory /boot --recheck --removable
  $CHROOTCMD ${MNT} grub-mkconfig -o /boot/grub/grub.cfg
}

function newmkinitcpio()
{
 echo "TODO"
}

#================ END::BOOTLAODER ===================#

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


function wheelgrpcfg()
{
  log "==> Ensure the wheel group exists and add user to it."
cat << EOF | $CHROOT
groupadd wheel
usermod -aG wheel polar
EOF
log ""
}

function sudocfg()
{
  log "==> Configure sudo ..."
  $CHROOT echo "%sudo ALL=(ALL) ALL" > /etc/sudoers.d/10-sudo
  $CHROOT groupadd sudo && log "==> Add sudo group" || error "==> Failed to add sudo group!"
  $CHROOT usermod -aG sudo $USER && log "==> Add sudo for $USER" || error "==> Failed to add sudo to $USER!"
  log ""
}

# TODO: 


function rootpwcfg()
{
  $CHROOT usermod --password $ROOTPW root && log "==> Set root pw to ${ROOTPW}!" || error "==> Failed to set root pw!"
  echo -e "${ROOTPW}\n${ROOTPW}\n" | $CHROOTCMD $MNT passwd root && log "==> Set root pw to ${ROOTPW}!" || error "==> Failed to set root pw!"
}



#================ TUI CONFIG ===================#
function copytui()
{
  log "copy $WORK/tui to ${MNT}/opt"
  cp -rv ${WORK}/tui ${MNT}/opt
}

function autostart()
{
log "create tui autostart on getty"

FILE=etc/systemd/system/getty@tty1.service.d/autologin.conf
cat <<EOF > ${CHROOT}/${FILE}
# /etc/systemd/system/getty\@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin root --login-program ${TUI} --noissue --noclear %I $TERM
EOF

log "tui getty autostart done!" && log ""
}



# ===========================
# MAIN
# ===========================
about
log "Starting build $(date +"%D %T")"
sleep 2

### prepare ###
unmounting
partioning
mounting

### base system ###
basesystem
fstabgen

### config ###
localecfg
hostcfg
usercfg


bootloader

networkcfg
networkenable

rootpwcfg
wheelgrpcfg

#sudocfg #TODO: dont works
copytui

###  ###
if [ "${ENTER_CHROOT}" = "YES" ]
then
    log "Enter chroot ..."
    $CHROOTCMD $MNT
fi

log "-----------------------------"
log "DONE!"





#================ TEMPLATES ===================#
function copy_template1()
{
  cp -r ${WORK}/tui /mnt/usb/opt 
}


function copy_template2()
{
  install -m 0644 $WORK/tui/ $MNT/opt
}

function copy_template3()
{
  mount -o bind "$WORK/tui" "$MNT/mnt"
  $CHROOTCMD cp -r /mnt /opt
  uexit
  mount "$MNT/mnt"
}

function template()
{
cat << EOF | $CHROOT

EOF
}
