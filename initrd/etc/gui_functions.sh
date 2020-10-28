#!/bin/bash
# Shell functions for common operations using fbwhiptail

mount_usb()
{
  # Unmount any previous USB device
  if grep -q /media /proc/mounts ; then
    umount /media || die "Unable to unmount /media"
  fi
  # Mount the USB boot device
  mount-usb
  if [ $? -eq 5 ]; then
    exit 1
  elif $?; then
    whiptail --title 'USB Drive Missing' \
      --msgbox "Insert your USB drive and press Enter to continue." 16 60
    mount-usb
    if [ $? -eq 5 ]; then
      exit 1
    elif $?; then
      whiptail "$BG_COLOR_ERROR" --title 'ERROR: Mounting /media Failed' \
        --msgbox "Unable to mount USB device" 16 60
      exit 1
    fi
  fi
}

file_selector()
{
  FILE=""
  FILE_LIST=$1
  MENU_MSG=${2:-"Choose the file"}
  MENU_TITLE=${3:-"Select your File"}

  # create file menu options
  if [ $(wc -l "$FILE_LIST") -gt 0 ]; then
    option=""
    while [ -z "$option" ]
    do
      MENU_OPTIONS=""
      n=0
      while read option
      do
        n=$((n + 1))
        option=$(echo $option | tr " " "_")
        MENU_OPTIONS="$MENU_OPTIONS $n ${option}"
      done < $FILE_LIST

      MENU_OPTIONS="$MENU_OPTIONS a Abort"
      whiptail --clear --title "${MENU_TITLE}" \
        --menu "${MENU_MSG} [1-$n, a to abort]:" 20 120 8 \
        -- $MENU_OPTIONS \
        2>/tmp/whiptail || die "Aborting"

      option_index=$(cat /tmp/whiptail)

      if [ "$option_index" = "a" ]; then
        option="a"
        return
      fi

      option=$(head -n $option_index $FILE_LIST | tail -1)
      if [ "$option" == "a" ]; then
        return
      fi
    done
    if [ -n "$option" ]; then
      FILE=$option
    fi
  else
    whiptail $BG_COLOR_ERROR --title 'ERROR: No Files Found' \
      --msgbox "No Files found matching the pattern. Aborting." 16 60
    exit 1
  fi
}
