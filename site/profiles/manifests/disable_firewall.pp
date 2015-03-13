# Class profiles::disable_firewall
# This class will disable firewalld on Centos/RHEL7.
#
# Parameters: #Paramiters accepted by the class
# N/A
#
# Requires: #Modules required by the class
# - N/A
#
# Sample Usage:
# class { 'profiles::disable_firewall': }
#
# Hiera:
#   N/A
#
class profiles::disable_firewall {

  case $::osfamily{
    'RedHat': {
      service { 'firewalld':
        ensure => stopped,
        enable => false,
      }
    }
    default: {
      notify{'Firewall only disabled for RHEL based systems': }
    }
  }
}
