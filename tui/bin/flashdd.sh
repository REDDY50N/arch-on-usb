# HOW TO CLONE / FLASH FROM CLI

# Compression rates:
# https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/


# Clone - dd flash with pv - gzip
pv -n /dev/sda | gzip > /mnt/backup/nprohd.img.gz
pv -n /dev/sda2 | zstd -16 > /mnt/backup/nprohd.zst

# Flash
gzcat /mnt/backup/nprohd.img.gz | pv > /dev/sda3
gunzip -c /mnt/backup/nprohd.img.gz | pv > /dev/sda3

## dd flash with pv - zstd
zstdzcat /mnt/backup.img.zst | pv >/dev/sda3

dd bs=1M iflag=fullblock if=/dev/sda status=progress | gzip > /mnt/backup/nprohd.img.gz
gzcat /mnt/usb/nprohd.img.gz | dd bs=1M iflag=fullblock of=/dev/sda2          status=progress

dd bs=1M iflag=fullblock if=/dev/sda2 status=progress | zstd -16v > /mnt/backup/nprohd.img.zst
zstdcat /mnt/usb/nprohd.img.zst | dd bs=1M iflag=fullblock of=/dev/sda2       status=progress


## ausgelagerte Funktionen:

# SAVE / RESTORE DATA
function savedata()
{
    # save customer data from current image
    # save_config & #save_ispv

    _ISPV="/mnt/data/ispv_root"
    _CONF="(mnt/data/.config/POLAR\ MOHR/"
    _TMP=/mnt/usb/tmp

    mkdir -p ${TMP}
    rsync -avz ${_ISPV} ${_CONF} ${_TMP} || \
        cp -arv ${_ISPV} ${_CONF} ${_TMP}
}

function restoredata()
{
    # write customer data back to new image
    _ISPV_TO="(mnt/usb/tmp/ispv_root/"
    _CONF_TO="(mnt/usb/tmp/.config/POLAR\ MOHR/"
}


### FLASH
function flashx()
{
    _IMG=""
    #_TARGET=/dev/sda
    _TARGET=/dev/null
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
        errorbox "Error selecting flash image!"
    fi

    [ -z "$_IMG" ] && errorbox "Image selection failed!"
    
    #(gunzip -c ${filepath}/${filename} | pv > /dev/null ) 2>&1 | \
    #    whiptail --gauge "Flashing dd image to harddrive ..." 10 70 0

    [ $ARMED == true ] && TARGET="/dev/sda" && log "dd flash target: $TARGET"
    [ $ARMED == false ] && TARGET="/dev/null" && log "dd flash target: $TARGET"

    CMD2="(gunzip -c "$_IMG" | pv > /dev/sdb ) 2>&1 |"
    
    CMD="(gunzip -c $_IMG | dd bs=1M iflag=fullblock of=$_TARGET status=progress) 2&>1 |"

    progressbar "FLASH" "I will flash now" "$CMD2"
}


function flash_one()
{
    # whiptail --title "$TITLE" --yesno "$ask4flash" --yes-button "Yes" --no-button "No" 10 70

    if (whiptail --yesno "$ask4flash" 10 78); then
        fileread
        (dd status=progress if="$from" of="$to") 2>&1 | \
            stdbuf -o0 awk -v RS='\r' \
            "/copied/ {printf(\"%0.f\n\", \$1 / $os_image_size * 100) }" | \
            whiptail --title "Image cloning" --gauge "Flashing ..." 10 ${WIDTH} 0
    fi
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