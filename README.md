# pkg
packages for OSX.

# scripts
scripts for OSX i've written & found.

# soe
packages I bundle in my "vanilla" soe via autodmg/createosxinstaller/munki/create_os_x_vm_install_dmg

### how
kick the tyres with build.bash

The script will recursively search the sub folders looking for a structure that confirms to my PKG template. It
uses the built-in Apple tools pkgutil and productbuild.

		Example:

		soe
		|-- input
		|    |-- YOURAPPTOPACKAGE
		|    |-- root
		|    |    |-- Applications
		|    |    +-- Library
		|    |-- scripts
		|         |-- postinstall
		|         +-- preinstall
		+-- log
		|
		+-- output

https://github.com/autopkg is a more full featured solution.

# acknowledgments
These guys are worth following.

+ https://github.com/gregneagle
+ https://github.com/rtrouton
+ https://github.com/timsutton
+ https://github.com/MagerValp
