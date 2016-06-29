
class profiles::tomcat(
  $catalina_base = '/opt/tomcat',
  $catalina_home = '/opt/tomcat',
  $server_config = '/opt/tomcat/conf/server.xml'
){


#  include java
#  include tomcat
#  include stdlib
#  include wsgi
#  include concat

#  java::oracle { 'jdk7' :
#    ensure  => 'present',
#    version => '7',
#    java_se => 'jdk',
#  }

#define tomcat::config::properties::property (
#  $catalina_base,
#  $value,
#  $property = $name,
#) {
#  concat::fragment { "${catalina_base}/conf/catalina.properties property ${property}":
#    target  => "${catalina_base}/conf/catalina.properties",
#    content => "${property}=${value}",
#  }
#}

#packages are installed by yum
  package { ['java-1.7.0-openjdk', 'java-1.7.0-openjdk-devel', 'haproxy', 'tomcat'] :
     ensure => present
  }

  tomcat::install { '/opt/tomcat':
    source_url => 'http://www-us.apache.org/dist/tomcat/tomcat-7/v7.0.69/bin/apache-tomcat-7.0.69.tar.gz'
  }
  tomcat::instance { 'default':
    catalina_home => '/opt/tomcat'
  }
  tomcat::config::server::tomcat_users {
    'manager-gui':
      ensure        => present,
      catalina_base => '/opt/tomcat',
      element       => 'role',
      element_name  => 'admin';
    'tomcat':
      ensure        => present,
      catalina_base => '/opt/tomcat',
      element       => 'user',
      element_name  => 'tomcat',
      password      => 'password',
      roles         => ['admin'];
  }
  tomcat::service {'tomcat':
      catalina_base => $catalina_base,
      catalina_home => $catalina_home
  }
#  tomcat::war {'sample.war':
#      catalina_base => $catalina_base,
#      war_source    => '/opt/tomcat/webapps/docs/appdev/sample/sample.war',
#      appBase       => 'webapps',
#      unpackWARS    => true,
#      autoDeploy    => true
#  }
#  tomcat::config::properties::property {'shared':
#      catalina_base => $catalina_base,
#      value         => '/opt/tomcat/lr_classes/ejb_client',
#      property      => 'shared.folder'
#  }
#  tomcat::config::properties::property {'LR_TOMCAT_CONFIG_ROOT':
#      catalina_base => $catalina_base,
#      value         => '/opt/tomcat/lr_classes',
#      property      => 'LR_TOMCAT_CONFIG_ROOT'
#  }
  tomcat::config::server {'server.xml':
      catalina_base => $catalina_base,
      port          => 8005,
      shutdown      => 'SHUTDOWN'
  }
  tomcat::config::server::listener {'AprLifecycleListener':
      class_name => 'org.apache.catalina.core.AprLifecycleListener'
  }
  tomcat::config::server::listener {'JasperListener':
      class_name => 'org.apache.catalina.core.JasperListener'
  }
  tomcat::config::server::listener {'JreMemoryLeakPreventionListener':
      class_name => 'org.apache.catalina.core.JreMemoryLeakPreventionListener'
  }
  tomcat::config::server::listener {'ClobalResourcesLifecycleListener':
      class_name => 'org.apache.catalina.mbeans.GlobalResourcesLifecycleListener'
  }
  tomcat::config::server::listener {'ThreadLocalLeakPreventionListener':
      class_name => 'org.apache.catalina.core.ThreadLocalLeakPreventionListener'
  }
  tomcat::config::server::globalnamingresource{'UserDatabase':
      ensure                => present,
      catalina_base         => $catalina_base,
      additional_attributes => {
                                auth          => 'Container',
                                type          => 'org.apache.catalina.UserDatabase',
                                description   => 'User database that can be updated and saved',
                                factory       => 'org.apache.catalina.users.MemoryUserDatabaseFactory',
                                pathname      => 'conf/tomcat-users.xml'
                               },
      server_config         => $server_config,
  }
  tomcat::config::server::service{'Catalina':
      catalina_base  => $catalina_base,
      server_config  => $server_config,
      service_ensure => present
  }
  tomcat::config::server::connector{'port8080':
      port                  => 8080,
      protocol              => 'HTTP/1.1',
      catalina_base         => $catalina_base,
      server_config         => $server_config,
      additional_attributes => {
                                connectionTimeout  => 20000,
                                redirectPort       => 8443
                               }
  }
  tomcat::config::server::connector{'port8443':
      port                  => 8443,
      protocol              => 'HTTP/1.1',
      catalina_base         => $catalina_base,
      server_config         => $server_config,
      additional_attributes => {
                                #SSLEnabled         => true,
                                maxThreads         => 150,
                                scheme             => 'https',
                                secure             => true,
                                keystoreFile       => '.keystore',
                                keystorePass       => 'XXXXX',
                                clientAuth         => false,
                                sslEnabledProtocol => 'TLSv1, TLSv1.1, TLSv1.2'
                               }
  }
  tomcat::config::server::engine{'Catalina':
      engine_name      => 'Catalina',
      default_host     => 'localhost',
      jvm_route        => 'jvm1',         #Do we need this?
      jvm_route_ensure => present,        #
      catalina_base    => $catalina_base,
      server_config    => $server_config
  }
  tomcat::config::server::realm{'LockOutRealm':
      class_name        => 'org.apache.catalina.realm.LockOutRealm',
      catalina_base    => $catalina_base,
      server_config    => $server_config,
      realm_ensure     => present
  }
  tomcat::config::server::realm{'UserDatabaseRealm':
      class_name             => 'org.apache.catalina.realm.UserDatabaseRealm',
      additional_attributes => {resourceName => 'UserDatabase'},
      parent_realm          => 'LockOutRealm',
      catalina_base         => $catalina_base,
      server_config         => $server_config,
      realm_ensure          => present
  }
  tomcat::config::server::valve{'AccessLog':
      class_name            => 'org.apache.catalina.valves.AccessLogValve',
      catalina_base         => $catalina_base,
      server_config         => $server_config,
      additional_attributes => {directory => 'logs',
                                prefix    => 'localhost_access_log.',
                                suffix    => '.txt',
                                pattern   => '%h %l %u %t &quot;%r&quot; %s %b'
                               }
  }
  tomcat::config::server::valve{'AMTomcat':
      class_name            => 'com.ibm.tivoli.integration.am.catalina.valves.AMTomcatValve',
      catalina_base         => $catalina_base,
      server_config         => $server_config,
      additional_attributes => {debugTrace   => true,
                                groupsHeader => 'iv-groups',
                                fallThrough  => true
                               }
  }
}
