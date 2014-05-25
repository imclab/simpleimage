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
	echo $(date +"%Y%m%d-%H-%M-%S") >> "${LOG_DIR}/DEBUG.log"
	echo "[   ${1}   ] ${2}" >> "${LOG_DIR}/DEBUG.log"
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

# pkg distribution.dist template
function make_distribution_dist
{

sudo cat > "${INPUT_DIR}/${application}/distribution.dist" << EOPROFILE
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<installer-gui-script minSpecVersion="1">
    <options customize="never" rootVolumeOnly="true"/>
    <pkg-ref id="${bundle_identifier}">
        <bundle-version/>
    </pkg-ref>
    <options customize="never" require-scripts="false"/>
    <choices-outline>
        <line choice="default">
            <line choice="${bundle_identifier}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${bundle_identifier}" visible="false">
        <pkg-ref id="${bundle_identifier}"/>
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
    <pkg-ref id="${bundle_identifier}" onConclusion="none">${bundle_identifier}.pkg</pkg-ref>
</installer-gui-script>
EOPROFILE
}

# sha1 checksum
# 1 args: path
# !think about using it in err checking
function checksum
{
    openssl sha1 "${1}" >> "${LOG_DIR}/${application}.log"
}

# pkgutil payload
function build_pkgbuild
{
# skip if OUTPUT productbuild pkg exists
if (path_exists "${out_productbuild_pkg}"); then
	echo_stdout "SKIP" " out_productbuild_pkg exists: ${out_productbuild_pkg}";
else
	# skip if OUTPUT pkgbuild pkg exists
	if (path_exists "${out_pkgbuild_pkg}"); then
		echo_stdout "SKIP" " out_pkgbuild_pkg exists: ${out_pkgbuild_pkg}";
	else
		#  continue only if /scripts exists
		if (path_exists "${build_scripts}"); then
			#  init payload/nopayload
			if (path_exists "${build_root}"); then
				echo_stdout "PKG " " has a payload, building.  ${out_pkgbuild_pkg}";
				pkgbuild \
				--identifier "${bundle_identifier}" \
				--root "${build_root}" \
				--scripts "${build_scripts}" \
				--version "${PACKAGE_VERSION}" \
				"${out_pkgbuild_pkg}" >> "${LOG_DIR}/${application}.log"
				#checksum "${out_pkgbuild_pkg}"
			else
				echo_stdout "PKG " " has no payload, building. ${out_pkgbuild_pkg}";
				pkgbuild --identifier "${bundle_identifier}" \
				--nopayload --scripts "${build_scripts}" \
				--version "${PACKAGE_VERSION}" \
				"${out_pkgbuild_pkg}" >> "${LOG_DIR}/${application}.log"
				#checksum "${out_pkgbuild_pkg}"
			fi

			if (path_exists "${distribution_dist}"); then
				echo_stdout "INFO" " has a distribution_dist. ${distribution_dist}";
				build_productbuild
			else
				echo_stdout "WARN" " distribution_dist DOES NOT EXIST, creating from template : ${out_productbuild_pkg}";
				make_distribution_dist
				build_productbuild
				rm -Rf "${distribution_dist}"
			fi

		else
			echo_stdout "WARN" " build_scripts DO NOT EXIST : ${build_scripts}";
		fi
	fi
fi
}

# productbuild
function build_productbuild {
	# skip if OUTPUT productbuild package exists
	if (path_exists "${out_productbuild_pkg}"); then
		echo_stdout "SKIP" " out_productbuild_pkg exists: ${out_productbuild_pkg}";
	else
		# build distribution
		if (path_exists "${distribution_dist}"); then
			if (path_exists "${out_pkgbuild_pkg}"); then
				if (path_exists "${distribution_dist}"); then
					echo_stdout "DIST" " has an out_pkgbuild_pkg, building. ${out_productbuild_pkg}";
					productbuild --distribution "${distribution_dist}" \
					--package-path "${OUTPUT_DIR}" \
					"${out_productbuild_pkg}" >> "${LOG_DIR}/${application}.log"
					checksum "${out_productbuild_pkg}"
				else
					echo_stdout "WARN" " something went wrong with distribution_dist, cannot productbuild : ${out_productbuild_pkg}";
				fi
			fi
		else
			echo_stdout "WARN" " distribution_dist DOES NOT EXIST, cannot productbuild : ${out_productbuild_pkg}";
		fi
	fi
	# Cleanup pkgbuild version, we don't need it.
	rm -Rf "${out_pkgbuild_pkg}"
}

