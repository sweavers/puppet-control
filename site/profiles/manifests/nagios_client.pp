class profiles::nagios_client(

  $interface       = eth1,
  $nagios_services = hiera_hash('nagios_services', false)

  ){

  # create additional nrpe commands from hiera
  class { 'nagiosclient':
    nrpe_commands => hiera_array('nrpe_commands', undef)
  }

  # Export nagios host configuration
  @@nagios_host { $::fqdn :
    ensure                => present,
    alias                 => $::hostname,
    address               => inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>"),
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
    ensure              => present,
    check_command       => 'check_ping!100.0,20%!500.0,60%',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'Ping'
  }

  @@nagios_service { "check_load_${::hostname}":
    ensure              => present,
    check_command       => 'check_nrpe!check_load\!5.0,4.0,3.0\!10.0,6.0,4.0',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'Current Load'
  }

  @@nagios_service { "check_current_users_${::hostname}":
    ensure              => present,
    check_command       => 'check_nrpe!check_users\!20\!50',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'Current Users'
  }

  @@nagios_service { "check_root_partition_${::hostname}":
    ensure              => present,
    check_command       => 'check_nrpe!check_disk\!20%\!10%\!/',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'Root Partition'
  }

  @@nagios_service { "check_ssh_${::hostname}":
    ensure              => present,
    check_command       => 'check_ssh',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'SSH'
  }

  # Only add swap check if this is not an aws machine
  if ($::hosting_platform != dev_aws) and ($::hosting_platform != internal_aws) {
    @@nagios_service { "check_swap_${::hostname}":
      ensure              => present,
      check_command       => 'check_nrpe!check_swap\!20\!10',
      mode                => '0644',
      owner               => root,
      use                 => 'generic-service',
      host_name           => $::hostname,
      notification_period => '24x7',
      service_description => 'Swap Usage'
    }
  }

  @@nagios_service { "check_procs_${::hostname}":
    ensure              => present,
    check_command       => 'check_nrpe!check_procs\!250\!400\!RSZDT',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'Processes'
  }

  @@nagios_service { "check_mem_${::hostname}":
    ensure              => present,
    check_command       => 'check_nrpe!check_mem\!20\!10',
    mode                => '0644',
    owner               => root,
    use                 => 'generic-service',
    host_name           => $::hostname,
    notification_period => '24x7',
    service_description => 'Ram Usage'
  }

  # create additional nagios services from hiera
  if $nagios_services {
    create_resources('@@nagios_service', $nagios_services)
  }

}
