#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

#
# disable softwareupdate
#
sudo /usr/sbin/softwareupdate --schedule off

exit 0