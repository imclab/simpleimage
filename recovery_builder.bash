#!/bin/bash
# Create a custom Recovery HD as a utility to;
# Use createOSXinstaller
# Use AutoDMG
# Use Virtualbox

current_directory=$(dirname $0) #++ use current working directory
if [[ $current_directory == "." ]]; then
	current_directory=$(pwd)
fi

#++ setup some variables
osx_version=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion)	# 10.9.2 etc
osx_build=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductBuildVersion) # 13A603 etc
readwrite_dmg=~/Desktop/${osx_version}_${osx_build}_recovery_RW.dmg
target_dmg=~/Desktop/${osx_version}_${osx_build}_recovery.dmg
basesystem_dmg="/Volumes/OS X Install ESD/BaseSystem.dmg" # APPLE'S BASE SYSTEM, THE BOOTABLE RECOVERY OS

# must sudo
if [[ $(id -u) -ne 0 ]]; then
	echo "Run this script with sudo."
	exit 1
fi

#++ remind me to specify the esd
if [ $# -eq 0 ]; then
cat <<EOF

	Usage:
	sudo $(basename "$0") [--dmg --pkg --iso]
		--dmg 	Create DMG image.
		--pkg 	Create createOSXinstallPkg package.
		--iso 	Create Virtualbox bootable image.

	Description:
	Creates a Recovery HD dmg using Apple's BaseSystem.dmg
	If the relevent option is specifed, AutoDMG generated disk image and
	createOSXinstallPkg package will be copied to the Recovery HD.

	Requirements:
	- Valid Apple InstallESD.dmg

EOF
exit 1
fi

#++ house keeping
declare -a disk_mounts
eject_disks() {
    unset tempdirs
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

#++ convert basesystem.dmg to RW
if [ -e "${basesystem_dmg}" ]; then
	sudo hdiutil convert -format UDRW -o ${readwrite_dmg} "${basesystem_dmg}"
	if [ $? -ne 0 ]; then
		echo "error converting ${basesystem_dmg}"
		XIT 1
	fi
else
	echo "error finding ${basesystem_dmg}"
	exit 1
fi

#++ attach RW basesytem.dmg
sleep 5
attached_basedmg=$(hdiutil attach "${readwrite_dmg}" -nobrowse -owners on)
disk_mounts+=("${attached_basedmg}")
if [ $? -ne 0 ]; then
	echo "error attaching ${readwrite_dmg}"
	XIT 1
fi

# rename temp BaseSystem.dmg VOLUME
# probably need something smarter here to detect /dev/disks etc
if [ -d "/Volumes/OS X Base System" ]; then
	sudo diskutil rename "OS X Base System" "Custom OS X Base System"
	if [ $? -ne 0 ]; then
		echo "error renaming '/Volumes/OS X Base System' to 'Custom OS X Base System'"
	fi
fi

#++ eject disks, if they aren't the next conversion won't work
eject_disks

sudo hdiutil convert -format UDZO -o ${target_dmg} "${readwrite_dmg}"
if [ $? -ne 0 ]; then
	echo "error UDZO ... exiting."
	XIT 1
fi

#++ asr scan
sleep 5
sudo asr imagescan --source ${target_dmg}
if [ $? -ne 0 ]; then
	echo "asr scan for restore failed."
fi

if [[ ${ISO} = 1 ]]; then
   hdiutil convert "${target_dmg}" -format UDTO -o "${target_dmg}.iso"
   mv "${target_dmg}.iso.cdr" "${target_dmg}.iso"
fi

exit 0