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

  file { 'logstash_broker_key':
    ensure  => 'file',
    name    => '/etc/pki/tls/private/logstash-forwarder.key',
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => $logserver_key
  }

  file { 'logstash_broker_cert':
    ensure  => 'file',
    name    => '/etc/pki/tls/certs/logstash-forwarder.crt',
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => $logserver_cert
  }

sysctl { 'vm.overcommit_memory':
  value  => '1',
  notify => Service['redis']
}

exec { 'disable_transparent_hugepage_enabled':
  command => '/bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled',
  unless  => '/bin/grep -c "\[never\]" /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null',
  notify  => Service['redis']
}

exec { 'set_somaxconn_for_redis':
  command => '/bin/echo 511 > /proc/sys/net/core/somaxconn',
  unless  => '/bin/grep -c "511" /proc/sys/net/core/somaxconn 2>/dev/null',
  notify  => Service['redis']
}

  class { 'redis':
    listen => '0.0.0.0'
  }

  class { 'logstash':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
    require      => [ Class[ 'redis' ],
                      File[ 'logstash_broker_key','logstash_broker_cert' ] ]
  }

  logstash::configfile { 'log_broker_config':
    content => hiera( 'log_broker_logstash_config' ),
    order   => 10
  }
}
