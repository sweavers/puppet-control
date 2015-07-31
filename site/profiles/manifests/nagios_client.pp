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

  $nagios_server = '192.16.42.58'

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
    @@nagios_service { "check_ping_${::hostname}":
      check_command       => 'check_ping!100.0,20%!500.0,60%',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Ping'
    }

    @@nagios_service { "check_load_${::hostname}":
      check_command       => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Current Load'
    }

    @@nagios_service { "check_current_users_${::hostname}":
      check_command       => 'check_local_users!20!50',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Current Users'
    }

    @@nagios_service { "check_root_partition_${::hostname}":
      check_command       => 'check_local_disk!20%!10%!/',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Root Partition'
    }

    @@nagios_service { "check_ssh_${::hostname}":
      check_command       => 'check_ssh',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'SSH'
    }

    @@nagios_service { "check_swap_${::hostname}":
      check_command       => 'check_local_swap!20!10',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Swap Usage'
    }

    @@nagios_service { "check_procs_${::hostname}":
      check_command       => 'check_local_procs!250!400!RSZDT',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Total Processes'
    }
}
