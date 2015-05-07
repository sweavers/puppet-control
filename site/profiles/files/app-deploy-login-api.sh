#!/usr/bin/env bash
# Create and deploy a tar ball containing beta application code

GITREPO=${GITREPO:-""}
APPNAME=`echo $GITREPO | cut -d "/" -f2 | cut -d "." -f1`
TARGETSERVER=${TARGETSERVER:-""}
BRANCH=${BRANCH:-""}
LOCALDIR="/tmp/"
TARGETDIR="/opt/deployment/${APPNAME}"

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

# Clone GITREPO to LOCALDIR
echo "Attempting to clone ${GITREPO}" | output
git clone -b ${BRANCH} ${GITREPO} ${LOCALDIR}${APPNAME} --single-branch > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Successfully cloned ${GITREPO}" | output SUCCESS
else
  echo "Error creating cloning ${GITREPO}" | output ERROR && exit 1
fi

# Create compressed tar archive of the git repo
echo "Attempting to create code artifact" | output
tar -C ${LOCALDIR}/${APPNAME} -czf ${APPNAME}.tgz . > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Code artifact successfully created" | output SUCCESS
else
  echo "Error creating code artifact" | output ERROR && exit 1
fi

# Copy tar archive to TARGETSERVER
echo "Attempting to copy code artifact to ${TARGETSERVER}" | output
scp ${APPNAME}.tgz deployment@${TARGETSERVER}:/tmp/ > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Successfully copied code artifact to ${TARGETSERVER}" | output SUCCESS
else
  echo "Error copying code artifact to ${TARGETSERVER}" | output ERROR && exit 1
fi

# SSH to TARGETSERVER,
echo "Attempting to deploy code artifact on ${TARGETSERVER}" | output
# Stop log-in service
ssh deployment@${TARGETSERVER} "sudo systemctl stop login-api" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error stopping monit service on ${TARGETSERVER}" | output ERROR #&& exit 1

# Ensure 'prev-ver' directory exists and is purged on TARGETSERVER
ssh deployment@${TARGETSERVER} "if [ ! -d /opt/deployment/prev-ver ] ; then sudo mkdir -p /opt/deployment/prev-ver ; else sudo rm -rf /opt/deployment/prev-ver/* ; fi" #> /dev/null 2>&1
[[ $? != '0' ]] && echo "Error creating or purging 'prev-ver' directory on ${TARGETSERVER}" | output ERROR && exit 1

# Ensure TARGETDIR directory exists on TARGETSERVER
ssh deployment@${TARGETSERVER} "if [ ! -d ${TARGETDIR} ] ; then sudo mkdir -p ${TARGETDIR} ; else exit 0 ; fi" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error creating or creating ${TARGETDIR} on ${TARGETSERVER}" | output ERROR && exit 1

# Move any existing code to 'prev-ver' folder
ssh deployment@${TARGETSERVER} "sudo mv ${TARGETDIR}/* /opt/deployment/prev-ver/" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error moving existing code to 'pre-ver' ${TARGETSERVER}" | output ERROR #&& exit 1

# Untar artifact from /tmp to TARGETDIR
ssh deployment@${TARGETSERVER} "sudo tar -C ${TARGETDIR} -xzf /tmp/${APPNAME}.tgz" > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Code artifact successfully deployed to ${TARGETSERVER}" | output SUCCESS
else
  echo "Error unpacking ${APPNAME}.tgz on ${TARGETSREVER}" | output ERROR && exit 1
fi

# Re-start monitd service
echo "Attempting to restart login-api service" | output
ssh deployment@${TARGETSERVER} "sudo systemctl start login-api" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error re-starting monitd service on ${TARGETSERVER}" | output ERROR #&& exit 1

# Clean up
echo "Cleaning up" | output
ssh deployment@${TARGETSERVER} "sudo rm -rf /tmp/${APPNAME}.tgz/" > /dev/null 2>&1
[[ $? != '0' ]] && echo "Error cleaning up /tmp/${APPNAME}.tgz on ${TARGETSERVER}" | output WARN
rm ${APPNAME}.tgz
[[ $? != '0' ]] && echo "Error cleaning up /tmp/${APPNAME}.tgz on local machine" | output WARN
rm -rf ${LOCALDIR}${APPNAME}
[[ $? != '0' ]] && echo "Error cleaning up ${LOCALDIR}${APPNAME} on local machine" | output WARN
exit 0
