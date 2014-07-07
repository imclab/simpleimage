#!/bin/bash

#+ create read write sparse disk
#+ mount installesd.dmg in current working directory, use the system version naming convention.
#+ install OSInstall.mpkg
#+ install packages in current working directory.
#+ convert sparse disk to read only compressed disk.
#+ asr scan compressed disk.
#+ simple, minimal error checking.

#+ adapted from https://github.com/MagerValp/AutoDMG
#+ and some stuff here https://github.com/rtrouton

current_directory=$(dirname $0) #++ use current working directory
if [[ $current_directory == "." ]]; then
	current_directory=$(pwd)
fi

#++ setup some variables
osx_version=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion)	# 10.9.2 etc
osx_build=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductBuildVersion) # 13A603 etc
sparse_dmg=~/Desktop/os.sparseimage
target_dmg=~/Desktop/${osx_version}_${osx_build}.dmg
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
	sudo $(basename "$0") PATH_TO_ESD

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

#++ eject disks, if they aren't the next conversion won't work
eject_disks

#++ compress
hdiutil convert -puppetstrings -format UDZO "${sparse_dmg}" -o "${target_dmg}"
if [ $? -ne 0 ]; then
	echo "something went wrong converting UDZO ${sparse_dmg} ... exiting"
	exit 1
fi

#++ cleanup
rm ~/Desktop/os.sparseimage

exit 0