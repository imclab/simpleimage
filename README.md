# package_builder.bash
packages for a minimal OSX dmg.

The script will recursively search the sub folders looking for a structure that confirms to my PKG template. It
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

# system_builder.bash
builds a dmg base on Apple InstallESD.dmg + any packages in the current working directory. ie. the minimal OSX
packages in the package_builder.

# acknowledgments
These guys are worth following.

+ https://github.com/gregneagle
+ https://github.com/rtrouton
+ https://github.com/timsutton
+ https://github.com/MagerValp