# the magic starts here
function process_deployments {
	application=$(basename "${1}")
	bundle_identifier="${REVERSE_DOMAIN}.${application}"
	build_root="${1}/root"
	build_scripts="${1}/scripts"
	distribution_dist="${1}/distribution.dist"
	vendor="${1}/vendor.plist"
	out_pkgbuild_pkg="${OUTPUT_DIR}/${bundle_identifier}.pkg"
	out_productbuild_pkg="${OUTPUT_DIR}/${application}.pkg"
	output_cmmac="${out_productbuild_pkg}.cmmac"
	if [ "${application}" != "input" ]; then
		#build_vendor_download
		build_pkgbuild
		#build_cmmac
	fi

	sudo chmod -R 777 "${OUTPUT_DIR}"
}

IFS=$'\n'

# kick the tyres
for i in $(find "${INPUT_DIR}" -maxdepth 1); do
	if [ -d "${i}" ]; then
		echo_stdout "    " " BEGIN: ${i}";
		process_deployments "${i}"

		echo_stdout "    " " ";
	fi
done




















# TAKE ANOTHER LOOK AT THIS

# cmapputil
function build_cmmac {
	# !think of a dynamic way to cmmac a distribution productbuild vs a package
	# so you can build vendors too.
	echo_stdout "SCCM" " building. ${output_cmmac}";
	CMAppUtil -v -c "${out_productbuild_pkg}" -o "${OUTPUT_DIR}/"
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
		if (path_exists "${out_productbuild_pkg}"); then
			echo_stdout "SCCM" " building. ${output_cmmac}";
			CMAppUtil -s -v -c "${out_pkgbuild_pkg}" -o "${OUTPUT_DIR}/"
			checksum "${output_cmmac}"
		fi
	fi
}

# download vendors
# !think about microsoft remote desktop type vendors, ie pkg in dmg
function build_vendor_download
{
# skip if OUTPUT distribution exists
if (path_exists "${out_productbuild_pkg}"); then
	echo_stdout "SKIP" " out_productbuild_pkg exists: ${out_productbuild_pkg}";
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
			ditto "/Volumes/${vendor_volume}/${vendor_payload}" "${build_root}/${vendor_target}/${vendor_payload}" >> "${LOG_DIR}/${application}.log"
			vendor_disk=$(df -k | grep "${vendor_volume}" | awk '{print $1}')
			hdiutil detach "${vendor_disk}" -force
		else
			if [ "${vendor_type}" == "zip" ]; then
				ditto -V -x -k --sequesterRsrc --rsrc "${build_root}/vendor.${vendor_type}" "${build_root}/${vendor_target}/" >> "${LOG_DIR}/${application}.log"
			fi
		fi
		build_version=$(defaults read "${build_root}/${vendor_target}/${vendor_payload}/Contents/info.plist" CFBundleShortVersionString)

		# !think about naming versions
		#out_pkgbuild_pkg="${OUTPUT_DIR}/${bundle_identifier}${build_version}.pkg"
		#out_productbuild_pkg="${OUTPUT_DIR}/${bundle_identifier}${build_version}.dist.pkg"
		#output_cmmac="${out_productbuild_pkg}.cmmac"

		rm -Rf "${build_root}/vendor.${vendor_type}"
		#rm -Rf "${INPUT_DIR}/${application}/root"
		#rm -Rf "${INPUT_DIR}/${application}/scripts"
		# add key for option to go straight to cmmac from dmg or pkg + key to do custom build too
	fi
fi
}

exit 0
