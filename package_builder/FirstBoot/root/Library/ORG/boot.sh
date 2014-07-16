#!/bin/bash
# execute during first boot, self destruct

#
# vars
#
default_nameserver=$(cat /etc/resolv.conf 2>/dev/null | awk '/^domain/ { print $2 }')
default_domain=$(sed 's/[^.]*\.\([^.]*\)\..*/\1/' <<< "${default_nameserver}")
device_os=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion)	# 10.9 etc
device_build=$(defaults read "/System/Library/CoreServices/SystemVersion" ProductBuildVersion) # 13A603 etc
device_serial=$(ioreg -c IOPlatformExpertDevice | sed -E -n -e '/IOPlatformSerialNumber/{s/^.*[[:space:]]"IOPlatformSerialNumber" = "(.+)"$/\1/p;q;}')
[ $(networksetup -getMACADDRESS en1 | awk '{print $3}' | sed s/://g) == "The" ] && device_interface="en1" || device_interface="en0"  # wifi nic if eth0 is empty (mac book air etc)
device_macaddress=$(networksetup -getMACADDRESS ${device_interface} | awk '{print $3}' | sed s/://g) # minus : chars
device_model=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | grep -E model | awk '{print $3}' | sed 's/\<\"//' | sed 's/\"\>//')
device_ram=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Memory" | awk '{print $2$3}')
device_cpu=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Processor Name" | awk '{print $3$4$5$6$7$8$9}')
device_en0=$(/usr/sbin/ipconfig getifaddr en0)
device_en1=$(/usr/sbin/ipconfig getifaddr en1)
device_fw1=$(/usr/sbin/ipconfig getifaddr fw1)
device_utun0=$(ifconfig | grep -A1 'utun0' | grep -A1 'inet' | awk '{print $2}')
formatted_date=$(date +"%Y%m%d%H%M%S")

#
# boot script
booted="/Library/ORG/boot.plist"
if [[ ! -e "/Library/ORG/boot.plist" ]]; then
	
	#++ log... maybe email it
	defaults write /Library/ORG/boot.plist serial "${device_serial}"
	defaults write /Library/ORG/boot.plist macaddress "${device_macaddress}"
	defaults write /Library/ORG/boot.plist model "${device_model}"
	defaults write /Library/ORG/boot.plist os "${device_os}"
	defaults write /Library/ORG/boot.plist build "${device_build}"
	defaults write /Library/ORG/boot.plist ram "${device_ram}"
	defaults write /Library/ORG/boot.plist cpu "${device_cpu}"
	defaults write /Library/ORG/boot.plist en0 "${device_en0}"
	defaults write /Library/ORG/boot.plist en1 "${device_en1}"
	defaults write /Library/ORG/boot.plist utun0 "${device_utun0}"
	
	#++ disable spotlight to speed up the localisation
	#mdutil -ad
	#mdutil -ai off
	
	#++ energy saver
	pmset -a autorestart 0
	pmset -a disksleep 0
	pmset -a displaysleep 90
	pmset -a powerbutton 0
	pmset -a sleep 0
	pmset -a womp 0
	#++ Laptop?
	ioreg -rd1 -c IOPlatformExpertDevice | grep -E model | awk '{print $3}' | sed s/\<\"// | sed s/\"\>// | grep "Book"
	if [ "$?" == "1" ]; then
		echo "desktop"
	else
		#++ battery
		pmset -b autorestart 0
		pmset -b disksleep 0
		pmset -b displaysleep 90
		pmset -b powerbutton 0
		pmset -b sleep 120
		pmset -b womp 0
	fi
	
	#++ disable gatekeeper
	/usr/sbin/spctl --master-disable

	#++ disable softwareupdate
	/usr/sbin/softwareupdate --schedule off
	
	#++ user template
	mkdir "/System/Library/User Template/English.lproj/Library/Preferences/ByHost"

	#++ menu extras
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.systemuiserver" "dontAutoLoad" -array-add -string "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"
	# Laptop?
	ioreg -rd1 -c IOPlatformExpertDevice | grep -E model | awk '{print $3}' | sed s/\<\"// | sed s/\"\>// | grep "Book"
	if [ "$?" == "1" ]; then
		# com.apple.systemuiserver.${UUID}.plist for non-laptop
		defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.systemuiserver" "dontAutoLoad" -array-add -string "/System/Library/CoreServices/Menu Extras/AirPort.menu"
		defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.systemuiserver" "dontAutoLoad" -array-add -string "/System/Library/CoreServices/Menu Extras/VPN.menu"
		defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.systemuiserver" "dontAutoLoad" -array-add -string "/System/Library/CoreServices/Menu Extras/Battery.menu"
	else
		# com.apple.systemuiserver.plist for laptop
		defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.systemuiserver" "menuExtras" -array-add -string "/System/Library/CoreServices/Menu Extras/AirPort.menu"
		defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.systemuiserver" "menuExtras" -array-add -string "/System/Library/CoreServices/Menu Extras/VPN.menu"
		defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.systemuiserver" "menuExtras" -array-add -string "/System/Library/CoreServices/Menu Extras/Battery.menu"
	fi
	# com.apple.screensaver.${UUID}.plist
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" idleTime -int "1800"
	# com.apple.screensaver.${UUID}.plist
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" CleanExit -string "YES"
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" PrefsVersion -int "100"
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" "moduleDict" -dict-add "moduleName" -string "Computer Name"
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" "moduleDict" -dict-add "path" -string "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver"
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver" "moduleDict" -dict-add "type" -int "0"
	defaults -currentHost write "/System/Library/User Template/English.lproj/Library/Preferences/ByHost/com.apple.ScreenSaver.Basic" "MESSAGE" -string "${MESSAGE}"
	# com.apple.screensaver.plist
	defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPassword -int 1
	defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPasswordDelay -int 0
	# com.apple.systempreferences.plist
	defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.systempreferences" HiddenPreferencePanes -array "com.apple.prefs.backup" "com.apple.preferences.icloud" "com.apple.preference.internet" "com.apple.preferences.internetaccounts" "com.apple.preferences.sharing" "com.apple.preferences.appstore" "com.apple.preferences.softwareupdate" "com.apple.preferences.parentalcontrols" "com.apple.preference.startupdisk" "com.NT-Ware.UniFLOWMacClientConfig"
	
	#++ iCloud fix for users updated from older OS's
	for i in `ls /Users`
		do
		 if [ -d "/Users/${i}/Library/Preferences" ]; then
			sudo defaults write "/Users/${i}/Library/Preferences/com.apple.SetupAssistant.plist" DidSeeCloudSetup -bool true
			sudo defaults write "/Users/${i}/Library/Preferences/com.apple.SetupAssistant.plist" GestureMovieSeen none
			sudo defaults write "/Users/${i}/Library/Preferences/com.apple.SetupAssistant.plist" LastSeenCloudProductVersion "${device_os}"
			sudo defaults write "/Users/${i}/Library/Preferences/com.apple.SetupAssistant.plist" LastPreLoginTasksPerformedVersion "${device_os}"
			sudo defaults write "/Users/${i}/Library/Preferences/com.apple.SetupAssistant.plist" LastPreLoginTasksPerformedBuild "${device_build}"
			sudo chown "${i}" "/Users/${i}/Library/Preferences/com.apple.SetupAssistant.plist"
		fi
	done

	# Clean existing .accounts...remove this eventually.
	for i in `ls /Users`
	do
		if [ -d "/Users/${i}" ]; then
			if [ -f "/Users/${i}/.account" ]; then
				srm -f "/Users/${i}/.account"
				dscl . -delete /Users/${i}
				chown -R "${i}" "/Users/${i}"
			fi
		fi
	done
	
	#++ dslocal local groups etc
	dscl . -create /Groups/PowerUsers
	dscl . -create /Groups/PowerUsers PrimaryGroupID 1000
	# add local administrators to the PowerUsers
	dseditgroup -o edit -a admin -t group PowerUsers
	# add everyone as printer managers
	dseditgroup -o edit -a everyone -t group lpadmin
	# add a user if you want to later...
	#dseditgroup -o edit -a cgerke -t user PowerUsers

	#++ authorization
	#security authorizationdb read system.preferences > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.plist"
	security authorizationdb write system.preferences allow
	#security authorizationdb read system.preferences.accessibility > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.accessibility.plist"
	security authorizationdb write system.preferences.accessibility allow
	#security authorizationdb read system.preferences.datetime > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.datetime.plist"
	security authorizationdb write system.preferences.datetime allow
	#security authorizationdb read system.preferences.energysaver > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.energysaver.plist"
	security authorizationdb write system.preferences.energysaver allow
	security authorizationdb read system.preferences.network > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.network.plist"
	#security authorizationdb write system.preferences.network allow
	cp "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.network.plist" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
	/usr/libexec/plistbuddy -c "set group PowerUsers" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
	security authorizationdb write system.preferences.network < "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
	srm -f "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.network.plist"
	srm -f "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
	security authorizationdb read system.services.systemconfiguration.network > "/usr/local/bin/authorizationdb.${formatted_date}.system.services.systemconfiguration.network.plist"
	#security authorizationdb write system.services.systemconfiguration.network allow
	cp "/usr/local/bin/authorizationdb.${formatted_date}.system.services.systemconfiguration.network.plist" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
	/usr/libexec/plistbuddy -c "set group PowerUsers" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
	security authorizationdb write system.services.systemconfiguration.network < "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
	srm -f "/usr/local/bin/authorizationdb.${formatted_date}.system.services.systemconfiguration.network.plist"
	srm -f "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
	#security authorizationdb read system.preferences.printing > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.energysaver.plist"
	security authorizationdb write system.preferences.printing allow
	#security authorizationdb read system.print.admin > "/usr/local/bin/authorizationdb.${formatted_date}.system.print.admin.plist"
	security authorizationdb write system.print.admin allow
	#security authorizationdb read system.print.operator > "/usr/local/bin/authorizationdb.${formatted_date}.system.print.operator.plist"
	security authorizationdb write system.print.operator allow
	#security authorizationdb read system.preferences.sharing > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.sharing.plist"
	#security authorizationdb write system.preferences.sharing allow
	#security authorizationdb read system.preferences.timemachine > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.timemachine.plist"
	security authorizationdb write system.preferences.timemachine allow
	#security authorizationdb read system.device.dvd.setregion.change > "/usr/local/bin/authorizationdb.${formatted_date}.system.device.dvd.setregion.change.plist"
	security authorizationdb write system.device.dvd.setregion.change allow
	#security authorizationdb read system.device.dvd.setregion.initial > "/usr/local/bin/authorizationdb.${formatted_date}.system.device.dvd.setregion.initial.plist"
	security authorizationdb write system.device.dvd.setregion.initial allow
	#security authorizationdb read system.preferences.softwareupdate > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.softwareupdate.plist"
	#security authorizationdb write system.preferences.softwareupdate allow
	#security authorizationdb read system.install.apple-software > "/usr/local/bin/authorizationdb.${formatted_date}.system.install.apple-software.plist"
	#security authorizationdb write system.install.apple-software allow
	#security authorizationdb read com.apple.SoftwareUpdate.modify-settings > "/usr/local/bin/authorizationdb.${formatted_date}.com.apple.SoftwareUpdate.modify-settings.plist"
	#security authorizationdb write com.apple.SoftwareUpdate.modify-settings allow
	#security authorizationdb read com.apple.SoftwareUpdate.scan > "/usr/local/bin/authorizationdb.${formatted_date}.com.apple.SoftwareUpdate.scan.plist"
	#security authorizationdb write com.apple.SoftwareUpdate.scan allow
	
	#++ prep the the network
	networksetup -setairportpower "en1" "off"
	#networksetup -setv6off "Airport"
	#networksetup -setv6off "Ethernet"
	#networksetup -setv6off "Wi-Fi"
	#networksetup -setnetworkserviceenabled "Bluetooth DUN" "off"
	#networksetup -setnetworkserviceenabled "Bluetooth PAN" "off"
	#networksetup -setnetworkserviceenabled "FireWire" "off"
	
	#++ require admin password for comp-to-comp wifi
	/usr/libexec/airportd en1 prefs RequireAdminIBSS=YES

	#++ set a name for troubleshooting/locating
	scutil --set ComputerName "${device_macaddress}"
	scutil --set LocalHostName "${device_macaddress}"
	scutil --set HostName "${device_macaddress}"
	hostname "${device_macaddress}"

	#++ netbios...keep it short
	defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName "${device_macaddress}"
	
	#++ shortname in Connect to Server dialog... is this needed?
	defaults write /Library/Preferences/com.apple.NetworkAuthorization.plist UseDefaultName -bool NO
	defaults write /Library/Preferences/com.apple.NetworkAuthorization.plist UseShortName -bool YES

	#++ additional loginwindow system information
	#++ disable external accounts (i.e. accounts stored on drives other than the boot drive.)
	#++ hide local admin users
	#++ username/password input fields
	#++ input menu
	defaults write /Library/Preferences/com.apple.loginwindow.plist AdminHostInfo "DSStatus"
	defaults write /Library/Preferences/com.apple.loginwindow.plist EnableExternalAccounts -bool NO
	defaults write /Library/Preferences/com.apple.loginwindow.plist Hide500Users -bool YES
	defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool "TRUE"
	defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool "TRUE"
	#defaults write /var/ard/Library/Preferences/com.apple.menuextra.textinput ModeNameVisible -bool "TRUE"
	#defaults write /Library/Preferences/com.apple.loginwindow StartupDelay -int 13
	#++ text
	defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText -string "Unauthorised access to these resources is prohibited."
	
	#++ reset loginwindow
	defaults delete "${path_root}/System/Library/LaunchDaemons/com.apple.loginwindow.plist" ProgramArguments
	defaults write "${path_root}/System/Library/LaunchDaemons/com.apple.loginwindow.plist" ProgramArguments -array-add "/System/Library/CoreServices/loginwindow.app/Contents/MacOS/loginwindow" "console"
	chown root:wheel "${path_root}/System/Library/LaunchDaemons/com.apple.loginwindow.plist"
	chmod 644 "${path_root}/System/Library/LaunchDaemons/com.apple.loginwindow.plist"

	#++ kickstart sharing
	/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -allowAccessFor -allUsers -access -on -privs -all -clientopts -setvnclegacy -vnclegacy yes
	/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -restart -agent
	defaults write "${path_root}/Library/Preferences/com.apple.RemoteDesktop.plist" Text1 "${device_model} - CPU: ${device_cpu} RAM: ${device_ram}"
	defaults write "${path_root}/Library/Preferences/com.apple.RemoteDesktop.plist" Text2 "${device_serial}"

	#++ should not get here again
	reboot
fi

exit 0