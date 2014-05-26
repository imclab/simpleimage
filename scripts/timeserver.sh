#!/bin/bash

default_timeserver="internalserver"
default_timeserver2="time.asia.apple.com"
#
# timeserver hack because compiled app can't do sudo for some reason.
# Set primary using systemsetup -setnetworktimeserver
# This command will clear /etc/ntp.conf and add the primary as the first line.

/usr/sbin/systemsetup -setusingnetworktime on
echo "Setting timeserver to ${default_timeserver}"
sudo systemsetup -setnetworktimeserver "${default_timeserver}"
echo "server ${default_timeserver2}" >> /etc/ntp.conf
sudo systemsetup -setusingnetworktime on

exit