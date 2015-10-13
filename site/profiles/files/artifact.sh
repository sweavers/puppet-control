#!/usr/bin/env bash
# Builds a tar ball of the /etc/puppet/environments folder (including secrets) for deployment to puppet masters

GITREPO=$1
SECRETS=$2
DIR="/var/lib/jenkins/artifact_r10k"
TIMESTAMP=$(date +%Y%m%d-%H%M)
USAGE=`basename $0`" [GITREPO] [SECRETS_REPO]"
TEMPDIR="/tmp/secrets-$(date +%s)"
HIERA_PATH="hiera/secrets"
OUTPUT_LABEL='deploy-secrets'
R10KCONFDIR="/var/lib/jenkins/artifact_r10k"

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

# Check that a git repo has been specified
[ -z "$GITREPO" ] && echo -e "ERROR - You must specify a source git repo! \n Usage: ${USAGE}" | output ERROR && exit 1

# Check that a secrets repo has been specified
[ -z "$SECRETS" ] && echo -e "ERROR - You must specify a secrets repo! \n Usage: ${USAGE}" | output ERROR && exit 1

# Ensure that /usr/local/bin/ is on root's path
if ! printenv | grep PATH | grep /usr/local/bin/; then
  export PATH=$PATH:/usr/local/bin && echo "Adding /usr/local/bin to PATH" | output
fi

# Check that required commands are installed
for command in git tar puppet r10k; do
  if ! type "${command}" > /dev/null 2>&1 ; then
    echo >&2 "ERROR - You must have ${command} installed to run this script" | output ERROR && exit 1
  fi
done

# Enssure that target artifact directory exits
if [ ! -d ${DIR}/artifacts ] ; then
  mkdir -p ${DIR}/artifacts
fi

# Ensure that artifact_r10k configuration is in place
rm -rf ${R10KCONFDIR}/artifact_r10k.yaml
cat > ${R10KCONFDIR}/artifact_r10k.yaml <<EOF
:cachedir: ${DIR}/cache
:sources:
  control:
    basedir: ${DIR}/environments
    prefix: false
    remote: ${GITREPO}
:purgedirs:
  - ${DIR}/environments
EOF

if [[ $? == '0' ]]; then
  echo "Created ${R10KCONFDIR}/artifact_r10k.yaml" | output SUCCESS
else
  echo "Error creating ${R10KCONFDIR}/artifact_r10k.yaml" | output ERROR && exit 1
fi

# Run R10k to get puppet code from github and dependency modules from the puppet forge
echo "Attempting to retrive puppet environment code and dependencies" | output
r10k deploy environment -c ${R10KCONFDIR}/artifact_r10k.yaml -p > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Puppet environment code and dependencies successfully retrieved" | output SUCCESS
else
  echo "Error retriving puppet environment code and or dependencies" | output ERROR && exit 1
fi

# Use git to pull secrests from secrets repo
echo "Attempting to retrive secrets" | output
git clone ${SECRETS} ${TEMPDIR} 2>&1 | output

for environment in ${DIR}/environments/*; do
  envname=$(basename ${environment})

  # Clean up old secrets directory or create new one
  if [ -d "${environment}/${HIERA_PATH}" ]; then
    echo "Purging previous secrets from ${envname}" | output
    rm -rf ${environment}/${HIERA_PATH}/*
  else
    mkdir ${environment}/${HIERA_PATH}
  fi

  # Check to see if branch exists in secrets repository that matches environment
  # -C option not available on version of git included with CentOS7
  #git -C ${TEMPDIR} checkout ${envname} >/dev/null 2>&1
  cd ${TEMPDIR}
  git checkout ${envname} >/dev/null 2>&1
  if [[ $? == '0' ]]; then
    # Deploy new secrets
    cp -R ${TEMPDIR}/* ${environment}/${HIERA_PATH}
    if [ $? == '0' ]; then
      echo "New secrets deployed to ${envname}" | output
    else
      echo "ERROR - Unable to deploy secrets from ${TEMPDIR} to ${environment}" | output ERROR
      SOFTFAIL+=("${envname}")
      break # Skip to next environment
    fi
  else
    echo "No secrets available for ${envname}" | output WARN
  fi

done

# Purge temp secrets directory
#rm -rf ${TEMPDIR} 2>&1 >/dev/null

# Create compressed tar archive of the puppet enviroment code and dependancies
echo "Attempting to create artifact" | output
tar -C ${DIR} -czf ${DIR}/artifacts/${TIMESTAMP}.tgz environments/ > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Artifact successfully created" | output SUCCESS && exit 0
else
  echo "Error creating artifact" | output ERROR && exit 1
fi
