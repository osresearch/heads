#!/bin/sh
# Scan for USB installation options
set -e -o pipefail
. /etc/functions.sh
. /etc/gui_functions.sh
. /tmp/config

# Unmount any previous boot device
if grep -q /boot /proc/mounts ; then
	umount /boot \
		|| die "Unable to unmount /boot"
fi

# Mount the USB boot device
mount_usb || die "Unable to mount /media"

# Get USB boot device
USB_BOOT_DEV=$(grep "/media" /etc/mtab | cut -f 1 -d' ')

# Check for ISO first
get_menu_option() {
	if [ -x /bin/whiptail ]; then
		MENU_OPTIONS=""
		n=0
		while read -r option
		do
			n=$((n + 1))
			option=$(echo "$option" | tr " " "_")
			MENU_OPTIONS="$MENU_OPTIONS $n ${option}"
		done < /tmp/iso_menu.txt

		whiptail --clear --title "Select your ISO boot option" \
			--menu "Choose the ISO boot option [1-$n, s for standard boot, a to abort]:" 20 120 8 \
			-- "$MENU_OPTIONS" \
			2>/tmp/whiptail || die "Aborting boot attempt"

		option_index=$(cat /tmp/whiptail)
	else
		echo "+++ Select your ISO boot option:"
		n=0
		while read -r option
		do
			n=$((n + 1))
			echo "$n. $option"
		done < /tmp/iso_menu.txt

		read -r \
			-p "Choose the ISO boot option [1-$n, s for standard boot, a to abort]: " \
			option_index
	fi

	if [ "$option_index" = "a" ]; then
		die "Aborting boot attempt"
	fi

	if [ "$option_index" = "s" ]; then
			option=""
			return
	fi

	option=$(head -n "$option_index" /tmp/iso_menu.txt | tail -1)
}

# create ISO menu options
ls -1r /media/*.iso 2>/dev/null > /tmp/iso_menu.txt || true
ISO_MENU_OPT_COUNT=$(wc -l /tmp/iso_menu.txt)
if [ $((ISO_MENU_OPT_COUNT)) -gt 0 ]; then
	option_confirm=""
	while [ -z "$option" ] && [ "$option_index" != "s" ]
	do
		get_menu_option
	done

	if [ -n "$option" ]; then
		MOUNTED_ISO=$option
		ISO=${option:7} # remove /media/ to get device relative path
		kexec-iso-init "$MOUNTED_ISO" "$ISO" "$USB_BOOT_DEV"

		die "Something failed in iso init"
	fi
fi

echo "!!! Could not find any ISO, trying bootable USB"
# Attempt to pull verified config from device
if [ -x /bin/whiptail ]; then
	kexec-select-boot -b /media -c "*.cfg" -u -g -s
else
	kexec-select-boot -b /media -c "*.cfg" -u -s
fi

die "Something failed in selecting boot"
