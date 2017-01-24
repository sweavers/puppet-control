# Class profiles::nagios_server
#
# This class will manage nagios resources created from heira lookups and
# collected resources esported from nagios client nodes.
#
# Parameters:
#  ['nagios_hosts'] - Hash of additional nagios host resrources.
#  ['nagios_hostgroups'] - Hash of additional nagios hostgroup resrources.
#  ['nagios_services'] - Hash of additional nagios service resrources.
#  ['nagios_commands'] - Hash of additional nagios command resrources.
#  ['nagios_contacts'] - Hash of nagios contact resrources.
#  ['nagios_contactgroups'] - Hash of nagios contactgroup resrources.
#  ['monitor_localhost'] - Whether the server should monitro itself as localhost
#                          Defaults to false - should be set to true for testing
#                          when no master is present.
#
# Requires:
# - landregistry/nagios
#
# Sample Usage:
#
#   include profiles::nagios_server
#
# Hiera Lookups:
#
#  Turn on monitoring of localhost to facillitate masterless testing:
#    profiles::nagios_server::monitor_localhost: true
#
#  Example of nagios resources in heira:
#
#    nagios_hosts:
#      test_host:
#        ensure: present
#        alias: test_host
#        address: 192.168.42.51
#        mode: '0644'
#        owner: root
#        use: linux-server
#        max_check_attempts: 5
#        check_period: 24x7
#        notification_interval: 30
#        notification_period: 24x7
#
#    nagios_services:
#      check_ping_test_host:
#        ensure: present
#        check_command: check_ping!100.0,20%!500.0,60%
#        mode: '0644'
#        owner: root
#        use: generic-service
#        host_name: test_host
#        notification_period: 24x7
#        service_description: Ping

class profiles::nagios_server(

  $nagios_hosts         = hiera_hash('nagios_hosts',false),
  $nagios_hostgroups    = hiera_hash('nagios_hostgroups',false),
  $nagios_services      = hiera_hash('nagios_services',false),
  $nagios_commands      = hiera_hash('nagios_commands',false),
  $nagios_contacts      = hiera_hash('nagios_contacts',false),
  $nagios_contactgroups = hiera_hash('nagios_contactgroups',false),
  $monitor_localhost    = false

  ){

  include nagios

  # Collect nagios resources from puppetdb
  Nagios_host <<||>> {
    require => Package['nagios'],
    notify  => Service['nagios']
  }

  Nagios_hostgroup <<||>> {
    require => Package['nagios'],
    notify  => Service['nagios']
  }

  Nagios_service <<||>> {
    require => Package['nagios'],
    notify  => Service['nagios']
  }

  Nagios_command <<||>> {
    require => Package['nagios'],
    notify  => Service['nagios']
  }

  # Import nagios resources from heira
  $resource_defaults = {notify  => Service['nagios']}

  if $nagios_hosts {
    create_resources('nagios_host', $nagios_hosts, $resource_defaults)
  }

  if $nagios_hostgroups {
    create_resources('nagios_hostgroup', $nagios_hostgroups, $resource_defaults)
  }

  if $nagios_services {
    create_resources('nagios_service', $nagios_services, $resource_defaults)
  }

  if $nagios_commands {
    create_resources('nagios_command', $nagios_commands, $resource_defaults)
  }

  if $nagios_contacts {
    create_resources('nagios_contact', $nagios_contacts, $resource_defaults)
  }

  if $nagios_contactgroups {
    create_resources('nagios_contactgroup', $nagios_contactgroups, $resource_defaults)
  }

  # Configure nagios not to monitor localhosts
  if $monitor_localhost == false {
    file_line { 'nagios_localhost':
      ensure  => present,
      path    => '/etc/nagios/nagios.cfg',
      line    => '#cfg_file=/etc/nagios/objects/localhost.cfg',
      match   => 'cfg_file=/etc/nagios/objects/localhost.cfg',
      notify  => Service['nagios'],
      require => Package['nagios']
    }
  }
}
