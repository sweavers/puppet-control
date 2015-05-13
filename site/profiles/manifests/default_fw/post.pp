# Class profiles::default_fw::post
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
# <EXAMPLE OF ANY REQUIRED HIERA STRUCTURE>
#

class profiles::default_fw::post {
  firewall { '999 drop all':
    proto  => 'all',
    action => 'drop',
    before => undef,
  }
}
