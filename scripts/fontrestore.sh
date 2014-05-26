#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

#
# reset os fonts just-in-case
#
sudo fontrestore default

#
# disable os font protection
#
#sudo atsutil fontprotection -off

exit 0