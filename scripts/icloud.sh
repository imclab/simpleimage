#!/bin/bash

dev_os=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion)	# 10.9 etc
dev_build=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductBuildVersion) # 13A603 etc

defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.SetupAssistant.plist" DidSeeCloudSetup -bool true
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.SetupAssistant.plist" GestureMovieSeen none
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.SetupAssistant.plist" LastSeenCloudProductVersion "${dev_os}"
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.SetupAssistant.plist" LastPreLoginTasksPerformedVersion "${dev_os}"
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.SetupAssistant.plist" LastPreLoginTasksPerformedBuild "${dev_build}"

exit 0
