secret_repo=$1

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
for d in /etc/puppet/environments/* ; do

  e=`basename $d`

  echo "environment is $e"

  #check if secrest folder exists....
  echo "checking to see if $d/secrets  exists..."
  if [  -d "$d/secrets" ]; then

    # delete the directory if it does...
    echo "...yup cleaning up old $d/secrets"
    rm -rf $d/secrets
  fi

  #re-create the secrets directory
  echo "creating new $d/secrets dir"
  mkdir $d/secrets

  #clone the secrets repo to the secrets folder
  echo "cloning the secrets repo"
  #cd $d/secrets
  git -C $d/secrets clone $secret_repo

  #check to see if branch exists in secrets for this environment
  echo "checking to see if a secrets brach exists for this environment"
  if [ -n `git -C $d/secrets/puppet-secrets branch --list $e` ]; then

    #check out environment branch
    echo "checking out the secret repo branch for $e"
    git -C $d/secrets/puppet-secrets checkout $e

    #move the secrets to the environment's 'hiera' folder
    mv -f $d/secrets/puppet-secrets/* $d/hiera/
  else
   echo "no secrets brach exists for $e"
  fi

  #clean up
  rm -rf $d/secrets/
done
