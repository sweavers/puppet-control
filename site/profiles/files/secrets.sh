#!/usr/bin/env bash
# Pulls secrets from a private repository and merges them into the Hiera tree

SECRETS=$1
TEMPDIR="/tmp/secrets-$(date +%s)"
OUTPUT_LABEL='deploy-secrets'

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

# Check user is root
[ $(id -u) != 0 ] && echo "ERROR - You must run this script as root!" | output ERROR && exit 1

# Check that a repo has been specified
[ -z "$SECRETS" ] && echo "ERROR - You must specify a secrets repository!" | output ERROR && exit 1

# Make sure we actually have Puppet environments set up
#[ ! -d /etc/puppet/environments ] && echo "/etc/puppet/environments does not exist!" | output ERROR && exit 1

echo "Deploying secrets from ${SECRETS}" | output
git clone ${SECRETS} ${TEMPDIR} 2>&1 | output

for environment in ./etc/puppet/environments/*; do
  envname=$(basename ${environment})

  # Clean up old secrets directory or create new one
  if [ -d "${environment}/secrets" ]; then
    echo "Purging secrets from ${envname}" | output
    rm -rf ${environment}/secrets/*
  else
    mkdir ${environment}/secrets
  fi

  # Check to see if branch exists in secrets repository that matches environment
  if [[ -n $(git -C ${TEMPDIR} branch --list ${envname}) ]]; then
    # Check out environment branch
    git -C ${TEMPDIR} checkout ${envname} 2>&1 >/dev/null | output
    # Deploy new secrets
    cp -R ${TEMPDIR}/* ${environment}/secrets/
    if [ $? == '0' ]; then
      echo "New secrets deployed to ${envname}" | output
    else
      echo "ERROR - Unable to deploy secrets from ${TEMPDIR} to ${environment}" | output ERROR
      SOFTFAIL+=("${envname}")
      break # Skip to next environment
    fi
  else
    echo "No secrets available for ${envname}" | output
  fi

done


# This is a little hacky but provides good visibilty of failures
if [ ! -z $SOFTFAIL ]; then
  echo "ERROR - Did not successfully complete deployment!" | output ERROR
  failures=$(printf ", %s" "${SOFTFAIL[@]}"); failures=${failures:1}
  echo "Failed to deploy to:${failures}" | output ERROR
  exit 1;
else
  # We only want to clean up if we exit cleanly, to aid debugging on fail
  echo "Removing temporary directory at ${TEMPDIR}" | output
  rm -rf ${TEMPDIR} 2>&1 >/dev/null

  # :wq
  echo "Deployment completed successfully!" | output SUCCESS
  exit 0
fi
