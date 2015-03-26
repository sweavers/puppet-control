# Class profiles::elklogstash
#
# Sample Usage:
#   class { 'profiles::elklogstash': }
#
class profiles::elklogstash {

  class { 'logstash':
    package_url  => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.1-1_bd507eb.noarch.rpm',
    java_install => true,
  }

}
