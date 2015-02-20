# Class profiles::gitlab
# This class will manage Gitlab installations.
# Currently supports stand-alone only.
#
# Parameters:
#  ['backup_location'] - NFS location for backups
#  ['smtp_relay']      - SMTP relay server and port ('server:port')
#  ['local_login']     - Should local login should be permitted. (Boolean)
#
# Requires:
# - spuder/gitlab
# - puppetlabs/firewall
#
# Sample Usage:
#   class { 'profiles::gitlab': }
#
class profiles::gitlab (

  $backup_location = undef,
  $smtp_relay      = undef,
  $local_login     = false,
  $external_url    = 'localhost',
  $ldap_enabled    = false,
  $ldap_host       = undef,
  $ldap_base       = undef,
  $ldap_bind_dn    = undef,
  $ldap_password   = undef,

){

  class { '::gitlab' :
    puppet_manage_config          => true,
    puppet_manage_backups         => true,
    gitlab_branch                 => '7.5.1',
    gitlab_download_link          => 'https://downloads-packages.s3.amazonaws.com/ubuntu-14.04/gitlab_7.5.1-omnibus.5.2.0.ci-1_amd64.deb',  # Should be pulled from Hira
    external_url                  => $external_url,
    backup_keep_time              => 5184000, # In seconds, 5184000 = 60 days
    backup_path                   => '/var/opt/gitlab/backups',
    gravatar_enabled              => true,
    gitlab_signup_enabled         => false,
    gitlab_signin_enabled         => $local_login,
    gitlab_default_theme          => 4, # 1=Basic, 2=Mars, 3=Modern, 4=Gray, 5=Color (gitlab default: 2)
    gitlab_default_projects_limit => 40,

    # LDAP integration
    ldap_enabled                  => $ldap_enabled,
    ldap_host                     => $ldap_host,
    ldap_port                     => 389,
    ldap_method                   => 'plain',
    ldap_base                     => $ldap_base,
    ldap_bind_dn                  => $ldap_bind_dn,
    ldap_password                 => $ldap_password,
    ldap_uid                      => 'sAMAccountName'
  }

  #ensure that nfs package is installed
  #determin the package name based on the OS
  $nfs_package = $::operatingsystem ? {
    Redhat     => 'nfs-utils',
    Ubuntu     => 'nfs-common',
  }

  package { $nfs_package :
    ensure => present
  }

  mount { '/var/opt/gitlab/backups':
    ensure  => 'mounted',
    device  => $backup_location,
    fstype  => 'nfs',
    options => 'defaults',
    atboot  => true,
    require => Package [ $nfs_package ]
  }

  file_line { 'internal smtp relay config':
    ensure => present,
    line   => "relayhost = ${smtp_relay}",
    path   => '/etc/postfix/main.cf',
  }

}
