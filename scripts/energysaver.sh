#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

#
# energy saver
#
sudo pmset -a autorestart 0
sudo pmset -a disksleep 0
sudo pmset -a displaysleep 90
sudo pmset -a powerbutton 0
sudo pmset -a sleep 0
sudo pmset -a womp 0
# Laptop?
ioreg -rd1 -c IOPlatformExpertDevice | grep -E model | awk '{print $3}' | sed s/\<\"// | sed s/\"\>// | grep "Book"
if [ "$?" == "1" ]; then
	echo "desktop"
else
	# battery
	sudo pmset -b autorestart 0
	sudo pmset -b disksleep 0
	sudo pmset -b displaysleep 90
	sudo pmset -b powerbutton 0
	sudo pmset -b sleep 120
	sudo pmset -b womp 0
fi

exit 0