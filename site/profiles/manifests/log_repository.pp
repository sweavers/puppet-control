# Class profiles::log_repository
#
# Sample Usage:
#   class { 'profiles::log_repository': }
#
class profiles::log_repository{

  case $machine_level{
    production:     { $serverenv = prod }
    pre-production: { $serverenv = preprod }
    test:           { $serverenv = test }
    default: { fail("Unexpected environment value derived from hostname - ${puppet_environment}") }
  }

  $logserver_cert = hiera("log_repository_${serverenv}_logstash_forwarder_cert")
  $logserver_key  = hiera("log_repository_${serverenv}_logstash_forwarder_key")
  $logserver_ip = hiera("log_repository_${serverenv}_ip_address")
  $log_repository_logstash_config = hiera("log_repository_${serverenv}_logstash_config")

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

  class { 'profiles::elasticsearch':
    clustername => $serverenv,
    nodenumber  => $hostnumber
  }

  class { 'nginx': }

  nginx::resource::vhost { 'kibana_proxy':
    server_name    => [ '192.168.39.35' ],
    listen_port    => 80,
    proxy_redirect => 'off',
    proxy          => 'http://127.0.0.1:5601'
  }

  class { 'logstash':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
    require      => [ File[ 'logstash_forwarder_key','logstash_forwarder_cert' ] ]
  }

  logstash::configfile { 'log_repository_config':
    content => $log_repository_logstash_config,
    order   => 10
  }

  class { 'kibana': }

}
