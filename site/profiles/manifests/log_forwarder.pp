# Class profiles::log_forwarderuto-merging hiera/common.yaml
#
# Will install logstash forwarder on a node.
#
# Sample Usage:
#   class { 'profiles::log_forwarder': }
#
class profiles::log_forwarder{

  $ip_first_octet = split( $::ipaddress, '[.]' )

  case $ip_first_octet[0]{
    10:      { $servertype = 'broker' }
    192:     { $servertype = 'repository' }
    default: { fail("Unexpected network - ${::ipaddress}") }
  }

  case regsubst($::hostname, '^.*-(\d)\d\.*$', '\1'){
    0:       { $serverenv = prod }
    1:       { $serverenv = preprod }
    default: { fail("Unexpected environment value derived from hostname - ${::hostname}") }
  }

  $logserver_ip   = hiera("log_${servertype}_${serverenv}_ip_address")
  $logserver_cert = hiera("log_${servertype}_${serverenv}_logstash_forwarder_cert")

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
