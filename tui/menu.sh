#!/bin/bash

### Purpose: ###
# This is a simple tui menu for flashing compressed dd images
# to Geshem Box PCs. The tui menu is made with whitail.

### Whiptail Docs: ###
# https://linux.die.net/man/1/whiptail
# https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
# https://github.com/simudream/Whiptail-demo
# https://www.dev-insider.de/dialogboxen-mit-whiptail-erstellen-a-860990/

#set -x

# flash on /dev/sda if true false: /dev/null (testing)
PRODUCTION=false

# show minimal menu for service updates
SERVICEMENU=true

# ===========================
# PATH VARS
# ===========================
SCRIPTDIR="$(dirname $(readlink -f $0))"
HELPFILE=${SCRIPTDIR}/help
STARTDIR="/mnt/usb"
EXTENSION='.img.gz'

# for test
STARTDIR="$HOME/Code"

TUILOG="${SCRIPTDIR}/tui.log"
ERRORLOG="${SCRIPTDIR}/error.log"

# ===========================
# TEXT VARS
# ===========================
BACKTITLE="Geshem Flasher 1.0"


from=/dev/sda1
to=/dev/null

intro="This script will flash an dd image stored on USB flash drives
2nd partition to an Geshem Embedded Box PC.

Please note that only the folowing images are recogniezed,
if copied to usb's root directory:
  * nprohd.img.gz
  * pure-installer.bin"

ask4flash="Do you want to flash image on SSD?"


# ===========================
# COLOR PROFILES
# ===========================
export STANDARD='
    root=,blue
    checkbox=,blue
    entry=,blue
    label=blue,
    actlistbox=,blue
    helpline=,blue
    roottext=,blue
    emptyscale=blue
    disabledentry=blue,
'

export GREYGREEN='
    root=green,black
    border=green,black
    title=green,black
    roottext=white,black
    window=green,black
    textbox=white,black
    button=black,green
    compactbutton=white,black
    listbox=white,black
    actlistbox=black,white
    actsellistbox=black,green
    checkbox=green,black
    actcheckbox=black,green
'

SPECIAL='
    root=white,black
    border=black,lightgray
    window=lightgray,lightgray
    shadow=black,gray
    title=black,lightgray
    button=black,cyan
    actbutton=white,cyan
    compactbutton=black,lightgray
    checkbox=black,lightgray
    actcheckbox=lightgray,cyan
    entry=black,lightgray
    disentry=gray,lightgray
    label=black,lightgray
    listbox=black,lightgray
    actlistbox=black,cyan
    sellistbox=lightgray,black
    actsellistbox=lightgray,black
    textbox=black,lightgray
    acttextbox=black,cyan
    emptyscale=,gray
    fullscale=,cyan
    helpline=white,black
    roottext=lightgrey,black
'

GREYGREEN='
    root=red,black
    border=green,black
    title=green,black
    roottext=white,black
    window=green,black
    textbox=white,black
    button=black,green
    compactbutton=white,black
    listbox=white,black
    actlistbox=black,white
    actsellistbox=black,green
    checkbox=green,black
    actcheckbox=black,green
'

export REDBLUE='
    root=,red
    checkbox=,blue
    entry=,blue
    label=blue,
    actlistbox=,blue
    helpline=,blue
    roottext=,blue
    emptyscale=blue
    disabledentry=blue,
'



# chosen color profile
export NEWT_COLORS=$REDBLUE
#export NEWT_COLORS=$STANDARD

