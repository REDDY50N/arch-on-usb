# ===========================
# FLASH SUB-MENUS NPRO/ PURE (DONE!)
# ===========================


# ===========================
# FLASH SUBMENU FUNCTIONS
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
    errorbox "Function doesen't work yet."
    # mount
    # flash    
}

function flash_nprohd_update()
{
    errorbox "Function doesen't work yet."
}

### SUB: FLASH ###
function flash_submenu()
{
    while true 
    do
    CHOICE=$(
    whiptail --backtitle "${BACKTITLE}" --title "Flash a Geshem Box PC" --menu "Select which machine generation you are going to flash." 10 ${WIDTH} 0 \
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
    whiptail --backtitle "${BACKTITLE}" --title "Flash a Geshem Box PC" --menu "Select which machine generation you are going to flash." 10 ${WIDTH} 0 \
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
    10 ${WIDTH} 0 \
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


