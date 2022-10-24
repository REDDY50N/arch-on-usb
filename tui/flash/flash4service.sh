#!/bin/bash

function mount_sdb4()
{
    DEV=/dev/sdb4
    TO=/mnt/repo
    mkdir -p $TO && \
    mount $DEV $TO && \
    log "Mounting $DEV to $TO ..."
}

function clone_sda2()
{
    FROM=/dev/sda2
    TO=sda2.img
    log "Cloning $FROM to $TO ..."
    partclone.ext4 -d -c -s $FROM -o $TO && \
    log "Cloning $FROM to $TO succesful."
}

function flash_sda2()
{
    FROM=sda2.img
    TO=/dev/sda2
    log "Restore $FROM to $TO ..."
    partclone.ext4 -d -r -s sda2.img -o /dev/sda2 && \
    log "Restoring $FROM to $TO succesful."
}



function clone_sda2()
{
    log "Cloning "
    partclone.ext4 -d -c -s /dev/sda2 -o sda2.img
}

function flash4service_test()
{
    echo "I am flashing for service!"
    #cmd="pv -n /dev/zero > /dev/null"
    #whiptail --scrolltext --msgbox "$(cmd)" 30 60
    #pv -n /dev/zero > /dev/null | echo > MESSAGE
    #whiptail --textbox /dev/stdin 30 60 <<< "$(echo Hello)"
}

function testflash()
{
    MNT=
    FROM=$MNT/"$IMAGENAME"
    TO=/dev/null

    (pv -n /dev/zero > /dev/null) 2>&1 | \
        whiptail --gauge "Copying disk image..." 10 70 0

    (gunzip -c "$FROM" | pv -n > $TO ) 2>&1 | whiptail --gauge "Clone image ..." 10 ${WIDTH} 0 \
        || errorbox "Flashing failed! \nTried to flash $FROM as $TO"    
}