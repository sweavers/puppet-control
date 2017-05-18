#
# Hash example:
# class { 'ha':
#   virtual_ip   => '192.168.99.10',
#   interface    => 'eth1',
#   lb_instances => {
#     'default' => {
#       'port'        => 80,
#       'healthcheck' => '/',
#       'backends'    => [ 'localhost:8080', 'localhost:8081']
#     },
#     'test'          => {
#       'listen_port' => 9000,
#       'healthcheck' => '/health',
#       'backends'    => [ 'airbnb.com' ]
#     }
#   }
#  }
class ha (
  $lb_instances = undef,
  $interface   = 'eth0',
  $virtual_ip  = undef,
  $sticky      = false,
  $auth_users  = undef,
) {

  include stdlib
  validate_hash($lb_instances)
  validate_string($interface)
  validate_string($virtual_ip)
  validate_bool($sticky)

  unless has_interface_with($interface) {
    fail("${interface} is not a valid network port")
  }
  unless is_ip_address($virtual_ip) {
    fail("${virtual_ip} is not a valid IP address")
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

  selboolean { 'haproxy_connect_any' :
    value      => 'on',
    persistent => true,
  }

  service { 'keepalived':
    ensure    => running,
    enable    => true,
    require   => [ Package['keepalived'], Selboolean['haproxy_connect_any'] ],
    subscribe => File[$keepalived_cfg]
  }

}
