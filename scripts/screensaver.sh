#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

#
# user template
#
sudo mkdir "/System/Library/User Template/English.lproj/Library/Preferences/ByHost"
# com.apple.screensaver.${UUID}.plist
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" idleTime -int "1800"
# com.apple.screensaver.${UUID}.plist
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" CleanExit -string "YES"
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" PrefsVersion -int "100"
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" "moduleDict" -dict-add "moduleName" -string "Computer Name"
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" "moduleDict" -dict-add "path" -string "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver"
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" "moduleDict" -dict-add "type" -int "0"
sudo defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.ScreenSaver.Basic" "MESSAGE" -string "${MESSAGE}"
# com.apple.screensaver.plist
sudo defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPassword -int 1
sudo defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPasswordDelay -int 0

exit 0