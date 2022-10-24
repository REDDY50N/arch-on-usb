#!/bin/bash

### Purpose: ###
# This is a simple tui menu for flashing compressed dd images
# to Geshem Box PCs. The tui menu is made with whitail.

### Whiptail Docs: ###
# https://linux.die.net/man/1/whiptail
# https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
# https://github.com/simudream/Whiptail-demo
# https://www.dev-insider.de/dialogboxen-mit-whiptail-erstellen-a-860990/

# uncomment for debugging
#set -x  # print all
set -e  # errexit = exit if a command exits with non zero 
set -u  # treat undefined vars as erros 
set -o pipefail


# ===========================
# INCLUDE SCRIPTS / FILES
# ===========================
SCRIPTDIR="$(dirname $(readlink -f $0))"

source $(dirname "$0")/flash/*
source $(dirname "$0")/clone/*
source $(dirname "$0")/filebrowser.sh

# tui help files
HELPFILE_SERVICE=${SCRIPTDIR}/help/help4service
HELPFILE_PRODUCTION=${SCRIPTDIR}/help/help4production
HELPFILE_DEVELOP=${SCRIPTDIR}/help/help4dev

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

# ===========================
# CLI ARGS
# ===========================
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -m|--mode)
                MENUCHOOSER="$2"
                shift
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

# ===========================
# MAIN MENU
# ===========================
function main()
{
    if [ $MENUCHOOSER == "service" ]; then
        CHOICE=$(
            whiptail --backtitle "${BACKTITLE}" \
            --title "Main Menu" --menu \
            "Minimal Service Menu \nSelect your option ..." \
            --ok-button "Select" 16 ${WIDTH} 0 \
                1 "Flash (System Partition)" \
                2 "Help" \
                3 "Shutdown" \
                3>&2 2>&1 1>&3 )

        while true 
        do
        case $CHOICE in
        1)
            flash && main
            ;;
        2)
            showhelp
            ;;
        3)
            shutdown
            ;;
        *)
            exit
            ;;
        esac
        done
    elif [ $MENUCHOOSER == "production" ]; then
        CHOICE=$(
            whiptail --backtitle "${BACKTITLE}" \
            --title "Main Menu" --menu "Choose one option ..." \
            --ok-button "Select" 16 ${WIDTH} 0 \
                1 "Flash (full drive)" \
                2 "Clone (full drive)" \
                3 "Help" \
                4 "Shutdown" \
                3>&2 2>&1 1>&3 )

        while true 
        do
        case $CHOICE in
        1)
            flash && main
            ;;
        2)
            clone_prog && main
            ;;
        3)
            showhelp
            ;;
        4)
            shutdown
            ;;
        *)
            exit
            ;;
        esac
        done        
        
    elif [ $MENUCHOOSER == "develop" ]; then
        CHOICE=$(
            whiptail --backtitle "${BACKTITLE}" \
            --title "Main Menu" --menu "Choose one option ..." \
            --ok-button "Select" 16 ${WIDTH} 0 \
                1 "Flash" \
                2 "Clone" \
                3 "Tools" \
                4 "Help" \
                5 "Shutdown" \
                3>&2 2>&1 1>&3 )

        while true 
        do
        case $CHOICE in
        1)
            #/bin/bash tui/flash.sh && main
            flash && main
            ;;
        2)
            clone && main
            ;;
        3)
            tools
            ;;
        4)
            showhelp
            ;;
        5)
            shutdown
            ;;
        *)
            exit
            ;;
        esac
        done 
    else # empty
        error "No menu option choosed! Check MENUCHOOSER variable on top of this script!"     
    fi 
}


# ===========================
# MAIN MENU - FLASH
# ===========================
# Hint: do not change !
function flash()
{
    if   [ $MENUCHOOSER == "service" ]; then
        log "Flash-Mode: SERVICE"
        serviceflash
    elif [ $MENUCHOOSER == "production" ]; then
        log "Flash-Mode: PRODUCTION"
        productionflash
    elif [ $MENUCHOOSER == "develop" ]; then
        log "Flash-Mode: DEVELOP"
        developflash
    fi
}


# Hint: modify here !
function serviceflash()
{
    log "call: serviceflash()"
    flash4service_test
}

function productionflash()
{
    log "call: productionflash()"
}

function developflash()
{
    log "call: developflash()"
}



# ===========================
# SUBMENU - TOOLS
# ===========================
function tools()
{
    while true 
    do
    CHOICE=$(
    whiptail --backtitle "${BACKTITLE}" --title "Tools" --ok-button "Select" --cancel-button "Exit" --menu "CLI Tools for manual work!" 0 ${WIDTH} 0 \
    1 "Terminal" \
    2 "Partclone" \
    3 "Filebrowser - Ranger" \
    4 "Filebrowser - fff" \
    5 "Ressources" \
    6 "Archtail" \
    7 "Partimage" \
    8 "Clonezilla" \
    9 "FS Archiver" \
    3>&2 2>&1 1>&3 )

    exitstatus=$?
    [ $exitstatus -eq 1 ] && break

    case $CHOICE in
    1)
        tmux && main
        ;;
    2)
        partclone && main
        ;;
    3)
        ranger && main
        ;;
    4)
        fff && main
        ;;
    5)
        nmon && main
        ;;
    6)
        bash $PWD/archtail.sh && main
        ;;
    7)
        partimage && main
        ;;
    8)
        clonezilla && main
        ;;                   
    9)  
        fsarchiver && main
        ;;
    *)
        exit && main
        ;;
    esac
    done
}

# ===========================
# HELP
# ===========================
function showhelp()
{
    if [ $MENUCHOOSER == "service" ]; then
        whiptail --textbox --scrolltext --ok-button "Exit" "$HELPFILE_SERVICE" 0 0 0
        main
    elif [ $MENUCHOOSER == "production" ]; then
        whiptail --textbox --scrolltext --ok-button "Exit" "$HELPFILE_PRODUCTION" 0 0 0
        main
    elif [ $MENUCHOOSER == "develop" ]; then
        whiptail --textbox --scrolltext --ok-button "Exit" "$HELPFILE_DEVELOP" 0 0 0
        main
    fi
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

