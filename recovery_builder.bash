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
basesystem_dmg="/Volumes/OS X Install ESD/BaseSystem.dmg" # APPLE'S BASE SYSTEM, THE BOOTABLE RECOVERY OS
target_dmg=~/Desktop/${osx_version}_${osx_build}_recovery.dmg

# must sudo
if [[ $(id -u) -ne 0 ]]; then
	echo "Run this script with sudo."
	exit 1
fi

#++ remind me to specify the esd
if [ $# -eq 0 ]; then
cat <<EOF

	Usage:
	sudo $(basename "$0") PATHTOINSTALLESD [--iso]
		--dmg 	Create DMG image. coming soon.
		--pkg 	Create createOSXinstallPkg package. coming soon.
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

if [ $# -eq 0 ]; then
	usage
	exit 1
fi

#++ mount installesd source file
if [ -e "${1}" ]; then
	hdiutil attach "${1}" -nobrowse -owners on
	if [ $? -ne 0 ]; then
		echo "error attaching ${1} ... exiting"
		exit 1
	fi
fi
sleep 5

#++ convert basesystem.dmg to RW
if [ -e "${basesystem_dmg}" ]; then
	basesystem_temp="$(mktemp -d ~/Desktop/BaseSystemRW.XXXX)"
	sudo hdiutil convert -format UDRW -o ${basesystem_temp} "${basesystem_dmg}"
	if [ $? -ne 0 ]; then
		echo "error converting ${basesystem_dmg}"
		exit 1
	fi
fi
sleep 5

#++ eject disks, if they aren't the next conversion won't work
hdiutil detach "/Volumes/OS X Install ESD" -force
if [ $? -ne 0 ]; then
	echo "error detaching /Volumes/OS X Install ESD"
	exit 1
fi
sleep 5

#++ attach RW basesytem.dmg
hdiutil attach "${basesystem_temp}.dmg" -mountpoint "${basesystem_temp}" -nobrowse -owners on
if [ $? -ne 0 ]; then
	echo "error attaching ${attached_basedmg}"
	exit 1
fi
sleep 5

# rename temp BaseSystem.dmg VOLUME
# probably need something smarter here to detect /dev/disks etc
sudo diskutil rename "OS X Base System" "Custom OS X Base System"
if [ $? -ne 0 ]; then
	echo "error renaming '/Volumes/OS X Base System' to 'Custom OS X Base System'"
fi

#++ setup the DMG storage
#++ this folder will contain the DMG or PKG files used in the Recovery HD menu/automation script
mkdir "${basesystem_temp}/INSTALL"

#++ eject disks, if they aren't the next conversion won't work
hdiutil detach "${basesystem_temp}" -force
if [ $? -ne 0 ]; then
	echo "error detaching Custom OS X Base System"
	exit 1
fi
sleep 5

sudo hdiutil convert -format UDZO -o ${target_dmg} "${basesystem_temp}.dmg"
if [ $? -ne 0 ]; then
	echo "error UDZO ... exiting."
	exit 1
fi
sleep 5

#++ clean up
rm -R "${basesystem_temp}"
rm "${basesystem_temp}.dmg"

#++ asr scan
sudo asr imagescan --source ${target_dmg}
if [ $? -ne 0 ]; then
	echo "asr scan for restore failed."
fi
sleep 5

if [[ ${ISO} = 1 ]]; then
   hdiutil convert "${target_dmg}" -format UDTO -o "${target_dmg}.iso"
   mv "${target_dmg}.iso.cdr" "${target_dmg}.iso"
fi

exit 0