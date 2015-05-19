# Class profiles::firewall
# This class will configures and manages IP tables if firewall state is 'on'.
#
# Parameters: #Paramiters accepted by the class
# - [firewall_state] - Sets the firewall on or off
# - [ssh_allowed_range] - Source address range for allowed ssh connections
# - [services] - A hash containing the details of allowed services
#
# Requires: #Modules required by the class
# - N/A
#
# Sample Usage:
# class { 'profiles::firewall': }
#
# Hiera:
#   profiles::firewall::firewall_state: 'on'
#   profiles::firewall::ssh_allowed_range: '0.0.0.0/0'
#   profiles::firewall::services:
#     HTTP: 80
#
#
class profiles::firewall (

  $firewall_state    = 'off',
  $ssh_allowed_range = '0.0.0.0/0',
  $services          = {}

  ){

    case $firewall_state {
      'on':{
        # Disable and remove firewalld
        service { 'firewalld':
          ensure => stopped,
          enable => false,
        }
        package { 'firewalld':
          ensure => purged
        }

        # Install and enable IP tables
        package { 'iptables-services' :
          ensure => installed
        }
        service { 'iptables':
          ensure  => running,
          enable  => true,
          require => Package ['iptables-services']
        }

        # Configure iptables rules from template
        file { '/etc/sysconfig/iptables':
          content => template('profiles/iptables.conf.erb'),
          owner   => root,
          group   => root,
          mode    => '0600',
          notify  => Service['iptables']
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
