#!/bin/bash

#++ mount installesd.dmg
#++ create read write sparse disk
#++ install OSInstall.mpkg
#++ install any packages in current working directory.
#++ convert sparse disk.
#++ asr scan it.

#++ if --usb is specified
#++ create a custom USB dmg based on BaseSystem.dmg
#++ create /INSTALL folder in the root of the custom USB to store deployable images
#++ convert the custom BaseSystem.dmg
#++ asr scan it.

current_directory=$(dirname $0) #++ use current working directory
if [[ $current_directory == "." ]]; then
	current_directory=$(pwd)
fi

#++ setup some variables
osx_version=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion)	# 10.9.2 etc
osx_build=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductBuildVersion) # 13A603 etc
basesystem_dmg="/Volumes/OS X Install ESD/BaseSystem.dmg" # APPLE'S BASE SYSTEM, THE BOOTABLE RECOVERY OS
sparse_dmg=~/Desktop/os.sparseimage
target_dmg=~/Desktop/${osx_version}_${osx_build}.dmg
target_usb_dmg=~/Desktop/${osx_version}_${osx_build}_USB.dmg
volume_name="System"
volume_size="20g"

#++ must sudo
if [[ $(id -u) -ne 0 ]]; then
	echo "Run this script with sudo."
	exit 1
fi