# ===========================
# FILEBROWSER FUNCTIONS
# ===========================
function filebrowser()
{
    # first parameter is Menu Title
    # second parameter is optional dir path to starting folder
    # otherwise current folder is selected

    if [ -z $2 ] ; then
        dir_list=$(ls -lhp  | awk -F ' ' ' { print $9 " " $5 } ')
    else
        cd "$2"
        dir_list=$(ls -lhp  | awk -F ' ' ' { print $9 " " $5 } ')
    fi

    curdir=$(pwd)
    if [ "$curdir" == "/" ] ; then  # Check if you are at root folder
        selection=$(whiptail --title "$1" \
                              --menu "\nYou are here: $curdir" 0 0 0 \
                              --cancel-button Cancel \
                              --ok-button Select $dir_list 3>&1 1>&2 2>&3)
    else   # Not Root Dir so show ../ BACK Selection in Menu
        selection=$(whiptail --title "$1" \
                              --menu "\nYou are here: $curdir" 0 0 0 \
                              --cancel-button Cancel \
                              --ok-button Select ../ BACK $dir_list 3>&1 1>&2 2>&3)
    fi

    RET=$?
    if [ $RET -eq 1 ]; then  # Check if User Selected Cancel
       return 1
    elif [ $RET -eq 0 ]; then
       if [[ -d "$selection" ]]; then  # Check if Directory Selected
          filebrowser "$1" "$selection"
       elif [[ -f "$selection" ]]; then  # Check if File Selected
          if [[ $selection == *$EXTENSION ]]; then   # Check if selected File has .img.gz extension
            if (whiptail --title "Confirm selection" --yesno \
                "Dirpath : $curdir\nFilename: $selection" 0 0 \
                         --yes-button "Ok" \
                         --no-button "Retry"); then
                filename="$selection"
                filepath="$curdir"    # Return full filepath  and filename as selection variables
            else
                filebrowser "$1" "$curdir"
            fi
          else   # Not correct extension so Inform User and restart
             errorbox "wrong extension" "\nYou must select a $EXTENSION file"
             filebrowser "$1" "$curdir"
          fi
       else
          # Could not detect a file or folder so Try Again
          whiptail --title "ERROR - selection error" \
                   --msgbox "Error changing to path $selection" 0 0
          filebrowser "$1" "$curdir"
       fi
    fi
}


# ===========================
# MOUNT & DATA FUNCTIONS
# ===========================
function mount_sda3()
{
    # https://www.baeldung.com/linux/bash-is-directory-mounted
    _DATA_DEV=/dev/sda3
    _DATA_MNT=/mnt/data

    mkdir -p $_DATA_MNT             && log "created mount point $_DATA_MNT" || errorlog "failed to create mount point $_DATA_MNT" 
    mount $_DATA_DEV $_DATA_MNT     && log "$_DATA_DEV mounted to $_DATA_MNT" || errorlog "mounting $_DATA_DEV to $_DATA_MNT failed"

    infobox "MOUNTING" "USB: $(_DATA_DEV)   DATA: $(_DATA_MNT)"
}

function mount_usb()
{
    log "try to mount usb drive to /mnt/usb"

    SDB1=/dev/sdb1 #TODO: rename sdb2
    SDC1=/dev/sdc1
    MNT=/mnt/usb

    # create mountpoint & mount
    if mountpoint -q /mnt/usb; then
        umount -f /mnt/usb
        mount $SDB1 $MNT || mount $SDC1 $MNT
    else
        mkdir -p $MNT && log "Created mount point $MNT" || errorlog "Failed to create mount point $MNT"
        mount $SDB1 $MNT || mount $SDC1 $MNT 
    fi

    # check if mount was successful 
    [ ! -z "$(cat /proc/mounts | grep $SDB1)" ] && \
        log "Mounting $SDB1 on $MNT failed." && \
        infobox "$SDB1 was mounted on $MNT" || log "Failed to mount $SDB1 on $MNT" 
    
    [ ! -z "$(cat /proc/mounts | grep $SDC1)" ] && \
        log "Mounting $SDC1 on $MNT failed." && \
        infobox "$SDC1 was mounted on $MNT" || log "Failed to mount $SDC1 on $MNT"

}


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

# ===========================
# FLASH FUNCTIONS
# ===========================
function flash_pure_production()
{
   errorbox "Function is not implemented yet."
}

function flash_pure_update()
{
   errorbox "Function is not implemented yet."
}


function flash_nprohd_production()
{
    mount_usb
    flash       
}

function flash_nprohd_update()

{
    mount_sda3
    mount_usb
    savedata
    flash
    restoredata
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
        errorbox "Error selecting flash image!"
    fi
}




function flash()
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

    [ $PRODUCTION == true ] && TARGET="/dev/sda" && log "dd flash target: /dev/sda"
    [ $PRODUCTION == false ] && TARGET="/dev/sdb" && log "dd flash target: /dev/null"

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
            whiptail --title "Image cloning" --gauge "Flashing ..." 10 78 0
    fi
}

