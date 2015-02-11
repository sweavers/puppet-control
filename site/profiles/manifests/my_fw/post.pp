# Class profiles::my_fw::post
# This class configures default firewall rules to be applied last
#
# Parameters: #Paramiters accepted by the class
# N/A
#
# Requires: #Modules required by the class
# - puppetlabs/firewall
#
# Sample Usage:
# class { 'profiles::firewall': }
#
# Hiera:
# N/A
#

class profiles::my_fw::post {
  firewall { '999 drop all':
    proto  => 'all',
    action => 'drop',
    before => undef,
  }
}
