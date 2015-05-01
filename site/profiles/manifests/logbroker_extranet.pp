# Class profiles::logbroker_extranet
#
# Sample Usage:
#   class { 'profiles::logbroker_extranet': }
#
class profiles::logbroker_extranet {

  case regsubst($::hostname, '^.*-(\d)\d\.*$', '\1'){
    0: {
      $logserver_cert = hiera('logbroker_extranet_prod_logstash_forwarder_cert')
      $logserver_key = hiera('logbroker_extranet_prod_logstash_forwarder_key')
    }
    1: {
      $logserver_cert = hiera('logbroker_extranet_preprod_logstash_forwarder_cert')
      $logserver_key = hiera('logbroker_extranet_preprod_logstash_forwarder_key')
    }
    default: {
      fail("Unexpected environment value derived from hostname - ${::hostname}")
    }
  }

  file { 'logstash_forwarder_key':
    ensure  => 'file',
    name    => '/etc/pki/tls/private/logstash-forwarder.key',
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => $logserver_key
  }

  file { 'logstash_forwarder_cert':
    ensure  => 'file',
    name    => '/etc/pki/tls/certs/logstash-forwarder.crt',
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => $logserver_cert
  }

  class { 'redis':
    listen => '0.0.0.0'
  }

  class { 'logstash':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
    require      => [ Class[ 'redis' ],
                      File[ 'logstash_forwarder_key' ],
                      File[ 'logstash_forwarder_cert' ] ]
  }

  logstash::configfile { 'input_lumberjack':
    content => hiera( 'logbroker_extranet_logstash_config' ),
    order   => 10
  }
}
