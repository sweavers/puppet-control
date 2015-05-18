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

  $firewall_state    = 'off',
  $ssh_allowed_range = '0.0.0.0/1'

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
