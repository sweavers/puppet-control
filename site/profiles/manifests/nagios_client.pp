# Class profiles::nagios_server
# This class will install and configure nagios server from epel.
#
# Parameters: #Paramiters accepted by the class
# ['$nagios_user'] - string
# ['$nagios_passwd'] - string
#
# Requires: #Modules required by the class
# - None
#
# Sample Usage:
# class { 'profiles::nagios_server': }
#
# Hiera:
# <EXAMPLE OF ANY REQUIRED HIERA STRUCTURE>
#
class profiles::nagios_client (

  $nagios_server = '172.16.42.69'

  ) {

    include ::stdlib

    # Install nagios client packages
    $PKGLIST=['nrpe', 'nagios-plugins-all', 'openssl']
    ensure_packages($PKGLIST)

    # Set ip address of nagios server
    file_line { '/etc/nagios/nrpe.cfg':
      path    => '/etc/nagios/nrpe.cfg',
      line    => "allowed_hosts=127.0.0.1 ${nagios_server}",
      match   => '^allowed_hosts.*$',
      require => Package['nrpe'],
      notify  => Service['nrpe']
    }

    # Ensure nrpe is runnning
    service { 'nrpe':
      ensure  =>'running',
      require => Package['nrpe']
    }

    # Export nagios host configuration
    @@nagios_host { $::hostname :
      ensure                => present,
      alias                 => $::hostname,
      address               => $::ipaddress,
      mode                  => '0644',
      owner                 => root,
      use                   => 'linux-server',
      max_check_attempts    => '5',
      check_period          => '24x7',
      notification_interval => '30',
      notification_period   => '24x7'
    }

    # Export nagios service configuration
    @@nagios_service { 'SSH' :
      ensure                => present,
      use                   => 'generic-service',
      host_name             => 'client',
      service_description   => 'SSH',
      check_command         => 'check_ssh',
      notifications_enabled => '0'
    }
}
