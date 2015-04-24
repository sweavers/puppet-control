# Class profiles::log_repository
#
# Sample Usage:
#   class { 'profiles::log_repository': }
#
class profiles::log_repository{

  case regsubst($::hostname, '^.*-(\d)\d\.*$', '\1'){
    0: { $environment = 'prod' }
    1: { $environment = 'preprod' }
    default: {
      fail("Unexpected environment value derived from hostname - ${::hostname}")
    }
  }

  class { 'redis': }

  class { 'elasticsearch':
    config => { 'cluster.name' => $environment }
  }

  class { 'logstash':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
    }

  class { 'kibana': }

}
