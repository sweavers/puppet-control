#
class tomcat_old (

  $tomcat_manager_gui_password = hiera('tomcat_manager_gui_password'),
  $tomcatvalve                 = false
  ){

  include stdlib
  validate_bool($tomcatvalve)

  ##############################################################################
  ################################## INSTALL ###################################
  ##############################################################################

  # Make sure dependencies are installed, but don't necessarily manage them.
  $java_pkgs = [ 'java-1.8.0-openjdk', 'java-1.8.0-openjdk-devel', 'java-1.8.0-openjdk-headless' ]
  package { $java_pkgs :
    ensure => present,
  }

  # Add tomcat packages necessary for installation
  $tomcat_pkgs = [ 'tomcat', 'tomcat-webapps', 'tomcat-admin-webapps']
  package { $tomcat_pkgs :
    ensure  => present,
    require => Package[$java_pkgs]
  }

#  package { 'java-1.8.0-openjdk':
#    ensure  => absent,
#    require => Package[$java_pkgs]
#  }

  ##############################################################################
  #################################TOMCAT CONF##################################
  ##############################################################################

  $localtime = '/etc/localtime'
  $conf_dir = '/etc/tomcat'
  $server_xml = "${conf_dir}/server.xml"
  $catalina_properties = "${conf_dir}/catalina.properties"
  $tomcat_users_xml = "${conf_dir}/tomcat-users.xml"
  $tomcat_service = 'tomcat'

  file { $localtime :
    ensure => 'link',
    target => '/usr/share/zoneinfo/Europe/London'
  }

  file { $server_xml :
    ensure  => present,
    content => template('tomcat/server.xml.erb'),
    require => Package[$tomcat_pkgs],
    notify  => Service[$tomcat_service],
    owner   => 'tomcat',
    group   => 'tomcat'
  }

  file { $catalina_properties :
    ensure  => present,
    require => Package[$tomcat_pkgs],
    notify  => Service[$tomcat_service],
    owner   => 'tomcat',
    group   => 'tomcat'
  }->
  file_line { 'catalina_properties_share_loader':
    path  => '/usr/share/tomcat/conf/catalina.properties',
    line  => 'shared.loader=lr_classes/ejb_client',
    match => 'shared.loader'
  } ->
  file_line { 'catalina_prorperties_config_root':
    path => '/usr/share/tomcat/conf/catalina.properties',
    line => 'LR_TOMCAT_CONFIG_ROOT=/usr/share/tomcat/lr_classes'
  }

  file { $tomcat_users_xml :
    ensure  => present,
    require => Package[$tomcat_pkgs],
    notify  => Service[$tomcat_service],
    owner   => 'tomcat',
    group   => 'tomcat'
  }->
  file_line { 'tomcat_users_conf1':
    path  => '/usr/share/tomcat/conf/tomcat-users.xml',
    line  => ' ',
    match => '</tomcat-users>'
  }->
  file_line { 'tomcat_users_man':
    path => '/usr/share/tomcat/conf/tomcat-users.xml',
    line => '<role rolename="manager-gui"/>',
  }->
  file_line { 'tomcat_users_pass':
    path => '/usr/share/tomcat/conf/tomcat-users.xml',
    line => "<user name=\"tomcat\" password=\"${tomcat_manager_gui_password}\" roles=\"manager-gui\" />"
  }->
  file_line { 'tomcat_users_conf2':
    path => '/usr/share/tomcat/conf/tomcat-users.xml',
    line => '</tomcat-users>'
  }

  service { $tomcat_service :
    ensure    => running,
    enable    => true,
    require   => Package[$tomcat_pkgs],
    subscribe => File[$server_xml, $catalina_properties, $tomcat_users_xml]
  }

  # Need to SCP config zip and unzip in /usr/share/tomcat/
  #exec { 'install_tomcat_apps' :
  #  command =>  ''
  #}

}
