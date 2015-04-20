# Class profiles::logbroker_extranet
#
# Sample Usage:
#   class { 'profiles::logbroker_extranet': }
#
class profiles::logbroker_extranet {

  class { 'redis': }

  class { 'logstash':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
  }

}
