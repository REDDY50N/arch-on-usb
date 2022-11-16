   _          _    _    _                _   _ ___ ___
  /_\  _ _ __| |_ | |  (_)_ _ _  ___ __ | | | / __| _ )
 / _ \| '_/ _| ' \| |__| | ' \ || \ \ / | |_| \__ \ _ \
/_/ \_\_| \__|_||_|____|_|_||_\_,_/_\_\  \___/|___/___/


# Introduction
This page explains how to install Arch Linux on a USB flash drive. 
The end result is a persistent installation identical to that on a 
normal hard drive along with several performance optimizations aimed 
at running Linux on removable flash media. 

It is compatible with both BIOS and UEFI booting modes.

The only packages explicitly installed besides linux, 
linux-firmware, and base are: 
efibootmgr, grub, iwd, polkit, sudo, and vim

Basic services all handled by systemd.

# Part I - Install Base System

Determine the target USB device name: `lsblk`

For the remainder of this guide, the device name will be referred to as /dev/sdX.

## 1. Full wipe (optional)

Use dd to write the USB with all zeros, permanently erasing all data:
`dd if=/dev/zero of=/dev/sdX status=progress && sync`

Expect this to take a relatively long time (hour+) depending on the size of the USB.

## 2. Partition
Delete the MBR & GTP partition tables
`sgdisk -Z /dev/sdX`

Create a 10M BIOS partition, a 500M EFI partition, and a Linux partition with the remaining space:
`sgdisk -o -n 1:0:+10M -t 1:EF02 -n 2:0:+500M -t 2:EF00 -n 3:0:0 -t 3:8300 /dev/sdX`

## 3. Format

Do not format the /dev/sdX1 block. This is the BIOS/MBR parition.

Format the 500MB EFI system partition with a FAT32 filesystem:
`mkfs.fat -F32 /dev/sdX2`

Format the Linux partition with an ext4 filesystem:
`mkfs.ext4 /dev/sdX3`

Format /data partition
`mkfs.exfat --volume-label=data /dev/sdX4`


# 4. Wipe
Erase all available signatures like magic strings (s. libblkid)
`wipefs -a /dev/sdX2`
`wipefs -a /dev/sdX3`
`wipefs -a /dev/sdX4`


## 4. Mount

Mount the ext4 formatted partition as the root filesystem:
```sh
mkdir -p /mnt/usb
mount /dev/sdX3 /mnt/usb
```

Mount the FAT32 formatted EFI partition to /boot:
```sh
mkdir /mnt/usb/boot
mount /dev/sdX2 /mnt/usb/boot
```



## 5. Basesystem (pacstrap)

Download and install the Arch Linux base packages: 
`pacstrap /mnt/usb linux linux-firmware base vim`

## 6. Generate fstab

Generate a new /etc/fstab using UUIDs as source identifiers:
`genfstab -U /mnt/usb > /mnt/usb/etc/fstab`

# Part II - Configure Base System

## 1. Enter chroot
All configuration is done within a chroot. Chroot into the new system:
`arch-chroot /mnt/usb`

Exit the chroot environment when finished by typing exit.

## 2. Locale

Set local timezone with symbolic link: 
`ln -sf /usr/share/zoneinfo/region/city /etc/localtime`
`ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime`

Generate /etc/adjtime:
`hwclock --systohc`

Edit /etc/locale.gen and uncomment the desired language:
`vim /etc/locale.gen`

   or replace with sed:
`sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /etc/locale.gen`

Generate the locale information:
`locale-gen`

Set the LANG variable in /etc/locale.conf:
`echo LANG=<localeline> > /etc/locale.conf`
`echo LANG=de_DE.UTF-8 > /etc/locale.conf`


## 3. Hostname

Create a /etc/hostname file containing the desired hostname on a single line:
`echo hostname > /etc/hostname`
`echo flasher > /etc/hostname`

Edit /etc/hosts to contain only the following content:
`vim /etc/hosts`

```
127.0.0.1  localhost
::1        localhost
127.0.1.1  <hostname>.localdomain  <hostname>
```

```
127.0.0.1  localhost
::1        localhost
127.0.1.1  flasher.localdomain  flasher
```

## 4. Password

Set the root password: `passwd`

## 4. Bootloader

Install grub and efibootmgr packages:
`pacman -S grub efibootmgr`

Install GRUB bootloader on target:
`grub-install --target=i386-pc --recheck /dev/sdX`

Install UEFI booting mode on target (optional):
`grub-install --target=x86_64-efi --efi-directory /boot --recheck --removable`

Generate a GRUB configuration:
`grub-mkconfig -o /boot/grub/grub.cfg`

## 5. Networking
### Wired
Create a networkd configuration file with the following content to automatically establish wired connections:
`vim /etc/systemd/network/10-ethernet.network`

```
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
```

Enable networkd:
`systemctl enable systemd-networkd.service`

### Wireless (optional)
Install and enable iwd to allow user control over wireless interfaces:
```sh
pacman -S iwd
systemctl enable iwd.service
```

Create a networkd configuration file with the following content for wireless connections:
`vim /etc/systemd/network/20-wifi.network`

```
[Match]
Name=wl*

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes

[DHCPv4]
RouteMetric=20

[IPv6AcceptRA]
RouteMetric=20
```

Enable resolved and create link to /run/systmed/resolve/stub-resolv.conf:
`systemctl enable systemd-resolved.service`
`ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`

Enable timesyncd:
`systemctl enable systemd-timesyncd.service`

## 6. User

Create a new user account and set its password:
```sh
useradd -m <user>
passwd <user>

useradd -m polar
passwd polar
```

Ensure the wheel group exists and add user to it:
```sh
groupadd wheel
usermod -aG wheel <user>
```

## 7. sudo / sudoers

