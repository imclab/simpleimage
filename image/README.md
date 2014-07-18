# installesd.bash
builds a dmg base on Apple InstallESD.dmg + any packages in the current working directory. ie. the minimal OSX
packages in the packages folder.

--iso option to create a disk image for playing around in virtualbox

--usb option to create a custom Recovery HD that can be restored to a USB disk then used to deploy images...unfinished.

# packages.bash
source packages for a minimal OSX operating system dmg.

The script will recursively search the sub folders looking for a structure that conforms to my PKG template. It
uses the built-in Apple tools pkgutil and productbuild.

		Example:

		YOURSEARCHPATH
		|-- YOURAPPTOPACKAGE
		|   |-- root
		|   |   |-- Applications
		|   |   +-- Library
		|   |-- scripts
		|       |-- postinstall
		|       +-- preinstall
		+-- log
