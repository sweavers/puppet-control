# Class profiles::nagios_server
# This class will install and configure nagios server from epel.
#
# Parameters: #Paramiters accepted by the class
# ['$nagios_user'] - string
# ['$nagios_passwd'] - string
#
# Requires: #Modules required by the class
# - None
#
# Sample Usage:
# class { 'profiles::nagios_server': }
#
# Hiera:
# <EXAMPLE OF ANY REQUIRED HIERA STRUCTURE>
#
class profiles::nagios_server (

  $nagios_user   = nagiosadmin,
  $nagios_passwd = RbdO4ou4PNyMg #nagiospasswd

  ) {

    include ::stdlib

    # Install nagios packages
    $PKGLIST=['nagios', 'nagios-plugins-all']
    ensure_packages($PKGLIST)

    # Set nagios password
    file { '/etc/nagios/passwd':
      ensure  => 'present',
      content => "${nagios_user}:${nagios_passwd}",
      owner   => 'root',
      group   => 'apache',
      mode    => '0640',
      require => Package['nagios']
    }

    # Ensure apache is runnning
    service { 'httpd':
      ensure  =>'running',
      require => Package['nagios']
    }

    # Ensure nagios is runnning
    service { 'nagios':
      ensure  =>'running',
      require => Package['nagios']
    }

    # Auto populate nagios configuration from puppetdb
    Nagios_command <<||>> {
      require => Package['nagios'],
      notify  => Service['nagios']
    }

    Nagios_host <<||>> {
      target  => '/etc/nagios/conf.d/',
      require => Package['nagios'],
      notify  => Service['nagios']
    }

    Nagios_hostgroup <<||>> {
      require => Package['nagios'],
      notify  => Service['nagios']
    }

    Nagios_service <<||>> {
      require => Package['nagios'],
      notify  => Service['nagios']
    }
}
