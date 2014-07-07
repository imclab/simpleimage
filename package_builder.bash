#!/bin/bash

#+ automates pkgbuild/productbuild/cmmac builds

declare -r REVERSE_DOMAIN="com.org"					# reverse domain for bundle ids etc.
declare -r PACKAGE_VERSION=$(date +"%Y%m%d%H%M%S")	# dynamic version number based on the date !important, used in detection
declare -r WORKING_DIR=$(dirname "${0}")			# directory: working directory
IFS=$'\n'

function echo_stdout
{
  [[ ${1} == "DIST" ]] && echo "[   ${1}   ] ${2}"
  [[ ${1} == "INFO" ]] && echo "[   ${1}   ] ${2}"
  #[[ ${1} == "SKIP" ]] && echo "[   ${1}   ] ${2}"
  #[[ ${1} == "WARN" ]] && echo "[   ${1}   ] ${2}"
  [[ -e ${log_dir} ]] && echo $(date +"%Y%m%d-%H-%M-%S") >> "${log_dir}/DEBUG.log"
  [[ -e ${log_dir} ]] && echo "[   ${1}   ] ${2}" >> "${log_dir}/DEBUG.log"
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

# sha1 checksum
# 1 args: path
# !think about using it in err checking
function checksum
{
    openssl sha1 "${1}" >> "${log_dir}/${pkg_to_build}.log"
}

function search_input  #eg. ./input
{
  for input_folder in $(find "${WORKING_DIR}" -type d -name "${1}"); do
    echo_stdout "INFO" " searching ${input_folder}";
    search_pkg_template "${1}"
  done
}

function search_pkg_template #eg. ./input/Autologin
{
  for pkg_source in $(find "${input_folder}" -type d -maxdepth 1); do
    is_in_input=$(basename "${input_folder}") #eg. input
    if [ "$is_in_input" == "${1}" ]; then
      sudo chmod -R 755 "${input_folder}"  #eg. ./input
      input_parent=$(dirname "$input_folder") #eg. ./autodmg
      log_dir="${input_parent}/log"
      mkdir -p "${log_dir}" #eg. ./log
      check_pkg_scripts
    fi
  done
}

function check_out_pkg
{
  echo test
}

function check_pkg_scripts #eg. ./input/Autologin/scripts
{
  pkg_scripts="${pkg_source}/scripts"
  if (path_exists "${pkg_scripts}"); then
    echo_stdout "INFO" " found ${pkg_source}"
    check_pkg_postinstall
  else
    echo_stdout "WARN" " no scripts found ${pkg_scripts}"
  fi
}

function check_pkg_postinstall #eg. ./input/Autologin/scripts/postinstall
{
  pkg_postinstall="${pkg_source}/scripts/postinstall"
  if (path_exists "${pkg_postinstall}"); then
    echo_stdout "INFO" " found ${pkg_postinstall}"
    check_pkg_preinstall
  else
    echo_stdout "WARN" " no postinstall found ${pkg_postinstall}"
  fi
}

function check_pkg_preinstall #eg. ./input/Autologin/scripts/preinstall
{
  pkg_preinstall="${pkg_source}/scripts/preinstall"
  if (path_exists "${pkg_preinstall}"); then
    echo_stdout "INFO" " found ${pkg_preinstall}"
    process_pkgbuild
  else
    echo_stdout "WARN" " no preinstall found ${pkg_preinstall}"
  fi
}

# simplify this one by splittling out the nested IF when you get time
function process_pkgbuild {
  pkg_to_build=$(basename "${pkg_source}") #eg. Autologin
  pkg_bundle_id="${REVERSE_DOMAIN}.${pkg_to_build}" #eg. com.org.Autologin
  pkg_root="${pkg_source}/root" #eg. ./input/Autologin/root
  if (path_exists "${pkg_root}"); then
    pkg_prodbuild="${input_parent}/${pkg_to_build}.pkg" #eg. ./Autologin.pkg
    if (path_exists "${pkg_prodbuild}"); then
      echo_stdout "SKIP" " pkg_prodbuild exists ${pkg_pkgbuild}"
    else
      echo_stdout "INFO" " found ${pkg_root}"
      output_dir="${input_parent}" #eg. ./
      mkdir -p "${output_dir}"
      process_pkgbuild_source
    fi
  else
    pkg_prodbuild="${input_parent}/${pkg_to_build}.pkg" #eg. ./Autologin.pkg
    if (path_exists "${pkg_prodbuild}"); then
      echo_stdout "SKIP" " pkg_prodbuild exists ${pkg_pkgbuild}"
    else
      echo_stdout "WARN" " no root found ${pkg_root}"
      output_dir="${input_parent}" #eg. ./
      mkdir -p "${output_dir}"
      process_pkgbuild_tempate_nopayload
    fi
  fi
  process_productbuild
}


function process_pkgbuild_source {
  pkg_pkgbuild="${input_parent}/${pkg_bundle_id}.pkg" #eg. ./com.org.Autologin.pkg
  if (path_exists "${pkg_pkgbuild}"); then
    echo_stdout "SKIP" " pkgbuild exists ${pkg_pkgbuild}"
  else
    echo_stdout "PKG" " pkgbuild with payload ${pkg_bundle_id}"
    pkgbuild \
    --identifier "${pkg_bundle_id}" \
    --root "${pkg_root}" \
    --scripts "${pkg_scripts}" \
    --version "${PACKAGE_VERSION}" \
    "${pkg_pkgbuild}" >> "${log_dir}/${pkg_to_build}.log"
  fi
}

function process_pkgbuild_tempate_nopayload {
  pkg_pkgbuild="${input_parent}/${pkg_bundle_id}.pkg" #eg. ./com.org.Dockfixup.pkg
  if (path_exists "${pkg_pkgbuild}"); then
    echo_stdout "SKIP" " pkgbuild exists ${pkg_pkgbuild}"
  else
    echo_stdout "PKG" " pkgbuild payload free ${pkg_bundle_id}"
    pkgbuild --identifier "${pkg_bundle_id}" \
    --nopayload --scripts "${pkg_scripts}" \
    --version "${PACKAGE_VERSION}" \
    "${pkg_pkgbuild}" >> "${log_dir}/${pkg_to_build}.log"
    checksum "${pkg_pkgbuild}"
  fi
}

function use_distribution_template {
cat > "${input_folder}/${pkg_to_build}/distribution.dist" << EOPROFILE
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<installer-gui-script minSpecVersion="1">
    <options customize="never" rootVolumeOnly="true"/>
    <pkg-ref id="${pkg_bundle_id}">
        <bundle-version/>
    </pkg-ref>
    <options customize="never" require-scripts="false"/>
    <choices-outline>
        <line choice="default">
            <line choice="${pkg_bundle_id}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${pkg_bundle_id}" visible="false">
        <pkg-ref id="${pkg_bundle_id}"/>
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
    <pkg-ref id="${pkg_bundle_id}" onConclusion="none">${pkg_bundle_id}.pkg</pkg-ref>
</installer-gui-script>
EOPROFILE
}

function process_productbuild {
  if (path_exists "${pkg_prodbuild}"); then
    echo_stdout "SKIP" " productbuild exists ${pkg_prodbuild}"
  else
    process_productbuild_dist
  fi
}

function process_productbuild_dist {
  pkg_dist="${pkg_source}/distribution.dist" #eg. ./input/Autologin/distribution.dist
  if (path_exists "${pkg_dist}"); then
    echo_stdout "INFO" " found custom DIST ${pkg_dist}";
    echo_stdout "DIST" " productbuild ${pkg_prodbuild}";
    productbuild --distribution "${pkg_dist}" \
    --package-path "${output_dir}" \
    "${pkg_prodbuild}" >> "${log_dir}/${pkg_to_build}.log"
  else
    echo_stdout "WARN" " custom DIST not found, using generic template ${pkg_prodbuild}";
    use_distribution_template
    echo_stdout "DIST" " productbuild ${pkg_prodbuild}";
    productbuild --distribution "${pkg_dist}" \
    --package-path "${output_dir}" \
    "${pkg_prodbuild}" >> "${log_dir}/${pkg_to_build}.log"
    sudo rm -Rf "${pkg_dist}"
  fi
  checksum "${pkg_prodbuild}"
  rm -Rf "${pkg_pkgbuild}"
}

clear

#++ must sudo
if [[ $(id -u) -ne 0 ]]; then
  echo "Run this script with sudo, just to be safe."
  exit 1
fi

if [[ ${1} == "--log" ]]; then
  LOG=1
fi

echo_stdout "BUILD" " $(date +%Y%m%d-%H-%M-%S)"
search_input "package_builder"

chown -R root:admin "${log_dir}"
chmod -R 777 "${log_dir}"
if [[ ${LOG} != 1 ]]; then
    rm -R "${log_dir}"
fi

exit 0



































# TAKE ANOTHER LOOK AT THIS IF WE GO TO SCCM

# setup environment
#for d in "${INPUT_DIR}" "${log_dir}" "${OUTPUT_DIR}"; do
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
      ditto "/Volumes/${vendor_volume}/${vendor_payload}" "${build_root}/${vendor_target}/${vendor_payload}" >> "${log_dir}/${application}.log"
      vendor_disk=$(df -k | grep "${vendor_volume}" | awk '{print $1}')
      hdiutil detach "${vendor_disk}" -force
    else
      if [ "${vendor_type}" == "zip" ]; then
        ditto -V -x -k --sequesterRsrc --rsrc "${build_root}/vendor.${vendor_type}" "${build_root}/${vendor_target}/" >> "${log_dir}/${application}.log"
      fi
    fi
    build_version=$(defaults read "${build_root}/${vendor_target}/${vendor_payload}/Contents/info.plist" CFBundleShortVersionString)

    # !think about naming versions
    #out_pkgbuild_pkg="${OUTPUT_DIR}/${bundle_identifier}${build_version}.pkg"
    #out_productbuild_pkg="${OUTPUT_DIR}/${bundle_identifier}${build_version}.dist.pkg"
    #output_cmmac="${out_productbuild_pkg}.cmmac"

    sudo rm -Rf "${build_root}/vendor.${vendor_type}"

    #rm -Rf "${INPUT_DIR}/${application}/root"
    #rm -Rf "${INPUT_DIR}/${application}/scripts"
    # add key for option to go straight to cmmac from dmg or pkg + key to do custom build too
  fi
fi
}

exit 0
