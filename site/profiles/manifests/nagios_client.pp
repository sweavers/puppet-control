class profiles::nagios_client(

  $interface = 'eth1'

  ){

  include nagiosclient

  # Export nagios host configuration
  @@nagios_host { $::hostname :
    ensure                => present,
    alias                 => $::hostname,
    display_name          => $::hostname,
    address               => inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>"),
    use                   => 'generic-server,server-graph',
    hostgroups            => 'linux-servers, linux-virtual-servers',
    contact_groups        => 'admins',
    mode                  => '0644',
    owner                 => 'root',
    max_check_attempts    => '5',
    check_period          => '24x7',
    notification_interval => '30',
    notification_period   => '24x7',
    icon_image_alt        => 'Linux',
    statusmap_image       => 'vendor-logos/linux.jpg',
    icon_image            => 'vendor-logos/linux.jpg'
  }
}
