#!/bin/bash


# image repo 
function mount_sdb4()
{
    DEV=/dev/sdb4
    TO=/mnt/usb
    mkdir -p $TO && \
    mount $DEV $TO && \
    log "Mounting $DEV to $TO ..."
}

### SERVICE UPDATE ###
function clone_sda2()
{
    FROM=/dev/sda2
    TO=/mnt/usb/nprohd_sda2_$(date +%F_%H-%M-%S).img
    log "Cloning $FROM to $TO ..."
    partclone.ext4 -N -d -c -s $FROM -o $TO && \
    partclone.ext4 -N -c -s $FROM | gzip -c -6 > $TO
    log "Cloning $FROM to $TO succesful."
}

function flash_sda2()
{
    selectimg
    FROM=_IMG #sda2.img # TODO: whiptail filebrowser
    TO=/dev/sda2
    log "Restore $FROM to $TO ..."
    partclone.ext4 -d -r -s sda2.img -o /dev/sda2 && \
    log "Restoring $FROM to $TO succesful."
}

function selectimg()
{
    _IMG=""

    filebrowser "Select a image to flash" "$STARTDIR"

    exitstatus=$?
    if [ $exitstatus == 0 ]; then
        if [ "$selection" == "" ]; then
            [[ "$exitstatus" == 1 ]] && main
        else
            _IMG=$selection
            log "Image selected: $selection => IMG: $_IMG"
        fi
    else
        errorbox "Error selecting flash image!" && main
    fi
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