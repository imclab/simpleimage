#!/bin/bash
# *************************************** #
# Automates PKG/CMMAC building, using the
# new flat pack PKG format. pkgutil info
# is cool so that's why I prefer this new
# pkg format over the older.
# *************************************** #

#
# Consideration is required with regard
# to spaces in file paths in INPUT_DIR
#

#
# Constants : UPPERCASE with _ separator
# Functions : UPPER camel case.
# Variables : lowercase with _ separator
# 

REVERSE_DOMAIN="com.org"				# reverse domain for bundle ids etc.

PACKAGE_VERSION=$(date +"%Y%m%d%H%M%S")	# dynamic version number based on the date !important, used in detection

WORKING_DIR=$(dirname "${0}")			# directory: working directory
INPUT_DIR="${WORKING_DIR}/input"		# directory: sources for building
LOG_DIR="${WORKING_DIR}/log"			# directory: logs
OUTPUT_DIR="${WORKING_DIR}/output"		# directory: output packages, distribution packages, cmmac

# setup environment
for d in "${INPUT_DIR}" "${LOG_DIR}" "${OUTPUT_DIR}"; do
	mkdir -p "${d}"
done

# test environment
missing_commands=0
#required_commands="pkgutil productbuild CMAppUtil"
required_commands="pkgutil productbuild"
for i in $required_commands; do
  if ! hash "${i}" >/dev/null 2>&1; then
    printf "Command not found in PATH: %s\n" "${i}" >&2
    ((missing_commands++))
    exit 85
  fi
done

# returns stdout
# 2 args: info, path
function echo_stdout
{
	echo "[   ${1}   ] ${2}"
	echo $(date +"%Y%m%d-%H-%M-%S") >> "${LOG_DIR}/DEBUG.txt"
	echo "[   ${1}   ] ${2}" >> "${LOG_DIR}/DEBUG.txt"
}

# returns path true/false
# 1 args: path
function path_exists
{
	if [ -e "${1}" ]; then
		return 0
	else
		return 1
	fi
}

# pkg /scripts template
function pkg_scripts
{
for i in "postinstall" "preinstall"; do
	if (path_exists "${INPUT_DIR}/${application}/scripts/${i}"); then
		echo_stdout "SKIP" " script exists: ${INPUT_DIR}/${application}/scripts/${i}";
		sudo chown root:wheel "${INPUT_DIR}/${application}/scripts/${i}"
		sudo chmod 755 "${INPUT_DIR}/${application}/scripts/${i}"
	else
		mkdir -p "${INPUT_DIR}/${application}/scripts"
cat > "${INPUT_DIR}/${application}/scripts/${i}" << EOPROFILE
#!/bin/bash

exit 0
EOPROFILE

	fi
done
}

# pkg distribution.dist template
function pkg_distribution
{
cat > "${INPUT_DIR}/${application}/distribution.dist" << EOPROFILE
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<installer-gui-script minSpecVersion="1">
    <options customize="never" rootVolumeOnly="true"/>
    <pkg-ref id="PKGID_TEMPLATE">
        <bundle-version/>
    </pkg-ref>
    <options customize="never" require-scripts="false"/>
    <choices-outline>
        <line choice="default">
            <line choice="PKGID_TEMPLATE"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="PKGID_TEMPLATE" visible="false">
        <pkg-ref id="PKGID_TEMPLATE"/>
    </choice>
    <installation-check script="InstallationCheck()"/>
    <script>
    function InstallationCheck()
    {
        
        // THIS IS A DYNAMICALLY CREATED TEMPLATE BECAUSE YOU DID NOT SUPPLY ONE        
        // Just an example of advanced distribution req checks.
        
        // Check for file existence
        //var f = system.files.fileExistsAtPath("/Applications/xxx");
        
        // install
        //if (!f) {
            return true;
        //}

        //my.result.message = system.localizedStringWithFormat('Already installed.');
        //my.result.type = 'Fatal';
        //return false;
    }
    </script>
    <pkg-ref id="PKGID_TEMPLATE" onConclusion="none">#PKGID_TEMPLATE.pkg</pkg-ref>
</installer-gui-script>
EOPROFILE
}

