# Class profiles::logstash_forwarder
#
# Will install logstash forwarder on a node.
#
# Sample Usage:
#   class { 'profiles::logstash_forwarder': }
#
class profiles::logstash_forwarder(
  $environment              = undef,
  $logserver_fqdn           = 'logstash.lnx.lr.net',
  $logserver_live_ext_ip    = '10.79.40.77',
  $logserver_live_int_ip    = '192.168.39.35',
  $logserver_preprod_ext_ip = '10.79.40.77',
  $logserver_preprod_int_ip = '192.168.39.35',
  $logserver_preview_ext_ip = undef,
  $logserver_preview_int_ip = undef

  )

  {

  $ip_first_octet = split( $::ipaddress, '[.]' )
  $environment    = regsubst($::hostname, '^.*-(\d)\d\.*$', '\1')

  case $ip_first_octet[0]{
    10: {
      case $environment {
        '0': { $logserver_ip = $logserver_live_ext_ip }
        '1': { $logserver_ip = $logserver_preprod_ext_ip }
        '2': { $logserver_ip = $logserver_preview_ext_ip }
        default: { fail("Unexpected environment - ${::environment}") }
      }
    }

    192: {
      case $environment {
        '0': { $logserver_ip = $logserver_live_int_ip }
        '1': { $logserver_ip = $logserver_preprod_int_ip }
        '2': { $logserver_ip = $logserver_preview_int_ip }
        default: { fail("Unexpected environment - ${::environment}") }
      }
    }

    default: {
      fail("Unexpected network - ${::ipaddress}")
    }
  }


  $pattern = ".*${logserver_fqdn}$"

  file_line { 'logserverline':
    path  => '/etc/hosts',
    line  => "${logserver_ip} ${logserver_fqdn}",
    match => $pattern
  }

  # file { '':
  #   ensure => present,
  #   path   => '/etc/pki/tls/openssl.cnf',
  #   source => '',
  #   owner  => '',
  #   group  => '',
  #   mode   => '0111'
  #
  # }

  #  class { 'logstashforwarder': }
  #    servers  => [ 'logstash.lnx.lr.net' ],
  #    ssl_key  => 'puppet:///path/to/your/ssl.key',
  #    ssl_ca   => 'puppet:///path/to/your/ssl.ca',
  #    ssl_cert => 'puppet:///path/to/your/ssl.cert'

}
