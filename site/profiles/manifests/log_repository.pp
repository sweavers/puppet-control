# Class profiles::log_repository
#
# Sample Usage:
#   class { 'profiles::log_repository': }
#
class profiles::log_repository(
  $hostnumber     = 1,
  $auth_basic     = 'Restricted',
  $auth_password     = 'TOtM2LbCXW4XI',

){

  $logserver_cert = hiera('log_repository_logstash_forwarder_cert')
  $logserver_key  = hiera('log_repository_logstash_forwarder_key')
  $logserver_ip = hiera('log_repository_ip_address')
  $log_repository_logstash_config = hiera('log_repository_logstash_config')

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

  # The cluster name has to match that in log_repository_logstash_config for elasticsearch
  class { 'profiles::elasticsearch':
    clustername => $::machine_region,
    nodenumber  => $hostnumber
  }

  include profiles::nginx

  selinux::module { 'log_repo':
    ensure => 'present',
    source => 'puppet:///modules/profiles/log_repo.te'
  }

  $key = '/etc/nginx/ssl/kibana.key'
  $csr = '/etc/nginx/ssl/kibana.csr'
  $crt = '/etc/nginx/ssl/kibana.pem'

  file {"/etc/nginx/ssl/":
    ensure => "directory",
  }

  exec { 'create key':
    command => "openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj '/C=UK/ST=Denial/L=Plymouth/O=Dis/CN=$::hostname' -keyout $key  -out $crt",
    creates => $key,
    require => File['/etc/nginx/ssl/'],
  }

  # Set auth_basic to Off to disable.
  nginx::resource::vhost { 'kibana_proxy':
    server_name          => [ $::hostname ],
    listen_port          => 443,
    auth_basic           => $auth_basic,
    auth_basic_user_file => '/etc/nginx/conf.d/kibana.htpasswd',
    proxy_redirect       => 'off',
    proxy                => 'http://127.0.0.1:5601',
    ssl                  => true,
    ssl_cert             => $crt,
    ssl_key              => $key,
    require              => Exec['create key'],
  }

  file { '/etc/nginx/conf.d/kibana.htpasswd':
  ensure => present,
  }->
  htpasswd { 'kibana':
    cryptpasswd => $auth_password,  # encrypted password
    target      => '/etc/nginx/conf.d/kibana.htpasswd',
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