# sha1 checksum
# 1 args: path
# !think about using it in err checking
function checksum
{
    openssl sha1 "${1}" >> "${LOG_DIR}/${application}.txt"
}

# pkgutil payload
function build_pkgbuild
{
# skip if OUTPUT distribution exists
if (path_exists "${output_distribution}"); then
	echo_stdout "SKIP" " output_distribution exists: ${output_distribution}";
else
	# skip if OUTPUT package exists
	if (path_exists "${output_package}"); then
		echo_stdout "SKIP" " output_package exists: ${output_package}";
	else
		pkg_scripts
		#  continue only if /scripts exists
		if (path_exists "${build_scripts}"); then
			#  init payload/nopayload
			if (path_exists "${build_root}"); then
				echo_stdout "PKG " " has a payload, building.  ${output_package}";
				pkgbuild \
				--identifier "${bundle_identifier}" \
				--root "${build_root}" \
				--scripts "${build_scripts}" \
				--version "${PACKAGE_VERSION}" \
				"${output_package}" >> "${LOG_DIR}/${application}.txt"
				checksum "${output_package}"
			else
				echo_stdout "PKG " " has no payload, building. ${output_package}";
				pkgbuild --identifier "${bundle_identifier}" \
				--nopayload --scripts "${build_scripts}" \
				--version "${PACKAGE_VERSION}" \
				"${output_package}" >> "${LOG_DIR}/${application}.txt"
				checksum "${output_package}"
			fi
		else
			echo_stdout "WARN" " build_scripts DO NOT EXIST : ${build_scripts}";
		fi
	fi
fi
}

# productbuild
function build_productbuild {
	# skip if OUTPUT distribution exists
	if (path_exists "${output_distribution}"); then
		echo_stdout "SKIP" " output_distribution exists: ${output_distribution}";
	else
		pkg_distribution
		# build distribution	
		if (path_exists "${build_distribution}"); then
			#echo_stdout "INFO" " has a build_distribution. ${build_distribution}";
			if (path_exists "${output_package}"); then
				rm -f "${dist_temp}"
				cat "${build_distribution}" | sed s/PKGID_TEMPLATE/"${bundle_identifier}"/g > "${dist_temp}"
				if [ $? == 0 ]; then
					echo_stdout "DIST" " has an output_package, building. ${output_distribution}";
					productbuild --distribution "${dist_temp}" \
					--package-path "${OUTPUT_DIR}" \
					"${output_distribution}" >> "${LOG_DIR}/${application}.txt"
					checksum "${output_distribution}"
					# think about rm -Rf "${output_package}"
				else
					echo "rm ${build_distribution} rm ${build_package}"
				fi
			fi
		else
			echo_stdout "WARN" " build_distribution DOES NOT EXIST, cannot productbuild : ${output_distribution}";
		fi
	fi
}

# cmapputil
function build_cmmac {
	# !think of a dynamic way to cmmac a distribution productbuild vs a package
	# so you can build vendors too.
	echo_stdout "SCCM" " building. ${output_cmmac}";
	CMAppUtil -v -c "${output_distribution}" -o "${OUTPUT_DIR}/"
	checksum "${output_cmmac}"
}

# cmapputil vendors
function build_vendor_cmmac {
	# !think of a dynamic way to cmmac a distribution productbuild vs a package
	# so you can build vendors too.
	# skip if OUTPUT cmmac exists
	if (path_exists "${output_cmmac}"); then
		echo_stdout "SKIP" " output_cmmac exists: ${output_cmmac}";
	else
		if (path_exists "${output_distribution}"); then
			echo_stdout "SCCM" " building. ${output_cmmac}";
			CMAppUtil -s -v -c "${output_package}" -o "${OUTPUT_DIR}/"
			checksum "${output_cmmac}"	
		fi
	fi
}

