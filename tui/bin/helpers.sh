#!/bin/bash

### log files ###
#TUILOG="$(dirname "$0")/../log/tui.log"
#ERRORLOG="$(dirname "$0")/../log/error.log"

LOGDIR="$(dirname "$0")/log"


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
    echo "$(date +'%Y/%m/%d - %T') $*" >> $LOGDIR/tui.log #$TUILOG
}

function errorlog()
{
    echo "$(date +'%Y/%m/%d - %T') $*" >> $LOGDIR/error.log #$ERRORLOG
}

function usage() {
  echo "┌──────────────────────────────────────────┐"
  echo "Usage: $(basename $0) <options>"
  echo ""
  echo "Options:"
  echo "  --target <device-path> :"
  echo "      Sets target drive /mnt/<sdX>"
  echo ""
  echo "  --fullwipe"
  echo "      Wipe USB drive before building the LiveCD."
  echo ""
  echo "  --enter-chroot"
  echo "      Starts a chroot environment after build."
  echo ""
  echo "  --usage"
  echo "      This help dialog."
  echo "└──────────────────────────────────────────┘"
  echo ""
}