function testflash()
{
    MNT=
    FROM=$MNT/"$IMAGENAME"
    TO=/dev/null

    (pv -n /dev/zero > /dev/null) 2>&1 | \
        whiptail --gauge "Copying disk image..." 10 70 0

    (gunzip -c "$FROM" | pv -n > $TO ) 2>&1 | whiptail --gauge "Clone image ..." 10 70 0 \
        || errorbox "Flashing failed! \nTried to flash $FROM as $TO"    
}


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
        exit
    } | whiptail --title "$3" --gauge "Cloning..." 8 78 0
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
            (pv -n $SDB1 | gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 70 0 \
            || errorbox "Cloning failed! \nTried to clone $SDB1 as $MNT/$IMAGENAME!"
        elif mountpoint -q /mnt/usb; then
            (pv -n $SDC1| gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 70 0 \
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
        (pv -n $SDB1 | gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 70 0 \
         || errorbox "Cloning failed! \nTried to clone $SDB1 as $MNT/$IMAGENAME!"
    elif mountpoint -q /mnt/usb; then
        (pv -n $SDC1| gzip > $MNT/"$IMAGENAME") 2>&1 | whiptail --gauge "Clone image ..." 10 70 0 \
         || errorbox "Cloning failed! \nTried to clone $SDC1 as $MNT/$IMAGENAME!"
    else
        errorbox "No USB drive was mounted on /mnt/usb" 
    fi
}

function clone_prog()
{
    SDB1=/dev/sdb1
    SDC1=/dev/sdc
    MNT=/mnt/usb
    EXTENSION=".img.gz"
    FULLNAME="${FILENAME}${EXTENSION}"
    PROC="menu.sh"

    FROM=$SDC1
    TO="{$MNT}"/"{$FULLNAME}"

    FILENAME=$(whiptail --inputbox "Please enter a filename (without extension):" 10 70 nprohd_$(date +%F_%H-%M-%S) 3>&1 1>&2 2>&3)
    exitstatus=$?
    [[ "$exitstatus" = 1 ]] && main
    
    mount_usb
    clone $FROM $TO "Backup xxx:"
}




# ===========================
# MENUS (DONE!)
# ===========================

### SUB: FLASH ###
function flash_submenu()
{
    while true 
    do
    CHOICE=$(
    whiptail --backtitle "${BACKTITLE}" --title "Flash a Geshem Box PC" --menu "Select which machine generation you are going to flash." 10 70 0 \
    1 "NPRO HD" \
    2 "PURE" \
    3>&2 2>&1 1>&3 )

    exitstatus=$?
    if [ $exitstatus -eq 1 ]; then break; fi;

    case $CHOICE in
    1)
        flash_nprohd_submenu
        ;;
    2)
        flash_pure_submenu
        ;;
    *)
        exit && main
        ;;
    esac
    
    done
}

function flash_nprohd_submenu()
{
    while true 
    do
    CHOICE=$(
    whiptail --backtitle "${BACKTITLE}" --title "Flash a Geshem Box PC" --menu "Select which machine generation you are going to flash." 10 70 0 \
    1 "PRODUCTION" \
    2 "UPDATE (keep customer data)" \
    3>&2 2>&1 1>&3 )

    exitstatus=$?
    if [ $exitstatus -eq 1 ]; then break; fi;

    case $CHOICE in
    1)
        flash_nprohd_production
        ;;
    2)
        flash_nprohd_update
        ;;
    *)
        exit && main
        ;;
    esac
    done
}

function flash_pure_submenu()
{
    while true 
    do
    CHOICE=$(
    whiptail --backtitle "${BACKTITLE}" --title "Flash a Geshem Box PC" --menu \
    "Hint: Choose UPDATE to restore customers config and ISPV!" \
    10 70 0 \
    1 "PRODUCTION" \
    2 "UPDATE (keep customer data)" \
    3>&2 2>&1 1>&3 )

    exitstatus=$?
    if [ $exitstatus -eq 1 ]; then break; fi;

    case $CHOICE in
    1)
        flash_pure_production
        ;;
    2)
        flash_pure_update
        ;;
    *)
        exit && main
        ;;
    esac
    done
}

