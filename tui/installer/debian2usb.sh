#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

# todo: enter chroot /dev/sda = /

apt install grml-debootstrap
umount /dev/sdb*
grml-debootstrap --release buster --target /dev/sdb --grub /dev/sdb

echo 'Done :)'