# Class profiles::deploy_from_jenkins
# This class will enable the jenkins master to deploy code to any host on which it is included.
# Currently supports stand-alone only.
#
# Parameters:
#  None
#
# Requires:
# -
#
# Sample Usage:
#   class { 'profiles::deploy_from_jenkins': }
#
# Hiera:
#   profiles::jenkins::plugins:
#     git:
#       version: latest
#
class profiles::deployment (

    $public_key = undef,
    $path       = '/opt/deployment',
    $user       = 'deployment',

  ){

  user { $user:
    ensure         => present,
    home           => $path,
    managehome     => true,
    system         => true,
    purge_ssh_keys => true,
    comment        => 'Automated CI deployment',
  }

  # Create SSH authorized key if we have a public key to use
  if $public_key != undef {
    ssh_authorized_key { 'jenkins':
      user => $user,
      type => 'ssh-rsa',
      key  => $public_key,
    }
  }

  sudo::conf { 'deployment':
    priority => 10,
    content  => "%${user} ALL=(ALL) NOPASSWD: ALL",
  }

}
