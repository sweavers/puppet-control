# Class profiles::firewall
# This class will configures and manages IP tables.
#
# Parameters: #Paramiters accepted by the class
# - none
#
# Requires: #Modules required by the class
# - puppetlabs/firewall
#
# Sample Usage:
# class { 'profiles::firewall': }
#
# Hiera:
# - none NB look ups are required my_fw classes
#
class profiles::firewall (

  $firewall_state = 'off'

  ){

  case $firewall_state {
    'on':{
      # Remove firewalld package and purge its config files
      package { 'firewalld':
        ensure => 'purged'
      }

      # Puppetlabs/firewall
      # ensure furewall is installed and runing
      include ::firewall

      # Remove firewall rules not managed by puppet
      resources { 'firewall' :
        purge   => true,
      }

      # Ensure default pre firewall rules are applied (e.g. ssh)
      class { 'profiles::default_fw::pre' :
        require => Class['firewall']
      }

      # Ensure default post firewall rules are applied (e.g. drop all)
      class { 'profiles::default_fw::post' :
        require => Class['profiles::default_fw::pre']
      }
    }

    default :{
      # Ensure that firewalld service is not running
      service { 'firewalld':
        ensure => stopped,
        enable => false,
      }

      # Ensure that iptables is not running
      service { 'iptables':
        ensure => stopped,
        enable => false,
      }
    }
  }
}
