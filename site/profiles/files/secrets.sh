#!/usr/bin/env bash
# Pulls secrets from a private repository and merges them into the Hiera tree

SECRETS=$1

# Check user is root
if [ $(id -u) != 0 ]; then
  echo "You must run this script as root!"
  exit 1
fi

# Check that a repo has been specified
if [ -z "$1" ]; then
  echo "You must specify a secrets repo"
  exit 1
fi


# for each subdirectory of 'environments'....
for environment in /etc/puppet/environments/* ; do

  e=`basename $environment`

  echo "Environment is $e"

  #check if secrest folder exists....
  echo "checking to see if $environment/secrets  exists..."
  if [  -d "${environment}/secrets" ]; then

    # delete the directory if it does...
    echo "...yup cleaning up old ${environment}/secrets"
    rm -rf ${environment}/secrets
  fi

  #re-create the secrets directory
  echo "creating new ${environment}/secrets dir"
  mkdir ${environment}/secrets

  #clone the secrets repo to the secrets folder
  echo "cloning the secrets repo"
  #cd ${environment}/secrets
  git -C ${environment}/secrets clone ${SECRETS}

  #check to see if branch exists in secrets for this environment
  echo "checking to see if a secrets brach exists for this environment"
  if [ -n `git -C ${environment}/secrets/puppet-secrets branch --list $e` ]; then

    #check out environment branch
    echo "checking out the secret repo branch for $e"
    git -C ${environment}/secrets/puppet-secrets checkout $e

    #move the secrets to the environment's 'hiera' folder
    mv -f ${environment}/secrets/puppet-secrets/* ${environment}/hiera/
  else
   echo "no secrets brach exists for $e"
  fi

  #clean up
  rm -rf ${environment}/secrets/
done
