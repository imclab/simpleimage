#!/bin/bash

#
# timezone hack because compiled app can't do sudo for some reason.
#
echo "Setting timezone to ${default_timezone}"
sudo systemsetup -settimezone "${default_timezone}"

exit 0