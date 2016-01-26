# Class profiles::dns
#
# Will install named on a node.
#
# Sample Usage:
#   class { 'profiles::dns': }
#
class profiles::dns (
  $dns_zone = hiera_hash('dns_zone',false),
  $dns_a_record = hiera_hash('dns_a_record',false)
  ){

  include dns::server

  dns::server::options { '/etc/named/named.conf.options':
    forwarders => [ '8.8.8.8', '8.8.4.4' ]
  }

  if $dns_zone {
    create_resources('dns::zone', $dns_zone)
  }

  if $dns_a_record {
    create_resources('dns::record::a', $dns_a_record)
  }

}
