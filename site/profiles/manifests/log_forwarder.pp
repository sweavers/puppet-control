# Class profiles::log_forwarder
#
# Will install logstash forwarder on a node.
#
# Sample Usage:
#   class { 'profiles::log_forwarder': }
#
class profiles::log_forwarder{

  $ip_first_octet = split( $::ipaddress, '[.]' )

  case regsubst($::hostname, '^.*-(\d)\d\.*$', '\1'){
    0: {
      case $ip_first_octet[0]{
        10: {
          $logserver_ip   = hiera('logbroker_extranet_prod_ip_address')
          $logserver_cert = hiera('logbroker_extranet_prod_logstash_forwarder_cert')
        }

        192: {
          $logserver_ip   = hiera('log_repository_prod_ip_address')
          $logserver_cert = hiera('log_repository_prod_logstash_forwarder_cert')
        }

        default: {
          fail("Unexpected network - ${::ipaddress}")
        }
      }
    }
    1: {
      case $ip_first_octet[0]{
        10: {
          $logserver_ip   = hiera('logbroker_extranet_preprod_ip_address')
          $logserver_cert = hiera('logbroker_extranet_preprod_logstash_forwarder_cert')
        }

        192: {
          $logserver_ip   = hiera('log_repository_preprod_ip_address')
          $logserver_cert = hiera('log_repository_preprod_logstash_forwarder_cert')
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
    package_url => 'https://download.elastic.co/logstash-forwarder/binaries/logstash-forwarder-0.4.0-1.x86_64.rpm',
    servers     => [ "${logserver_ip}:5000" ],
    ssl_ca      => '/etc/pki/tls/certs/logstash-forwarder.crt',
    require     => File['logstash_forwarder_cert']
  }

  logstashforwarder::file { 'stdlogs':
    paths  => [ '/var/log/messages','/var/log/secure' ],
    fields => {
      'type' => 'syslog'
    }
  }
}
