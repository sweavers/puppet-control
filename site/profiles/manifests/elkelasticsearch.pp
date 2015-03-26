# Class profiles::elk
#
# Sample Usage:
#   class { 'profiles::elk': }
#
class profiles::elkelasticsearch {

  include ::stdlib

case $::osfamily{
  'RedHat': {
    $command= '/usr/bin/rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch'
  }
  'Debian': {
    $command= '/usr/bin/wget -qO - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -'
  }
  default: {
    fail("Unsupported OS type - ${::osfamily}")
  }
}
  exec { 'GPG-KEY-elasticsearch' :
    command  => $command
  }

$str = "[elasticsearch-1.5]
name=Elasticsearch repository for 1.5.x packages
baseurl=http://packages.elasticsearch.org/elasticsearch/1.5/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1"

file { '/etc/yum.repos.d/elasticsearch.repo' :
  ensure  => present,
  content => $str,
  require => Exec['GPG-KEY-elasticsearch']
  }

package { 'elasticsearch' :
  ensure  => present,
  require => File['/etc/yum.repos.d/elasticsearch.repo']
  }
}
