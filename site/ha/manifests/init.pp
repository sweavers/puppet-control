#
class ha (
  $listen_port = 80,
  $healthcheck = '/',
  $backends    = [],
  $interface   = 'eth0',
  $virtual_ip  = undef,
) {

  include stdlib
  validate_integer($listen_port)
  validate_string($healthcheck)
  validate_array($backends)
  validate_string($interface)
  validate_string($virtual_ip)

  unless has_interface_with($interface) {
    fail("$interface is not a valid network port")
  }
  unless is_ip_address($virtual_ip) {
    fail("$virtual_ip is not a valid IP address")
  }

  $haproxy_cfg    = '/etc/haproxy/haproxy.cfg'
  $keepalived_cfg = '/etc/keepalived/keepalived.conf'
  $vip_priority   = fqdn_rand_string(2,'0123456789')

  ensure_packages(['haproxy','keepalived'])

  file { $haproxy_cfg :
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('ha/haproxy.conf.erb'),
    require => Package['haproxy'],
    notify  => Service['haproxy']
  }

  service { 'haproxy':
    ensure    => running,
    enable    => true,
    require   => Package['haproxy'],
    subscribe => File[$haproxy_cfg]
  }

  file { $keepalived_cfg :
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('ha/keepalived.conf.erb'),
    require => Package['keepalived'],
    notify  => Service['keepalived']
  }

  service { 'keepalived':
    ensure    => running,
    enable    => true,
    require   => Package['keepalived'],
    subscribe => File[$keepalived_cfg]
  }

}
