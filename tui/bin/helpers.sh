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