#++ remind me to specify the esd
if [ $# -eq 0 ]; then
cat <<EOF

	Usage:
	sudo $(basename "$0") PATH_TO_ESD [--iso]
		--iso 	Create Virtualbox bootable image.
		--usb 	Create bootable image for USB.

EOF
exit 1
fi

#++ house keeping
declare -a disk_mounts
eject_disks() {
    unset tempdirs
    sleep 3
    hdiutil detach "/Volumes/OS X Install ESD" -force 2>/dev/null
    for mount_point in "${disk_mounts[@]}"; do
    if [[ -d "${mount_point}" ]]; then
        if ! hdiutil eject "${mount_point}"; then
            for tries in {1..10}; do
                sleep ${tries}
                if hdiutil eject "${mount_point}" -force 2>/dev/null; then
                    break
                fi
            done
        fi
    fi
    done
    unset disk_mounts
    return 0
}

#++ mount installesd source file
if [ -e "${1}" ]; then
	attached_installesd=$(hdiutil attach "${1}" -nobrowse -owners on)
	disk_mounts+=("${attached_installesd}")
	if [ $? -ne 0 ]; then
		echo "error attaching ${1} ... exiting"
		exit 1
	fi
fi

#++ create a sparse disk
hdiutil create -size "${volume_size}" -type SPARSE -fs HFS+J -volname "${volume_name}" -uid 0 -gid 80 -mode 1775 ${sparse_dmg}
if [ $? -ne 0 ]; then
	echo "could not create ${sparse_dmg} ... exiting"
	exit 1
fi
attached_sparse=$(hdiutil attach -nobrowse -noautoopen -noverify -owners on "${sparse_dmg}" | grep Apple_HFS | cut -f3)
disk_mounts+=("${attached_sparse}")
if [ $? -ne 0 ]; then
	echo "could not attach ${attached_sparse} ... exiting"
	exit 1
fi

#++ install OSX
installer -verboseR -dumplog -pkg /Volumes/OS\ X\ Install\ ESD/Packages/OSInstall.mpkg -target "${attached_sparse}"
if [ $? -ne 0 ]; then
	echo "something went wrong installing OSInstall.mpkg ... exiting"
	exit 1
fi

#++ install packages
for p in $(ls ${current_directory} | grep ".pkg")
do
	installer -verboseR -dumplog -pkg "${current_directory}/${p}" -target "${attached_sparse}"
	if [ $? -ne 0 ]; then
		echo "something may have gone wrong with ${current_directory}/${p}"
	fi
done

#++ USB option?
if [[ ${2} == "--usb" ]] || [[ ${3} == "--usb" ]]; then
	#++ USB convert original basesystem.dmg to RW
	if [ -e "${basesystem_dmg}" ]; then
		open /tmp
		sudo hdiutil convert -format UDRW "${basesystem_dmg}" -o /tmp/BaseSystemRW.dmg
		if [ $? -ne 0 ]; then
			echo "error converting ${basesystem_dmg}"
		fi
	fi
	sleep 3

	#++ eject disks, if they aren't the next conversion won't work
	eject_disks
	sleep 3

	#++ attach RW basesytem.dmg
	if [ -e "/tmp/BaseSystemRW.dmg" ]; then
		attached_basesystem_temp=$(hdiutil attach "/tmp/BaseSystemRW.dmg" -nobrowse -owners on)
		disk_mounts+=("${attached_basesystem_temp}")
		if [ $? -ne 0 ]; then
			echo "error attaching /tmp/BaseSystemRW.dmg ..."
		fi
	fi
	sleep 3

	#++ rename temp BaseSystem.dmg VOLUME
	#++ probably need something smarter here to detect /dev/disks etc
	if [[ -d "/Volumes/OS X Base System" ]]; then
		sudo diskutil rename "OS X Base System" "USB OS X Base System"
		if [ $? -ne 0 ]; then
			echo "error renaming '/Volumes/OS X Base System' to 'USB OS X Base System'"
		fi
	fi
	sleep 3

	#++ this folder will contain the DMG or PKG files used in the Recovery HD menu/automation script
	if [[ -d "/Volumes/USB OS X Base System" ]]; then
		mkdir "/Volumes/USB OS X Base System/INSTALL"
		if [ $? -ne 0 ]; then
			echo "error INSTALL folder ..."
		fi
	else
		echo "error USB volume..."
	fi

	#++ detach USB volume
	hdiutil detach "/Volumes/USB OS X Base System" -force 2>/dev/null

	#++ compress
	sudo hdiutil convert -format UDZO "/tmp/BaseSystemRW.dmg" -o ${target_usb_dmg}
	if [ $? -ne 0 ]; then
		echo "error UDZO ..."
	fi

	#++ clean up
	rm -f "/tmp/BaseSystemRW.dmg"

	#++ asr scan
	if [[ -e ${target_usb_dmg} ]]; then
		sudo asr imagescan --source ${target_usb_dmg}
		if [ $? -ne 0 ]; then
			echo "asr scan for restore failed."
		fi
	fi

fi

#++ eject disks, if they aren't the next conversion won't work
eject_disks

#++ compress
hdiutil convert -puppetstrings -format UDZO "${sparse_dmg}" -o "${target_dmg}"
if [ $? -ne 0 ]; then
	echo "something went wrong converting UDZO ${sparse_dmg} ... exiting"
	exit 1
fi

#++ asr scan
sudo asr imagescan --source ${target_dmg}
if [ $? -ne 0 ]; then
	echo "asr scan for restore failed."
fi
sleep 5

#++ USB option?
if [[ -e "${target_usb_dmg}" ]]; then
	#++ copy to USB, can't do this without resizing the custom DMG
	#++ and moving this section up in front of where we eject the disks.
	#++ for now just echo
	#cp -f "${target_dmg}" "/Volumes/USB OS X Base System/INSTALL/"
	echo "USB : Restore ${target_usb_dmg} to your desired USB disk."
	echo "      Copy ${target_dmg} to the /INSTALL directory on your USB disk."
fi

#++ create iso for virtualbox
if [[ ${2} == "--iso" ]] || [[ ${3} == "--iso" ]]; then
   hdiutil convert "${target_dmg}" -format UDTO -o "${target_dmg}.iso"
   mv "${target_dmg}.iso.cdr" "${target_dmg}.iso"
fi
sleep 5

#++ cleanup
rm ~/Desktop/os.sparseimage

exit 0