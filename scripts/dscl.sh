#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

#
# dslocal Local groups etc
#
# dscl
sudo dscl . -create /Groups/PowerUsers
sudo dscl . -create /Groups/PowerUsers PrimaryGroupID 1000
# add local administrators to the PowerUsers
sudo dseditgroup -o edit -a admin -t group PowerUsers
# add everyone as printer managers
sudo dseditgroup -o edit -a everyone -t group lpadmin
# add a user if you want to later...
#sudo dseditgroup -o edit -a cgerke -t user PowerUsers

exit 0