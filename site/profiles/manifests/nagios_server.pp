class profiles::nagios_server(

  $nagios_hosts         = hiera_hash('nagios_hosts',false),
  $nagios_hostgroups    = hiera_hash('nagios_hostgroups',false),
  $nagios_services      = hiera_hash('nagios_services',false),
  $nagios_commands      = hiera_hash('nagios_commands',false),
  $nagios_contacts      = hiera_hash('nagios_contacts',false),
  $nagios_contactgroups = hiera_hash('nagios_contactgroups',false)

  ){

  include nagiosserver

  # Remove monitoring for localhost
  file { '/etc/nagios/objects/localhost.cfg' :
    ensure  => absent,
    require => Package['nagios']
  }

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
  file_line { 'nagios_localhost':
    ensure  => present,
    path    => '/etc/nagios/nagios.cfg',
    line    => '#cfg_file=/etc/nagios/objects/localhost.cfg',
    match   => 'cfg_file=/etc/nagios/objects/localhost.cfg',
    notify  => Service['nagios'],
    require => Package['nagios']
  }
}
