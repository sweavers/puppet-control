# Class: profiles::puppet::puppetdb_firewall
#
# This class sets up a basic IP tables firewall to restric acccess to puppetdb
#
# Parameters:
#
#
#

#
# Sample Usage:
#  class { 'profiles::puppet::master':
#    control_repo => 'https://github.com/LandRegistry-Ops/puppet-control.git',
#  }
#
class profiles::puppet::puppetdb_firewall (

  $firewall_enabled  = false,
  $ssh_allowed_range = '0.0.0.0/0',
  $services          = {}

){

  case $firewall_enabled {
    true :{
      notify {'firewall_enabled': message => 'Firewall enabled' }
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
        content => template('profiles/puppetdb_iptables.conf.erb'),
        owner   => root,
        group   => root,
        mode    => '0600',
        notify  => Service['iptables']
      }
    }
    default :{
      notify {'firewall_disabled': message => 'Firewall disabled' }
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
