# package_builder.bash
packages for a minimal OSX dmg.

The script will recursively search the sub folders looking for a structure that conforms to my PKG template. It
uses the built-in Apple tools pkgutil and productbuild.

		Example:

		package_builder
		|-- YOURAPPTOPACKAGE
		|   |-- root
		|   |   |-- Applications
		|   |   +-- Library
		|   |-- scripts
		|       |-- postinstall
		|       +-- preinstall
		+-- log

# recovery_builder.bash
builds a recovery hd based on BaseSystem.dmg which I will eventually setup to use on USB flash disks to deploy DMGs in sites
that don't have netboot.

at the moment the disk simply gets a /INSTALL folder in the root. its my intention to store thin image DMGs or custom OSXInstall.mpkg files
here and use a rc boot file to restore/install to a disk0 that is booted from the USB drive.

# system_builder.bash
builds a dmg base on Apple InstallESD.dmg + any packages in the current working directory. ie. the minimal OSX
packages in the package_builder.

# acknowledgments
These guys are worth following.

+ https://github.com/gregneagle
+ https://github.com/MagerValp
+ https://github.com/rtrouton
+ https://github.com/timsutton
