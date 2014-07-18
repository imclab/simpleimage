#!/bin/bash

#++ manually create a user on a test machine and run this script to capture the kcpassword file and the hash

current_directory=$(dirname $0) #++ use current working directory
if [[ $current_directory == "." ]]; then
	current_directory=$(pwd)
fi

#++ setup some variables
osx_version=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion)	# 10.9.2 etc

#++ must sudo
if [[ $(id -u) -ne 0 ]]; then
	echo "Run this script with sudo."
	exit 1
fi

#++ usage
if [ $# -eq 0 ]; then
cat <<EOF

	Usage:
	sudo $(basename "$0") USERSHORTNAME
	sudo $(basename "$0") --2 USERSHORTNAME

EOF
exit 1
fi

#++ write to payload config
if [ $# -eq 2 ]; then
	if [ "${1}" == "--2" ]; then
		shortName2="${2}"
		shadowhash2=$(sudo defaults read /var/db/dslocal/nodes/Default/users/${shortName2}.plist ShadowHashData)
		defaults write "${current_directory}/CreateUsers.plist" shortName2 "${shortName2}"
		defaults write "${current_directory}/CreateUsers.plist" shadowhash2 "${shadowhash2}"
	fi
else
	shortName="${1}"
	shadowhash=$(sudo defaults read /var/db/dslocal/nodes/Default/users/${shortName}.plist ShadowHashData)
	defaults write "${current_directory}/CreateUsers.plist" shortName "${shortName}"
	defaults write "${current_directory}/CreateUsers.plist" shadowhash "${shadowhash}"
	#choice menu here, ask if we should copy the kcpassword file
	#cp /etc/kcpassword "${current_directory}/kcpassword.${osx_version}"
fi

#++ let me read it
chmod 755 "${current_directory}/CreateUsers.plist" 

exit 0