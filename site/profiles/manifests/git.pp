# Class profiles::git
#
# Will install git on a node.
#
# Sample Usage:
#   class { 'profiles::git': }
#
class profiles::git {

  # Install custom git build
  if ! defined(Package['git']) {
    package{ 'git' :
      ensure   => installed,
    }
  }
}
