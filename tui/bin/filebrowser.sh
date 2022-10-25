#!/bin/bash

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


