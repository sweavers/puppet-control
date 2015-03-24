#!/usr/bin/env bash
# Create and deploy a tar ball containing beta application code

GITREPO=${GITREPO:-""}
TARGETSERVER=${TARGETSERVER:-""}
LOCALDIR="/tmp/${GITREPO}"
TARGETDIR="/var/deployment/${GITREPO}"

# Purely cosmetic function to prettify output
# Set OUTPUT_LABEL to change the label
# Supports ERROR, SUCCESS, and WARN as arguments
function output() {
local label=${OUTPUT_LABEL:-$0}
local timestamp=$(date +%d/%m/%Y\ %H:%M)
local colour='\033[34m' # Blue
local reset='\033[0m'
case $1 in
ERROR) local colour='\033[31m' ;; # Red
SUCCESS) local colour='\033[32m' ;; # Green
WARN) local colour='\033[33m' ;; # Yellow
esac
while read line; do
echo -e "${colour}${label} [${timestamp}]${reset} ${line}"
done
}

# Check prerequisits
# Check user is root - currently disabled as script is now configured to run as un unpriv user
#[ $(id -u) != 0 ] && echo "ERROR - You must run this script as root!" | output ERROR && exit 1

# Clean up old LOCALDIR or create new one
if [ -d "${LOCALDIR}" ]; then
  echo "Purging old code from ${LOCALDIR}" | output
  rm -rf ${LOCALDIR}/*
else
  echo "Creating ${LOCALDIR}" | output
  mkdir -p ${LOCALDIR}
fi

# Clone GITREPO to LOCALDIR
echo "Attempting to clone ${GITREPO}" | output
git clone ${GITREPO} ${LOCALDIR}
if [[ $? == '0' ]]; then
  echo "Successfully cloned ${GITREPO}" | output SUCCESS && exit 0
else
  echo "Error creating cloning ${GITREPO}" | output ERROR && exit 1
fi

# Create compressed tar archive of the git repo
echo "Attempting to create code artifact" | output
tar -C ${LOCALDIR} -czf ${GITREPO}.tgz ${GITREPO}/ > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Code artifact successfully created" | output SUCCESS && exit 0
else
  echo "Error creating code artifact" | output ERROR && exit 1
fi

# Copy tar archive to TARGETSERVER
echo "Attempting to copy code artifact to ${TARGETSERVER}" | output
scp ${LOCALDIR}/${GITREPO}.tgz deployment@${TARGETSERVER}/tmp
if [[ $? == '0' ]]; then
  echo "Successfully copied code artifact to ${TARGETSERVER}" | output SUCCESS && exit 0
else
  echo "Error copying code artifact to ${TARGETSERVER}" | output ERROR && exit 1
fi

# SSH to TARGETSERVER,
#stop monitd service
ssh deployment@${TARGETSERVER} "sudo service monitd stop" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error stopping monitd service on ${TARGETSEVER}" | output ERROR && exit 1

# Ensure 'prev-ver' directory exists and is purged on TARGETSERVER
ssh deployment@${TARGETSERVER} "sudo if [ ! -d /var/deployment/prev-ver ]; \
then sudo mkdir -p /var/deployment/prev-ver; \
else rm -rf /var/deployment/prev-ver" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error creating or purging 'prev-ver' directory on ${TARGETSEVER}" | output ERROR && exit 1

# Move existing code to 'prev-ver' folder
ssh deployment@${TARGETSERVER} "sudo mv ${TARGETDIR}/* /var/deployment/prev-ver/" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error moving existing code to 'pre-ver' ${TARGETSEVER}" | output ERROR && exit 1

# Untar artifact from /tmp to TARGETDIR
ssh deployment@${TARGETSERVER} "sudo tar -C ${TARGETDIR} -xzf /tmp/${GITREPO}.tgz/" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error unpacking ${GITREPO}.tgz on ${TARGETSEVER}" | output ERROR && exit 1

# Re-start monitd service
ssh deployment@${TARGETSERVER} "sudo service monitd start" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error re-starting monitd service on ${TARGETSEVER}" | output ERROR && exit 1

# Clean up
ssh deployment@${TARGETSERVER} "sudo rm -rf /tmp/${GITREPO}.tgz/" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error cleaning up /tmp/${GITREPO}.tgz on ${TARGETSEVER}" | output WARN

# Test service
ssh deployment@${TARGETSERVER} "curl localhost" > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Application code successfully deployed to ${TARGETSEVER}" | output SUCCESS
else
  echo "Cannot access application service on ${TARGETSEVER}" | output ERROR && exit 1
fi
