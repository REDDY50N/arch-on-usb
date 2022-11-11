#!/bin/bash

set -e  # errexit = exit if a command exits with non zero 
set -u  # treat undefined vars as erros 
set -o pipefail

# ===========================
# INCLUDE SCRIPTS / FILES
# ===========================
SCRIPTDIR="$(dirname $(readlink -f $0))"

source $(dirname "$0")/bin/clone
source $(dirname "$0")/bin/flash
source $(dirname "$0")/bin/helpers.sh
source $(dirname "$0")/bin/filebrowser.sh



# ===========================
# FILEBROWSER VARS
# ===========================
EXTENSION='.img.gz'
STARTDIR="/mnt/usb" #STARTDIR="/mnt/data"
STARTDIR="$HOME/Code" # for test

# ===========================
# LOGS
# ===========================
TUILOG="${SCRIPTDIR}/tui.log"
ERRORLOG="${SCRIPTDIR}/error.log"

# ===========================
# TUI VARS
# ===========================
BACKTITLE="Geshem Flasher 1.0"
WIDTH=70

# ===========================
# COLOR WHIPTAIL
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

# Hint:
### Options
# root = background: blue
#root                  root fg, bg
#border                border fg, bg
#window                window fg, bg
#shadow                shadow fg, bg
#title                 title fg, bg
#button                button fg, bg
#actbutton             active button fg, bg
#checkbox              checkbox fg, bg
#actcheckbox           active checkbox fg, bg
#entry                 entry box fg, bg
#label                 label fg, bg
#listbox               listbox fg, bg
#actlistbox            active listbox fg, bg
#textbox               textbox fg, bg
#acttextbox            active textbox fg, bg
#helpline              help line
#roottext              root text
#emptyscale            scale full
#fullscale             scale empty
#disentry              disabled entry fg, bg
#compactbutton         compact button fg, bg
#actsellistbox         active & sel listbox
#sellistbox            selected listbox

### Colors ###
#color0  or black
#color1  or red
#color2  or green
#color3  or brown
#color4  or blue
#color5  or magenta
#color6  or cyan
#color7  or lightgray
#color8  or gray
#color9  or brightred
#color10 or brightgreen
#color11 or yellow
#color12 or brightblue
#color13 or brightmagenta
#color14 or brightcyan
#color15 or white

# chosen color profile
export NEWT_COLORS=$REDBLUE


# ===========================
# MAIN MENU
# ===========================
MAIN_MENU_TITLE="Service Flash Menu"
INFOTEXT="You will flash the entire system partition with a new image. Customer data will remain on the data partition.\n\n\n"

function main()
{
    CHOICE=$(
        whiptail --backtitle "${BACKTITLE}" \
        --title "${MAIN_MENU_TITLE}" --menu \
        "${INFOTEXT}" \
        --ok-button "Select" 16 ${WIDTH} 0 \
            1 "Flash (System Partition)" \
            2 "Shutdown" \
            3>&2 2>&1 1>&3 )

    while true 
    do
    case $CHOICE in
    1)
        mount_home && flash_sda2 && reboot_prompt
        ;;
    2)
        shutdown
        ;;
    *)
        exit
        ;;
    esac
    done
}


# ===========================
# MAIN MENU - FLASH
# ===========================

### FLASH SYSTEM PARTITION ONLY ### 
### FOR SERVICE UPDATE ###

# mount image repo 
function mount_home()
{
    REPO=/dev/sdb4
    TO=/mnt/usb
    mkdir -p $TO && \
    mount $REPO $TO && \
    log "Mounting $REPO to $TO ..."
}

# clone & compress - system partition
function flash_sda2()
{
    FROM=/mnt/usb/nprohd_sda2.img.gz
    TO=/dev/sda2
    log "Flashing $FROM to $TO ..."
    cat $FROM | gunzip -c | partclone.ext4 -N -d -r -s - -o $TO && \
    log "Flashing $FROM to $TO succesful."
}

function reboot_prompt()
{
    infobox "Flashing was successful. Reboot now!"
    reboot
}


# ===========================
# HELPERS
# ===========================
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



# ===========================
# HELPERs - LOG/ERROR
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

# ===========================
# SHUTDOWN / REBOOT
# ===========================
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
# MAIN LOOP
# ===========================
main

