### BASE MENU ###
function create_submenu()
{
    whiptail --backtitle "${BACKTITLE}" --title "$1" --nocancel --menu "Make your choice" 10 70 0 \
    "$2"    "$3" \
    "$5"    "$6" \
    "$8"    "$9" \
    "${11}" "${12}" \
    "${14}" "${15}" \
    "${17}" "${18}" \
    "${20}" "${21}" \
    "${23}" "${24}" \
    "${26}" "${27}" \
    3>&2 2>&1 1>&3

    item=$(show_tools_submenu)
    case $item in
    1)
        $4
        ;;
    2)
        $7
        ;;
    3)
        ${10}
        ;;
    4)
        ${13}
        ;;            
    5)
        ${16}
        ;;
    6)
        ${19}
        ;;
    7)
        ${21}
        ;;
    8)
        ${24}
        ;;
    9)
        ${27}
        ;;
    *)
        exit
        ;;
    esac
}


function create_sub()
{
while true 
do
CHOICE=$(
whiptail --backtitle "${BACKTITLE}" --title "$1" --nocancel --menu "Make your choice" 10 70 0 \
    "$2"    "$3" \
    "$5"    "$6" \
    "$8"    "$9" \
    "${11}" "${12}" \
    "${14}" "${15}" \
    "${17}" "${18}" \
    "${20}" "${21}" \
    "${23}" "${24}" \
    "${26}" "${27}" \
    3>&2 2>&1 1>&3
)

case $CHOICE in
    $2)
        $4
        ;;
    $5)
        $7
        ;;
    $8)
        ${10}
        ;;
    ${11})
        ${13}
        ;;            
    ${14})
        ${16}
        ;;
    ${17})
        ${19}
        ;;
    ${20})
        ${21}
        ;;
    ${23})
        ${24}
        ;;
    ${26})
        ${27}
        ;;
    *)
        exit
        ;;  
esac
done
}


### END::BASE_MENU ###