Install sudo: `pacman -S sudo`

Enable sudo for the sudo group by creating a rule in /etc/sudoers.d/:
- edit sudoers file with: `EDITOR=vim visudo /etc/sudoers.d/10-sudo`
- paste in this line: `%sudo ALL=(ALL) ALL`

Ensure the sudo group exists and add user to it:
```sh
groupadd sudo
usermod -aG sudo <user>
```

# Part III - Optional

## 1. Policy Kit

Install polkit to allow various commands (reboot and shutdown, among others) to be run by non-root users:
`pacman -S polkit`

## 2. noatime (optional)
Decrease excess writes to the USB by ensuring its filesystems are mounted with the noatime option. Open /etc/fstab in an editor and change each relatime or atime option to noatime:
`vim /etc/fstab`

```sh
# /dev/sdX3 LABEL=rootfs
UUID=<uuid>  /      ext4  rw,noatime      0 1

# /dev/sdX2
UUID=<uuid>  /boot  vfat  rw,noatime,...  0 2

# /dev/sdX4 LABEL=data
UUID=<uuid>  /data  auto  rw,noatime      0 2

```

# 2. Journal (optional)

Prevent the systemd journal service from writing to the USB by configuring it to use RAM. Create a drop-in config file with the following content:
`mkdir -p /etc/systemd/journald.conf.d`
`vim /etc/systemd/journald.conf.d/10-volatile.conf`

```
[Journal]
Storage=volatile
SystemMaxUse=16M
RuntimeMaxUse=32M
```

## 3. InitRamFS mkinitcpio (optional)

### Hooks
Ensure needed modules are always included in the initcpio image. Remove autodetect from HOOKS in /etc/mkinitcpio.conf:
`vim /etc/mkinitcpio.conf`

```
...
HOOKS=(base udev modconf block filesystems keyboard fsck)
...
```

### Disable fallback
Disable fallback image generation (it is identical to the default image without the autodetect hook). Remove fallback from PRESETS in /etc/mkinitcpio.d/linux.preset:

`vim /etc/mkinitcpio.d/linux.preset`
```sh
...
PRESETS=('default')
...
```

Remove the existing fallback image:
`rm /boot/initramfs-linux-fallback.img`

Generate a new initcpio image:
`mkinitcpio -P`

Generate a new GRUB configuration:
`grub-mkconfig -o /boot/grub/grub.cfg`

## 4. nomodeset (optional)
https://wiki.archlinux.org/title/Kernel_mode_setting
https://wiki.archlinux.org/title/Kernel_mode_setting#Disabling_modesetting

Create a GRUB menu item with the nomodeset kernel parameter. Use vim to copy the default menuentry from /boot/grub/grub.cfg into /etc/grub.d/40_custom and add nomodeset to its kernel command line:
`vim /etc/grub.d/40_custom`
```
...
menuentry 'Arch Linux (nomodeset)' ...
...
linux /vmlinuz-linux ... nomodeset
...
```

Generate a new GRUB configuration:
`grub-mkconfig -o /boot/grub/grub.cfg`

## 5. Interface names (optional)

Ensure that main ethernet and wifi interfaces are always named eth0 and wlan0. Revert to traditional device naming:
`ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules`


# Part IV - Polar specific stuff

## 1. Install packages
`pacman -Sy <packages>`

PACKAGES="libnewt, partclone, lshw, tmux, ranger"

Intel framebuffer driver
https://wiki.archlinux.org/title/Xorg#Driver_installation
xf86-video-fbdev

## 2. Copy tui

Service: `sudo cp -rv tui/menu_service.sh /mnt/usb/opt` 
Production: `sudo cp -rv tui/menu_production.sh /mnt/usb/opt`


## 3. Create systemd startup service

#### Method 1:
create a drop-in file: 
`systemctl edit <unit>`

`mkdir -p /etc/systemd/system/getty\@tty1.service.d/`
`vim /etc/systemd/system/getty@tty1.service.d/autologin.conf`

`vim /etc/systemd/getty@tty1.service.d/autologin.conf`

```
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin root --login-program /opt/menu_service.sh --noissue --noclear %I $TERM
```

alternative:
agetty <user>
agetty root


### Root autologin (first step - jump to autorun tui)

This service takes care of tty1 autologin for root account!

agetty service: `systemctl --type=service` 


getty@tty1.service
check status: `systemctl status getty@tty1`


#### Method 2:
```sh
Loaded: /usr/lib/systemd/system/getty@.service
Drop-In: /etc/systemd/getty@tty1.service.d/autologin.conf

# autologin.conf:
[Service]
ExecStart=
ExecStart=-/sbin/agetty -a root %I $TERM
```  

### Autorun TUI
```
/etc/systemd/getty@tty1.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin root --login-program /opt/menu_service.sh --noissue --noclear %I $TERM
```

Reload service: `systemctl daemon-reload`

### Help:   

Manpage: `man systemd-getty-generator` 

agreety: https://wiki.archlinux.org/title/Greetd

agetty
https://wiki.archlinux.org/title/Getty#Automatic_login_to_virtual_console
https://unix.stackexchange.com/questions/42359/how-can-i-autologin-to-desktop-with-systemd#289612


## Framebuffer @ Grub 
https://wiki.archlinux.org/title/GRUB/Tips_and_tricks

> Only the modes supported by the graphics card via VESA BIOS Extensions can be used. To view the list of supported modes, install hwinfo and run hwinfo --framebuffer as root. Alternatively, enter the GRUB command line and run the command videoinfo.

pacman -S hwinfo

/etc/defaults/grub
pacman -S grub-customizer


## 4. Copy image 2 datafs

Mount the datafs:
```sh
mkdir /mnt/datafs
mount /dev/sdX2 /mnt/datafs
cp -v <from> <to>
```