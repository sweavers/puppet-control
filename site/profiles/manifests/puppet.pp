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

  $master_fqdn = 'puppet',
  $environment = 'production'

){

  class { 'profiles::puppet::agent':
    master_fqdn => $master_fqdn,
    environment => $environment
  }

}
