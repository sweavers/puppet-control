# Class profiles::log_broker
#
# Sample Usage:
#   class { 'profiles::log_broker': }
#
class profiles::log_broker {

  case regsubst($::hostname, '^.*-(\d)\d\.*$', '\1'){
    0:       { $serverenv = prod }
    1:       { $serverenv = preprod }
    default: { fail("Unexpected environment value derived from hostname - ${::hostname}") }
  }

  $logserver_cert = hiera("log_broker_${serverenv}_logstash_forwarder_cert")
  $logserver_key  = hiera("log_broker_${serverenv}_logstash_forwarder_key")

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
                      File[ 'logstash_forwarder_key','logstash_forwarder_cert' ] ]
  }

  logstash::configfile { 'log_broker_config':
    content => hiera( 'log_broker_logstash_config' ),
    order   => 10
  }
}
