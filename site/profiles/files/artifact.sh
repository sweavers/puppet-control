#!/usr/bin/env bash
# Builds a tar ball of the /etc/puppet/environments folder for deployment to puppet masters

GITREPO=$1
DIR="/etc/artifact_r10k"
TIMESTAMP=$(date +%d%m%Y-%H%M)

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
# Check user is root
[ $(id -u) != 0 ] && echo "ERROR - You must run this script as root!" | output ERROR && exit 1

# Check that a repo has been specified
[ -z "$GITREPO" ] && echo "ERROR - You must specify a source git repo!" | output ERROR && exit 1

# Ensure that /usr/local/bin/ is on root's path
if ! printenv | grep PATH | grep /usr/local/bin/; then
  export PATH=$PATH:/usr/local/bin && echo "Adding /usr/local/bin to PATH" | output SUCCESS
fi

# Check that required commands are installed
for command in git tar puppet r10k; do
  if ! type "${command}" > /dev/null 2>&1 ; then
    echo >&2 "ERROR - You must have ${command} installed to run this script" | output ERROR && exit 1
  fi
done

# Ensure that artifact_r10k configuration is in place
rm -rf /etc/artifact_r10k.yaml
cat > /etc/artifact_r10k.yaml <<EOF
:cachedir: /var/cache/artifact_r10k
:sources:
  control:
    basedir: ${DIR}/environments
    prefix: false
    remote: ${GITREPO}
:purgedirs:
  - ${DIR}/environments
EOF

if [[ $? == '0' ]]; then
  echo "Created /etc/artifact_r10k.yaml" | output SUCCESS
else
  echo "Error creating /etc/artifact_r10k.yaml" | output ERROR && exit 1
fi

# Run R10k to get puppet code from github and dependency modules from the puppet forge
echo "Attempting to retrive puppet environment code and dependencies" | output SUCCESS
r10k deploy environment -c /etc/artifact_r10k.yaml > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Puppet environment code and dependencies successfully retrieved" | output SUCCESS
else
  echo "Error retriving puppet environment code and or dependencies" | output ERROR && exit 1
fi

# Enssure that target artifact directory exits
if [ ! -d ${DIR}/artifacts ] ; then
  mkdir -p ${DIR}/artifacts
fi

# Create compressed tar archive of the puppet enviroment code and dependancies
echo "Attempting to create artifact" | output SUCCESS

tar -C ${DIR} -czf ${DIR}/artifacts/${TIMESTAMP}.tgz environments/ > /dev/null 2>&1
if [[ $? == '0' ]]; then
  echo "Artifact successfully created" | output SUCCESS && exit 0
else
  echo "Error creating artifact" | output ERROR && exit 1
fi
