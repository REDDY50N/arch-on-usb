#!/bin/bash

### TODO:

# ===========================
# CLONE FUNCTIONS
# ===========================
function clone()
{
    # clone with progress bar loop
    ( (pv -n $1 | gzip > $2) 2>&1 ) & # run $ARG in background (daemon) &
    {
        # Keep checking if the process is running. And keep a count.
        i="0"
        while (true); do
            proc=$(ps aux | grep -v grep | grep -e "${PROC}") # scriptname = processname
            if [[ "$proc" == "" ]]; then break; fi
            sleep 1 # adjust for big data
            echo $i
            i=$(expr $i + 1)
        done
        
        echo 100 # display 100% when done
        sleep 2  # some time for user to see
        exit && main
    } | whiptail --title "$3" --gauge "Cloning..." 8 ${WIDTH} 0
}

function clone_manual()
{
    ### creates an backup of /dev/sda => image_name = userinput

    # TODO: better USB handling; see also mount_usb    
    # TODO: check if pv was successful = 100%
    
    SDB1=/dev/sdb1
    SDC1=/dev/sdc
    MNT=/mnt/usb
    EXTENSION=".img.gz"
    IMAGENAME="${FILENAME}${EXTENSION}"
    
    FILENAME=$(whiptail --inputbox "Please enter a filename (without extension):" 10 70 nprohd_$(date +%F_%H-%M-%S) 3>&1 1>&2 2>&3)
    exitstatus=$?
    [[ "$exitstatus" = 1 ]] && main
    
    # mount
    mount_usb || errorbox "Mounting failed! \
        \n\nCheck if a USB stick is inserted? \
        \n\nHint: \
        \nOtherwise check USB drive for corrupted filesystem. \
        \nCommon for Polar marketing usb drives."

    # clone if filename is not empty
    if [ -z "${FILENAME}" ]; then
        errorbox "Empty filename" "No filename entered! \nEmpty filename is not allowed." 0 0 0
    else
        infobox "Backup Clone drive and save on USB: \n $IMAGENAME"

        # clone 
        if mountpoint -q /mnt/usb; then
            (pv -n $SDB1 | gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 ${WIDTH} 0 \
            || errorbox "Cloning failed! \nTried to clone $SDB1 as $MNT/$IMAGENAME!"
        elif mountpoint -q /mnt/usb; then
            (pv -n $SDC1| gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 ${WIDTH} 0 \
            || errorbox "Cloning failed! \nTried to clone $SDC1 as $MNT/$IMAGENAME!"
        else
            errorbox "No USB drive was mounted on /mnt/usb" 
        fi
           
        infobox "Cloning complete. Image is located here: $MNT/$IMAGENAME"

        main
    fi
}



function clone_auto()
{
    ### creates an backup with auto naming => nprohd + date + img.gz
    # TODO: better USB mount handling, see also mount_usb function

    SDB1=/dev/sdb1
    SDC1=/dev/sdc1
    MNT=/mnt/usb
    IMAGENAME=nprohd_$(date "+%F_%H-%M-%S").img.gz
    
    # create mountpoint & mount
    mount_usb || errorbox "Mounting failed! \
        \n\nCheck if a USB stick is inserted? \
        \n\nHint: \
        \nOtherwise check USB drive for corrupted filesystem. \
        \nCommon for Polar marketing usb drives."
    
    # check if mount was successful 
    [ ! -z "$(cat /proc/mounts | grep $SDB1)" ] && \
        log "Mounting $SDB1 on $MNT failed." && \
        infobox "$SDB1 was mounted on $MNT" || errorbox "Failed to mount $SDB1 on $MNT" 
    
    [ ! -z "$(cat /proc/mounts | grep $SDC1)" ] && \
        log "Mounting $SDC1 on $MNT failed." && \
        infobox "$SDC1 was mounted on $MNT" || errorbox "Failed to mount $SDC1 on $MNT"

    # clone 
    if mountpoint -q /mnt/usb; then
        (pv -n $SDB1 | gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 ${WIDTH} 0 \
         || errorbox "Cloning failed! \nTried to clone $SDB1 as $MNT/$IMAGENAME!"
    elif mountpoint -q /mnt/usb; then
        (pv -n $SDC1| gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 ${WIDTH} 0 \
         || errorbox "Cloning failed! \nTried to clone $SDC1 as $MNT/$IMAGENAME!"
    else
        errorbox "No USB drive was mounted on /mnt/usb" 
    fi
}



# ===========================
# BASIC FUNCTIONS CLONE / FLASH
# ===========================
function clone_with_progressbar()
{
    FROM=$1
    TO=$2

    FILENAME=$(whiptail --inputbox "Please enter a filename (without extension):" 10 70 nprohd_$(date +%F_%H-%M-%S) 3>&1 1>&2 2>&3)
    exitstatus=$?
    [[ "$exitstatus" = 1 ]] && main
    
    mount_usb 
    clone $FROM $TO "$3"
}