# download vendors
# !think about microsoft remote desktop type vendors, ie pkg in dmg
function build_vendor_download
{
# skip if OUTPUT distribution exists
if (path_exists "${output_distribution}"); then
	echo_stdout "SKIP" " output_distribution exists: ${output_distribution}";
else
	if (path_exists "${vendor}"); then
		vendor_url=$(defaults read "${vendor}" vendor_url)
		vendor_type=$(defaults read "${vendor}" vendor_type)
		vendor_volume=$(defaults read "${vendor}" vendor_volume)
		vendor_payload=$(defaults read "${vendor}" vendor_payload)
		vendor_target=$(defaults read "${vendor}" vendor_target)
		
		echo_stdout "DOWN" " vendor, building : ${vendor}";
		mkdir -p "${build_root}/${vendor_target}"
		curl -L -o "${build_root}/vendor.${vendor_type}" "${vendor_url}"
		
		if [ "${vendor_type}" == "dmg" ]; then
			hdiutil attach -noautofsck -nobrowse -noverify -readonly "${build_root}/vendor.${vendor_type}"
			ditto "/Volumes/${vendor_volume}/${vendor_payload}" "${build_root}/${vendor_target}/${vendor_payload}" >> "${LOG_DIR}/${application}.txt"
			vendor_disk=$(df -k | grep "${vendor_volume}" | awk '{print $1}')
			hdiutil detach "${vendor_disk}" -force
		else
			if [ "${vendor_type}" == "zip" ]; then
				ditto -V -x -k --sequesterRsrc --rsrc "${build_root}/vendor.${vendor_type}" "${build_root}/${vendor_target}/" >> "${LOG_DIR}/${application}.txt"
			fi
		fi
		build_version=$(defaults read "${build_root}/${vendor_target}/${vendor_payload}/Contents/info.plist" CFBundleShortVersionString)

		# !think about naming versions
		#output_package="${OUTPUT_DIR}/${bundle_identifier}${build_version}.pkg"
		#output_distribution="${OUTPUT_DIR}/${bundle_identifier}${build_version}.dist.pkg"
		#output_cmmac="${output_distribution}.cmmac"	
		
		rm -Rf "${build_root}/vendor.${vendor_type}"
		#rm -Rf "${INPUT_DIR}/${application}/root"
		#rm -Rf "${INPUT_DIR}/${application}/scripts"
		# add key for option to go straight to cmmac from dmg or pkg + key to do custom build too
	fi
fi
}

# the magic starts here
function process_deployments {
	application=$(basename "${1}")
	bundle_identifier="${REVERSE_DOMAIN}.${application}"
	build_root="${1}/root"
	build_scripts="${1}/scripts"
	build_distribution="${1}/distribution.dist"
	vendor="${1}/vendor.plist"
	dist_temp="${1}/distribution.dist.temp"
	output_package="${OUTPUT_DIR}/${bundle_identifier}.pkg"
	output_distribution="${OUTPUT_DIR}/${application}.pkg"
	output_cmmac="${output_distribution}.cmmac"
	if [ "${application}" != "input" ]; then
		#build_vendor_download
		build_pkgbuild
		build_productbuild
		#build_cmmac
	fi
	
	# remove the older pkg, or comment this to keep it.
	if [ -e "${output_package}" ]; then
		if [ -e "${output_distribution}" ]; then
			sudo rm -R "${output_package}"
		fi
	fi
	
	# cleanup
	if [ -e "${dist_temp}" ]; then
		sudo rm -R "${dist_temp}"
	fi
	
	sudo chmod -R 777 "${OUTPUT_DIR}"
}

IFS=$'\n'

# kick the tyres
for i in $(find "${INPUT_DIR}" -maxdepth 1); do
	if [ -d "${i}" ]; then
		process_deployments "${i}"
	fi
done

exit 0