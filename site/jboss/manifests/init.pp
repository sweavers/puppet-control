#
class jboss(){

  include stdlib

  class { 'wildfly':
#    mode        => 'domain',
#    host_config => 'host-master.xml'
  }

#  wildfly::config::mgmt_user { 'slave1':
#    password => 'wildfly',
#  }


}
