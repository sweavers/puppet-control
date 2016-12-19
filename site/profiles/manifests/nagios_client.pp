class profiles::nagios_client(

  $interface = 'eth1'

  ){

  $nagiosclient_ip = inline_template("<%= scope.lookupvar('::ipaddress_${interface}') -%>")

  include nagiosclient

  # Export nagios host configuration

  #if $nagios::params::nagios_server_ip != $nagiosclient_ip {
    @@nagios_host { $::hostname :
      ensure                => present,
      alias                 => $::hostname,
      display_name          => $::hostname,
      address               => $nagiosclient_ip,
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
  #}
}
