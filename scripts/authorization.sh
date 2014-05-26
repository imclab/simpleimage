#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

formatted_date=$(date +"%Y%m%d%H%M%S")

#
# authorization
#
#sudo security authorizationdb read system.preferences > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.plist"
sudo security authorizationdb write system.preferences allow
#sudo security authorizationdb read system.preferences.accessibility > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.accessibility.plist"
sudo security authorizationdb write system.preferences.accessibility allow
#sudo security authorizationdb read system.preferences.datetime > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.datetime.plist"
sudo security authorizationdb write system.preferences.datetime allow
#sudo security authorizationdb read system.preferences.energysaver > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.energysaver.plist"
sudo security authorizationdb write system.preferences.energysaver allow
sudo security authorizationdb read system.preferences.network > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.network.plist"
#sudo security authorizationdb write system.preferences.network allow
sudo cp "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.network.plist" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
sudo /usr/libexec/plistbuddy -c "set group PowerUsers" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
sudo security authorizationdb write system.preferences.network < "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
sudo srm -f "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.network.plist"
sudo srm -f "/usr/local/bin/authorizationdb.${formatted_date}.new.system.preferences.network.plist"
sudo security authorizationdb read system.services.systemconfiguration.network > "/usr/local/bin/authorizationdb.${formatted_date}.system.services.systemconfiguration.network.plist"
#sudo security authorizationdb write system.services.systemconfiguration.network allow
sudo cp "/usr/local/bin/authorizationdb.${formatted_date}.system.services.systemconfiguration.network.plist" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
sudo /usr/libexec/plistbuddy -c "set group PowerUsers" "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
sudo security authorizationdb write system.services.systemconfiguration.network < "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
sudo srm -f "/usr/local/bin/authorizationdb.${formatted_date}.system.services.systemconfiguration.network.plist"
sudo srm -f "/usr/local/bin/authorizationdb.${formatted_date}.new.system.services.systemconfiguration.network.plist"
#sudo security authorizationdb read system.preferences.printing > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.energysaver.plist"
sudo security authorizationdb write system.preferences.printing allow
#sudo security authorizationdb read system.print.admin > "/usr/local/bin/authorizationdb.${formatted_date}.system.print.admin.plist"
sudo security authorizationdb write system.print.admin allow
#sudo security authorizationdb read system.print.operator > "/usr/local/bin/authorizationdb.${formatted_date}.system.print.operator.plist"
sudo security authorizationdb write system.print.operator allow
#sudo security authorizationdb read system.preferences.sharing > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.sharing.plist"
#sudo security authorizationdb write system.preferences.sharing allow
#sudo security authorizationdb read system.preferences.timemachine > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.timemachine.plist"
sudo security authorizationdb write system.preferences.timemachine allow
#sudo security authorizationdb read system.device.dvd.setregion.change > "/usr/local/bin/authorizationdb.${formatted_date}.system.device.dvd.setregion.change.plist"
sudo security authorizationdb write system.device.dvd.setregion.change allow
#sudo security authorizationdb read system.device.dvd.setregion.initial > "/usr/local/bin/authorizationdb.${formatted_date}.system.device.dvd.setregion.initial.plist"
sudo security authorizationdb write system.device.dvd.setregion.initial allow
#sudo security authorizationdb read system.preferences.softwareupdate > "/usr/local/bin/authorizationdb.${formatted_date}.system.preferences.softwareupdate.plist"
#sudo security authorizationdb write system.preferences.softwareupdate allow
#sudo security authorizationdb read system.install.apple-software > "/usr/local/bin/authorizationdb.${formatted_date}.system.install.apple-software.plist"
#sudo security authorizationdb write system.install.apple-software allow
#sudo security authorizationdb read com.apple.SoftwareUpdate.modify-settings > "/usr/local/bin/authorizationdb.${formatted_date}.com.apple.SoftwareUpdate.modify-settings.plist"
#sudo security authorizationdb write com.apple.SoftwareUpdate.modify-settings allow
#sudo security authorizationdb read com.apple.SoftwareUpdate.scan > "/usr/local/bin/authorizationdb.${formatted_date}.com.apple.SoftwareUpdate.scan.plist"
#sudo security authorizationdb write com.apple.SoftwareUpdate.scan allow

exit 0