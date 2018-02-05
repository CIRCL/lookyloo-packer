#!/usr/bin/env bash

# Latest version of Lookyloo
##VER=$(curl -s https://api.github.com/repos/CIRCL/lookyloo/tags  |jq -r '.[0] | .name')
VER='master'
# Latest commit hash of Lookyloo
LATEST_COMMIT=$(curl -s https://api.github.com/repos/CIRCL/lookyloo/commits  |jq -r '.[0] | .sha')
# Update time-stamp and make sure file exists
touch /tmp/lookyloo-latest.sha
# SHAsums to be computed
SHA_SUMS="1 256 384 512"

# Configure your user and remote server
REL_USER="lookyloo-release"
REL_SERVER="cpab"

# Place holder, this fn() should be used to anything signing related
function signify()
{
if [ -z "$1" ]; then
  echo "This function needs an arguments"
  exit 1
fi

}

# Check if latest build is still up to date, if not, roll and deploy new
if [ "${LATEST_COMMIT}" != "$(cat /tmp/lookyloo-latest.sha)" ]; then

  echo "Current Lookyloo version is: ${VER}@${LATEST_COMMIT}"

  # Search and replace for vm_name and make sure we can easily identify the generated VMs
  cat lookyloo.json| sed "s|\"vm_name\": \"Lookyloo_demo\",|\"vm_name\": \"LOOKY_${VER}@${LATEST_COMMIT}\",|" > lookyloo-deploy.json

  # Build virtualbox VM set
  /usr/local/bin/packer build -only=virtualbox-iso lookyloo-deploy.json

  # Build vmware VM set
  /usr/local/bin/packer build -only=vmware-iso lookyloo-deploy.json

  # ZIPup all the vmware stuff
  zip -r LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip  packer_vmware-iso_vmware-iso_sha1.checksum packer_vmware-iso_vmware-iso_sha512.checksum output-vmware-iso

  # Create a hashfile for the zip
  for SUMsize in `echo ${SHA_SUMS}`; do
    shasum -a ${SUMsize} *.zip > LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip.sha${SUMsize}
  done


  # Current file list of everything to gpg sign and transfer
  FILE_LIST="LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip output-virtualbox-iso/LOOKY_${VER}@${LATEST_COMMIT}.ova packer_virtualbox-iso_virtualbox-iso_sha1.checksum packer_virtualbox-iso_virtualbox-iso_sha256.checksum packer_virtualbox-iso_virtualbox-iso_sha384.checksum packer_virtualbox-iso_virtualbox-iso_sha512.checksum LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip.sha1 LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip.sha256 LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip.sha384 LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip.sha512"

  # Create the latest Looky export directory
  ##ssh ${REL_USER}@${REL_SERVER} mkdir -p export/LOOKY_${VER}@${LATEST_COMMIT}

  # Sign and transfer files
  for FILE in ${FILE_LIST}; do
    gpg --armor --output ${FILE}.asc --detach-sig ${FILE}
    ##rsync -azv --progress ${FILE} ${REL_USER}@${REL_SERVER}:export/LOOKY_${VER}@${LATEST_COMMIT}
    ##rsync -azv --progress ${FILE}.asc ${REL_USER}@${REL_SERVER}:export/LOOKY_${VER}@${LATEST_COMMIT}
    ##ssh ${REL_USER}@${REL_SERVER} rm export/latest
    ##ssh ${REL_USER}@${REL_SERVER} ln -s LOOKY_${VER}@${LATEST_COMMIT} export/latest
    ##ssh ${REL_USER}@${REL_SERVER} chmod -R +r export
  done

  ##ssh ${REL_USER}@${REL_SERVER} cd export ; tree -T "Lookyloo VM Images" -H https://www.circl.lu/lookyloo-images/ -o index.html

  # Remove files for next run
  ##rm -r output-virtualbox-iso
  ##rm -r output-vmware-iso
  ##rm *.checksum *.zip *.sha*
  rm lookyloo-deploy.json
  ##rm packer_virtualbox-iso_virtualbox-iso_sha1.checksum.asc
  ##rm packer_virtualbox-iso_virtualbox-iso_sha256.checksum.asc
  ##rm packer_virtualbox-iso_virtualbox-iso_sha384.checksum.asc
  ##rm packer_virtualbox-iso_virtualbox-iso_sha512.checksum.asc
  ##rm LOOKY_${VER}@${LATEST_COMMIT}-vmware.zip.asc
  echo ${LATEST_COMMIT} > /tmp/lookyloo-latest.sha
else
  echo "Current Lookyloo version ${VER}@${LATEST_COMMIT} is up to date."
fi
