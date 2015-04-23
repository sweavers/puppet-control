# Class profiles::logstash_forwarder
#
# Will install logstash forwarder on a node.
#
# Sample Usage:
#   class { 'profiles::logstash_forwarder': }
#
class profiles::logstash_forwarder(
  $environment = undef
  )

  {

  include profiles::logbroker_extranet
  include profiles::log_repository

  $ip_first_octet = split( $::ipaddress, '[.]' )

  case regsubst($::hostname, '^.*-(\d)\d\.*$', '\1'){
    0: {
      case $ip_first_octet[0]{
        10: {
          $logserver_ip   = $profiles::logbroker_extranet::prod_ip_address
          $logserver_cert = $profiles::logbroker_extranet::prod_logstash_forwarder_cert
        }

        192: {
          $logserver_ip   = $profiles::log_repository::prod_ip_address
          $logserver_cert = $profiles::log_repository::prod_logstash_forwarder_cert
        }

        default: {
          fail("Unexpected network - ${::ipaddress}")
        }
      }
    }
    1: {
      case $ip_first_octet[0]{
        10: {
          $logserver_ip   = $profiles::logbroker_extranet::preprod_ip_address
          $logserver_cert = $profiles::logbroker_extranet::preprod_logstash_forwarder_cert
        }

        192: {
          $logserver_ip   = $profiles::log_repository::preprod_ip_address
          $logserver_cert = $profiles::log_repository::preprod_logstash_forwarder_cert
        }

        default: {
          fail("Unexpected network - ${::ipaddress}")
        }
      }
    }
    default: {
      fail("Unexpected environment value derived from hostname - ${::hostname}")
    }
  }

  file { 'logstash_forwarder_cert':
    ensure  => 'file',
    name    => '/etc/pki/tls/certs/logstash-forwarder.crt',
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => $logserver_cert
  }

  class { 'logstashforwarder':
    servers => [ $logserver_ip ],
    ssl_ca  => $logserver_cert,
    require => File[logstash_forwarder_cert]
  }
}
