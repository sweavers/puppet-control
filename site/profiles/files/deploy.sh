#!/usr/bin/env bash
# Deploy tar ball of the /etc/puppet/environments folder (including secrets) for deployment to puppet masters

DIR="/var/lib/jenkins/artifact_r10k"
PUPPETMASTER=${PUPPET_MASTER:-""}
REMOTECI=${REMOTECI:-""}
ARTIFACT=`ls ${DIR}/artifacts/ | sort -n | head -1`

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

for PUPPET in ${PUPPETMASTER} ; do

  # Copy artifact to puppet master
  echo "Attempting to copy ${ARTIFACT} to ${PUPPET}" | output
  scp -o StrictHostKeyChecking=no ${DIR}/artifacts/${ARTIFACT} deployment@${PUPPET}:/tmp/ > /dev/null 2>&1
  if [[ $? == '0' ]]; then
    echo "${ARTIFACT}" successfully copied to ${PUPPET} | output SUCCESS
  else
    echo "Error copying ${ARTIFACT} to ${PUPPET}" | output ERROR && exit 1
  fi

  # SSH to puppet master, stop puppetmaster service, purge existing environments,
  # uncompress artifact and restart puppetmaster service
  ssh -o StrictHostKeyChecking=no deployment@${PUPPET} "sudo systemctl stop puppetmaster-unicorn.service" > /dev/null 2>&1
  [[ $? != '0' ]] && echo "Error stopping puppetmaster service on ${PUPPET}" | output ERROR && exit 1
  ssh deployment@${PUPPET} "sudo rm -rf /etc/puppet/environments" #> /dev/null 2>&1
  [[ $? != '0' ]] && echo "Error purging existing environments on  ${PUPPET}" | output ERROR && exit 1
  ssh -o StrictHostKeyChecking=no deployment@${PUPPET} "sudo tar -C /etc/puppet/ -xzf /tmp/${ARTIFACT}" > /dev/null 2>&1
  [[ $? != '0' ]] && echo "Error extracting artifact on  ${PUPPET}" | output ERROR && exit 1
  ssh -o StrictHostKeyChecking=no deployment@${PUPPET} "sudo systemctl start puppetmaster-unicorn.service" > /dev/null 2>&1
  if [[ $? == '0' ]]; then
    echo "Puppet environment code and dependencies successfully deployed" | output SUCCESS
  else
    echo "Error restarting puppetmaster service on ${PUPPET}" | output ERROR && exit 1
  fi
done

# Copy artifact to remote ci server
for CI in ${REMOTECI} ; do
  echo "Attempting to copy ${ARTIFACT} to ${CI}" | output
  scp -o StrictHostKeyChecking=no ${DIR}/artifacts/${ARTIFACT} deployment@${CI}:${DIR}/artifacts/ > /dev/null 2>&1
  if [[ $? == '0' ]]; then
    echo "${ARTIFACT}" successfully copied to ${CI} | output SUCCESS
  else
    echo "Error copying ${ARTIFACT} to ${CI}" | output ERROR && exit 1
  fi
done