### SUB: TOOLS ###
function tools()
{
    while true 
    do
    CHOICE=$(
    whiptail --backtitle "${BACKTITLE}" --title "Tools" --ok-button "Select" --cancel-button "Exit" --menu "CLI Tools for manual work!" 10 70 0 \
    1 "Terminal" \
    2 "Filebrowser" \
    3 "Network" \
    4 "Archtail" \
    3>&2 2>&1 1>&3 )

    exitstatus=$?
    [ $exitstatus -eq 1 ] && break

    case $CHOICE in
    1)
        tmux && main
        ;;
    2)
        fff && main
        ;;
    3)
        nmcli && main
        ;;
    4)
        bash archtail.sh && main
        ;;
    *)
        exit && main
        ;;
    esac
    done
}

### SUB: HELP ###
function help()
{
    whiptail --textbox --scrolltext --ok-button "Exit" "$HELPFILE" 0 0 0
    main
}


### SUB: SHUTDOWN ###
function shutdown()
{
    if (whiptail --title "Shutdown" --yesno "I am going to shut down now ..." 0 0 0); then
        /sbin/poweroff
    else
        main
    fi
}

function reboot()
{
    if (whiptail --title "Reboot" --yesno "I am going to reboot now ..." 0 0 0); then
        /sbin/reboot
    else
        main
    fi
}

# ===========================
# HELPER FUNCTIONS
# ===========================

### box functions ###
function infobox()
{
    whiptail --title "INFO" --msgbox "\n'$*'" 0 0
}

function errorbox()
{
    whiptail --title "ERROR" --msgbox "\n$*" 0 0
    errorlog "$*"
}

### Log functions ###
function log()
{
    echo "$(date +'%Y/%m/%d - %T') $*" >> $TUILOG
}

function errorlog()
{
    echo "$(date +'%Y/%m/%d - %T') - $*" >> $ERRORLOG
}


## TODO: not realy implemented
function progressbar() {
    ($3) & # run $ARG in background (daemon) &
    {
        # Keep checking if the process is running. And keep a count.
        i="0"
        while (true); do
            proc=$(ps aux | grep -v grep | grep -e "menu") # scriptname = processname
            if [[ "$proc" == "" ]]; then break; fi
            sleep 1 # adjust for big data
            echo $i
            i=$(expr $i + 1)
        done
        
        echo 100 # display 100% when done
        sleep 2  # some time for user to see
        exit
    } | whiptail --title "$1" --gauge "$2" 8 78 0
}


# ===========================
# MAIN (DONE)
# ===========================
function main()
{
    # TODO: remove cancel button; just for debug tui

    if [ $SERVICEMENU == true ]
    then
        CHOICE=$(
            whiptail --backtitle "${BACKTITLE}" \
            --title "Main Menu" --menu \
            "Minimal Service Menu \nSelect your option ..." \
            --ok-button "Select" 16 100 0 \
                1 "Flash (USB => SSD)" \
                2 "Help" \
                3 "Shutdown" \
                3>&2 2>&1 1>&3 )

        while true 
        do
        $CHOICE

        case $CHOICE in
        1)
            flash_submenu_simple
            ;;
        2)
            help
            ;;
        3)
            shutdown
            ;;
        *)
            exit
            ;;
        esac
        done
        
    else
        CHOICE=$(
            whiptail --backtitle "${BACKTITLE}" \
            --title "Main Menu" --menu "Choose one option ..." \
            --ok-button "Select" 16 100 0 \
                1 "Flash (USB ➞ HD)" \
                2 "Clone (HD ➞ USB)" \
                3 "Tools" \
                4 "Help" \
                5 "Shutdown" \
                3>&2 2>&1 1>&3 )

        while true 
        do
        $CHOICE

        case $CHOICE in
        1)
            flash_submenu
            ;;
        2)
            #clone_auto
            #clone_manual
            clone_prog
            ;;
        3)
            tools
            ;;
        4)
            help
            ;;
        5)
            shutdown
            ;;
        *)
            exit
            ;;
        esac
        done        
    fi 

}

main
