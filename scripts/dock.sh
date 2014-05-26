#!/bin/bash

path_root="$3"; if [ -z "${path_root}" ] || [ "${path_root}" = "/" ]; then path_root=""; fi # fix //

for i in `ls "${path_root}/Users"`
	do
	 if [ -d "${path_root}/Users/${i}/Library/Preferences" ]; then
		# com.apple.dock.plist (lazy way for now)
cat > "${path_root}/Users/${i}/Library/Preferences/com.apple.dock.plist" << EOPROFILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>autohide</key>
	<false/>
	<key>launchanim</key>
	<false/>
	<key>mineffect</key>
	<string>scale</string>
	<key>mod-count</key>
	<integer>6</integer>
	<key>persistent-apps</key>
	<array>
		<dict>
			<key>GUID</key>
			<integer>2837871025</integer>
			<key>tile-data</key>
			<dict>
				<key>bundle-identifier</key>
				<string>com.apple.launchpad.launcher</string>
				<key>dock-extra</key>
				<false/>
				<key>file-data</key>
				<dict>
					<key>_CFURLAliasData</key>
					<data>
					AAAAAACoAAMAAQAAzpITwgAASCsAAAAAAAAA
					SwACF24AAM4/EF8AAAAACSD//gAAAAAAAAAA
					/////wABAAQAAABLAA4AHAANAEwAYQB1AG4A
					YwBoAHAAYQBkAC4AYQBwAHAADwAaAAwATQBh
					AGMAaQBuAHQAbwBzAGgAIABIAEQAEgAaQXBw
					bGljYXRpb25zL0xhdW5jaHBhZC5hcHAAEwAB
					LwD//wAA
					</data>
					<key>_CFURLString</key>
					<string>file:///Applications/Launchpad.app/</string>
					<key>_CFURLStringType</key>
					<integer>15</integer>
				</dict>
				<key>file-label</key>
				<string>Launchpad</string>
				<key>file-mod-date</key>
				<integer>3460239455</integer>
				<key>file-type</key>
				<integer>169</integer>
				<key>parent-mod-date</key>
				<integer>3465680967</integer>
			</dict>
			<key>tile-type</key>
			<string>file-tile</string>
		</dict>
		<dict>
			<key>GUID</key>
			<integer>2837871044</integer>
			<key>tile-data</key>
			<dict>
				<key>bundle-identifier</key>
				<string>com.apple.exposelauncher</string>
				<key>dock-extra</key>
				<false/>
				<key>file-data</key>
				<dict>
					<key>_CFURLAliasData</key>
					<data>
					AAAAAAC6AAMAAQAAzpITwgAASCsAAAAAAAAA
					SwACF3kAAM4/EJAAAAAACSD//gAAAAAAAAAA
					/////wABAAQAAABLAA4AKAATAE0AaQBzAHMA
					aQBvAG4AIABDAG8AbgB0AHIAbwBsAC4AYQBw
					AHAADwAaAAwATQBhAGMAaQBuAHQAbwBzAGgA
					IABIAEQAEgAgQXBwbGljYXRpb25zL01pc3Np
					b24gQ29udHJvbC5hcHAAEwABLwD//wAA
					</data>
					<key>_CFURLString</key>
					<string>file:///Applications/Mission%20Control.app/</string>
					<key>_CFURLStringType</key>
					<integer>15</integer>
				</dict>
				<key>file-label</key>
				<string>Mission Control</string>
				<key>file-mod-date</key>
				<integer>3460239504</integer>
				<key>file-type</key>
				<integer>169</integer>
				<key>parent-mod-date</key>
				<integer>3465680967</integer>
			</dict>
			<key>tile-type</key>
			<string>file-tile</string>
		</dict>
	</array>
	<key>persistent-others</key>
	<array/>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>
EOPROFILE

chmod -R 777 "${path_root}/Users/${i}/Library/Preferences/com.apple.dock.plist"
	fi 
done

exit 0