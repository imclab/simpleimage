#!/bin/bash

me=$0
daemon="$(basename ${me})"

FINDER=$(ps -ax | grep "Finder.app" | grep -v grep | cut -d "/" -f5)

if [ "${FINDER}" != "Finder.app" ]; then
 echo "No finder yet."
 exit 1
fi

[ -e "/var/ard" ] && echo "User dir exists." || exit 1

curl -o ~Desktop/netboot.zip http://osxserver.local/netboot.zip

# Cleanup here rather than in the launchdaemon because the daemon has to respawn several times because I'm not smart enough
# to setup dependancies for this such as mount points etc and instead i use exit statements. basic i know ;)
[ -e "/Library/LaunchDaemons/${daemon}.plist" ] && sudo srm "/Library/LaunchDaemons/${daemon}.plist"; sudo srm "${0}"; sudo launchctl remove "${daemon}"

exit 0