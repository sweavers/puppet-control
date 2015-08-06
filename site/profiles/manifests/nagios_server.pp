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
  $nagios_passwd = '$apr1$.M8zJFqn$J8h.8S2w31aSd8yrnqvUo/' #nagiospasswd

  ) {

    include ::stdlib

    # Install nagios packages
    $PKGLIST=['nagios','nagios-plugins','nagios-plugins-all',
              'nagios-plugins-nrpe']
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

    nagios_command { 'check_nrpe' :
      command_name => 'check_nrpe',
      command_line => '/usr/lib64/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$',
      target       => '/etc/nagios/conf.d/nagios_command.cfg',
      mode         => '0644',
      owner        => 'root',
      require      => Package['nagios']
    }

    # Auto populate nagios configuration from puppetdb
    Nagios_host <<||>> {
      target  => '/etc/nagios/conf.d/nagios_host.cfg',
      require => Package['nagios'],
      notify  => Service['nagios']
    }

    Nagios_hostgroup <<||>> {
      target  => '/etc/nagios/conf.d/host_group.cfg',
      require => Package['nagios'],
      notify  => Service['nagios']
    }

    Nagios_service <<||>> {
      target  => '/etc/nagios/conf.d/service.cfg',
      require => Package['nagios'],
      notify  => Service['nagios']
    }

    Nagios_command <<||>> {
      target  => '/etc/nagios/conf.d/command.cfg',
      require => Package['nagios'],
      notify  => Service['nagios']
    }

}
