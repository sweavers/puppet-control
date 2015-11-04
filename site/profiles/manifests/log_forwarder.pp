# Class profiles::log_forwarderuto-merging hiera/common.yaml
#
# Will install logstash forwarder on a node.
#
# Sample Usage:
#   class { 'profiles::log_forwarder': }
#
class profiles::log_forwarder{

  case $::network_location{
    zone1:      { $servertype = 'repository' }
    zone2:      { $servertype = 'broker' }
    default: { fail("No Valid Zone Available - ${::network_location}") }
  }

  $logserver_ip   = hiera("log_${servertype}_ip_address", false)
  $logserver_cert = hiera("log_${servertype}_logstash_forwarder_cert", false)


  if ($logserver_cert) and ($logserver_ip) {

    if ! defined(File['logstash_forwarder_cert']) {
      file { 'logstash_forwarder_cert' :
        ensure  => 'file',
        name    => '/etc/pki/tls/certs/logstash-forwarder.crt',
        owner   => 'root',
        group   => 'root',
        mode    => '0664',
        content => $logserver_cert
      }
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

    logstashforwarder::file { 'applogs':
      paths  => [ '/opt/landregistry/applications/*/logs/*.log' ],
      fields => {
        'type' => 'application'
      }
    }


  }
}
