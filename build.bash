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
#for d in "${INPUT_DIR}" "${LOG_DIR}" "${OUTPUT_DIR}"; do
#	mkdir -p "${d}"
#done

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

sudo cat > "${INPUT_FOLDER}/${PKG_TO_BUILD}/distribution.dist" << EOPROFILE
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<installer-gui-script minSpecVersion="1">
    <options customize="never" rootVolumeOnly="true"/>
    <pkg-ref id="${PKG_BUNDLE_ID}">
        <bundle-version/>
    </pkg-ref>
    <options customize="never" require-scripts="false"/>
    <choices-outline>
        <line choice="default">
            <line choice="${PKG_BUNDLE_ID}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${PKG_BUNDLE_ID}" visible="false">
        <pkg-ref id="${PKG_BUNDLE_ID}"/>
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
    <pkg-ref id="${PKG_BUNDLE_ID}" onConclusion="none">${PKG_BUNDLE_ID}.pkg</pkg-ref>
</installer-gui-script>
EOPROFILE
}

# sha1 checksum
# 1 args: path
# !think about using it in err checking
function checksum
{
    openssl sha1 "${1}" >> "${LOG_DIR}/${PKG_TO_BUILD}.log"
}

# pkgutil payload
function build_pkgbuild
{
echo "Making ${INPUT_PARENT}/output"
mkdir -p "${INPUT_PARENT}/output"
mkdir -p "${INPUT_PARENT}/log"
# skip if OUTPUT productbuild pkg exists
if (path_exists "${PKG_PRODBUILD}"); then
	echo_stdout "SKIP" " PKG_PRODBUILD exists: ${PKG_PRODBUILD}";
else
	# skip if OUTPUT pkgbuild pkg exists
	if (path_exists "${PKG_PKGBUILD}"); then
		echo_stdout "SKIP" " PKG_PKGBUILD exists: ${PKG_PKGBUILD}";
	else
		#  continue only if /scripts exists
		if (path_exists "${PKG_SCRIPTS}"); then
			#  init payload/nopayload
			if (path_exists "${PKG_ROOT}"); then
				echo_stdout "PKG " " has a payload, building.  ${PKG_PKGBUILD}";
				pkgbuild \
				--identifier "${PKG_BUNDLE_ID}" \
				--root "${PKG_ROOT}" \
				--scripts "${PKG_SCRIPTS}" \
				--version "${PACKAGE_VERSION}" \
				"${PKG_PKGBUILD}" >> "${LOG_DIR}/${PKG_TO_BUILD}.log"
				#checksum "${PKG_PKGBUILD}"
			else
				echo_stdout "PKG " " has no payload, building. ${PKG_PKGBUILD}";
				pkgbuild --identifier "${PKG_BUNDLE_ID}" \
				--nopayload --scripts "${PKG_SCRIPTS}" \
				--version "${PACKAGE_VERSION}" \
				"${PKG_PKGBUILD}" >> "${LOG_DIR}/${PKG_TO_BUILD}.log"
				#checksum "${PKG_PKGBUILD}"
			fi

			if (path_exists "${PKG_DIST}"); then
				echo_stdout "INFO" " has a PKG_DIST. ${PKG_DIST}";
				build_productbuild
			else
				echo_stdout "WARN" " PKG_DIST DOES NOT EXIST, creating from template : ${PKG_PRODBUILD}";
				make_distribution_dist
				build_productbuild
				rm -Rf "${PKG_DIST}"
			fi

		else
			echo_stdout "WARN" " PKG_SCRIPTS DO NOT EXIST : ${PKG_SCRIPTS}";
		fi
	fi
fi
}

# productbuild
function build_productbuild {
	# skip if OUTPUT productbuild package exists
	if (path_exists "${PKG_PRODBUILD}"); then
		echo_stdout "SKIP" " PKG_PRODBUILD exists: ${PKG_PRODBUILD}";
	else
		# build distribution
		if (path_exists "${PKG_DIST}"); then
			if (path_exists "${PKG_PKGBUILD}"); then
				if (path_exists "${PKG_DIST}"); then
					echo_stdout "DIST" " has an PKG_PKGBUILD, building. ${PKG_PRODBUILD}";
					productbuild --distribution "${PKG_DIST}" \
					--package-path "${OUTPUT_DIR}" \
					"${PKG_PRODBUILD}" >> "${LOG_DIR}/${PKG_TO_BUILD}.log"
					checksum "${PKG_PRODBUILD}"
				else
					echo_stdout "WARN" " something went wrong with PKG_DIST, cannot productbuild : ${PKG_PRODBUILD}";
				fi
			fi
		else
			echo_stdout "WARN" " PKG_DIST DOES NOT EXIST, cannot productbuild : ${PKG_PRODBUILD}";
		fi
	fi
	# Cleanup pkgbuild version, we don't need it.
	rm -Rf "${PKG_PKGBUILD}"
}

IFS=$'\n'

for INPUT_FOLDER in $(find "${WORKING_DIR}" -name "input"); do #eg. /github/autodmg/input
	for PKG_SOURCE in $(find "${INPUT_FOLDER}" -maxdepth 1); do #eg. /github/autodmg/input/Autologin
		IS_INPUT=$(basename "${INPUT_FOLDER}") #eg. input
		INPUT_PARENT=$(dirname "$INPUT_FOLDER") #eg. /github/autodmg
		if [ "$IS_INPUT" == "input" ]; then

			PKG_TO_BUILD=$(basename "${PKG_SOURCE}") #eg. Autologin
			PKG_BUNDLE_ID="${REVERSE_DOMAIN}.${PKG_TO_BUILD}" #eg. com.org.Autologin
			PKG_SCRIPTS="${PKG_SOURCE}/scripts" #eg. /github/autodmg/input/Autologin/scripts

			if [ -d "${PKG_SCRIPTS}" ]; then

				PKG_ROOT="${PKG_SOURCE}/root" #eg. /github/autodmg/input/Autologin/root
				PKG_DIST="${PKG_SOURCE}/distribution.dist" #eg. /github/autodmg/input/Autologin/distribution.dist
				PKG_PKGBUILD="${INPUT_PARENT}/output/${PKG_BUNDLE_ID}.pkg" #eg. /github/autodmg/output/com.org.Autologin.pkg
				PKG_PRODBUILD="${INPUT_PARENT}/output/${PKG_TO_BUILD}.pkg" #eg. /github/autodmg/output/Autologin.pkg
				OUTPUT_DIR="${INPUT_PARENT}/output"
				LOG_DIR="${INPUT_PARENT}/log"
				#output_cmmac="${out_productbuild_pkg}.cmmac"
				#vendor="${PKG_SOURCE}/vendor.plist"
				#echo $PKG_TO_BUILD
				#echo $PKG_BUNDLE_ID
				#echo $PKG_ROOT
				#echo $PKG_SCRIPTS
				#echo $PKG_DIST
				#echo $PKG_PKGBUILD
				#echo $PKG_PRODBUILD
				build_pkgbuild
				#build_vendor_download
				#build_cmmac
			fi
		fi
	done
done

# kick the tyres
#for i in $(find "${INPUT_DIR}" -maxdepth 1); do
#	if [ -d "${i}" ]; then

		#echo $i

		#echo_stdout "    " " BEGIN: ${i}";
		#process_deployments "${i}"
		#echo_stdout "    " " ";
#	fi
#done




















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
