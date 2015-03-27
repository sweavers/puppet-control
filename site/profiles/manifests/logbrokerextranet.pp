# Class profiles::logbrokerextranet
#
# Sample Usage:
#   class { 'profiles::logbrokerextranet': }
#
class profiles::logbrokerextranet {

  class { 'redis': }

  class { 'logstash':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
  }

}
