#!/bin/bash

#set -e  # errexit = exit if a command exits with non zero 
#set -u  # treat undefined vars as erros 
#set -o pipefail

# ===========================
# VARIABLES
# ===========================
SCRIPTDIR="$(dirname $(readlink -f $0))"

# LOGS
TUILOG="${SCRIPTDIR}/tui.log"
ERRORLOG="${SCRIPTDIR}/error.log"

# TUI VARS
BACKTITLE="Geshem Flasher 1.0"
WIDTH=70

# ===========================
# COLORS WHIPTAIL
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
            2 "Clone (Partition / Drive)" \
            3 "Shutdown" \
            3>&2 2>&1 1>&3 )
    case $CHOICE in
    1)
        flash_production
        ;;
    2)
        clone
        ;;
    3)
        shutdown
        ;;    
    *)
        exit
        ;;
    esac
}


# ===========================
# FLASH MENU
# ===========================
### FLASH SYSTEM PARTITION ONLY ### 
### FOR SERVICE UPDATE ###

function flash_production()
{
    if mount | grep -w /data > /dev/null; then
        filebrowser "Filebrowser"
        echo "Selected image: $FILE_SELECTED"
        echo "Selected image path: $FILE_SELECTED_PATH"
        flash_sda $FILE_SELECTED_PATH && infobox "Flashing successful. I am going to shutdown now!" && shutdown
    else
        echo "Testmode ==> replace with error message!"
        echo "No partition /data mounted!"
        filebrowser "Filebrowser"
        cat $FILE_SELECTED
    fi        
}

# mount image repo 
function mount_home()
{
    REPO=/dev/sdb4
    TO=/mnt/usb
    mkdir -p $TO && \
    mount $REPO $TO && \
    log "Mounting $REPO to $TO ..."
}

function flash_sda()
{
    FROM="$1"
    TO=/dev/sda
    log "Flashing $FROM to $TO ..."
    cat $FROM | gunzip -c | partclone.dd -N -d  -s - -o $TO && \
    log "Flashing $FROM to $TO succesful."
}

function reboot_prompt()
{
    infobox "Flashing was successful. Reboot now!"
    reboot
}


# ===========================
# CLONE MENU
# ===========================
# clone & compress - system partition only
function clone_sda2()
{
    FROM=/dev/sda2
    TO=/mnt/usb/nprohd_sda2_$(date +%F_%H-%M-%S).img.gz
    log "Cloning $FROM to $TO ..."
    partclone.ext4 -N -c -s $FROM | gzip -c -6 > $TO && \
    log "Cloning $FROM to $TO succesful."
}

# clone & compress - whole drivw
function clone_sda()
{
    # https://partclone.org/usage/partclone.dd.php
    FROM=/dev/sda
    TO=/mnt/usb/nprohd_sda_$(date +%F_%H-%M-%S).img.gz
    log "Cloning $FROM to $TO ..."
    partclone.dd -N -s $FROM | gzip -c -6 > $TO && \
    log "Cloning $FROM to $TO succesful."
}


# ===========================
# HELPERS - FILEBROWSER
# ===========================
function filebrowser
{
    local TITLE=${1:-$MSG_INFO_TITLE}
    local LOCAL_PATH=${2:-$(pwd)}
    local FILE_MASK=${3:-"*"} #.img.gz
    local ALLOW_BACK=${4:-yes}
    local FILES=()

    [ "$ALLOW_BACK" != "no" ] && FILES+=(".." "..")

    # First add folders
    for DIR in $(find $LOCAL_PATH -maxdepth 1 -mindepth 1 -type d -printf "%f " 2> /dev/null)
    do
        FILES+=($DIR "folder")
    done

    # Then add the files
    for FILE in $(find $LOCAL_PATH -maxdepth 1 -type f -name "$FILE_MASK" -printf "%f %s " 2> /dev/null)
    do
        FILES+=($FILE)
    done

    while true
    do
        FILE_SELECTED=$(whiptail --clear --backtitle "$BACK_TITLE" --title "$TITLE" --menu "$LOCAL_PATH" 0 0 0 ${FILES[@]} 3>&1 1>&2 2>&3)

        if [ -z "$FILE_SELECTED" ]; then
            return 1
        else
            if [ "$FILE_SELECTED" = ".." ] && [ "$ALLOW_BACK" != "no" ]; then
                return 0

            elif [ -d "$LOCAL_PATH/$FILE_SELECTED" ] ; then
                if filebrowser "$TITLE" "$LOCAL_PATH/$FILE_SELECTED" "$FILE_MASK" "yes" ; then
                    if [ "$FILE_SELECTED" != ".." ]; then
                        return 0
                    fi
                else
                    return 1
                fi

            elif [ -f "$LOCAL_PATH/$FILE_SELECTED" ] ; then
                FILE_SELECTED="$FILE_SELECTED"
                FILE_SELECTED_PATH="$LOCAL_PATH/$FILE_SELECTED"
                return 0
            fi
        fi
    done
}

# ===========================
# HELPERS - LOG/ERROR
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
