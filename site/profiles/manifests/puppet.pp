# Class profiles::puppet
#
# This class will manage Puppet Agent and Master installations
#
# Parameters:
#  ['master'] - Boolean.
#
# Requires:
# - Hello
#
# Sample Usage:
#   class { 'profiles::puppet': }
#
class profiles::puppet(

  $master_fqdn   = 'puppet',
  $do_not_manage = false

){

  $environment = hiera( environment , 'production')

  case $do_not_manage{
    default: {
      class { 'profiles::puppet::agent':
        master_fqdn => $master_fqdn
      }
    }
    true: {
      # Do not manage agent with puppet module
      # Reqired for puppet masters
    }
  }
}
