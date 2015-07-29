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

  $enable_backup   = false,
  $backup_location = undef,
  $smtp_relay      = undef,
  $local_login     = false,
  $external_url    = 'http://localhost',
  $ldap_enabled    = false,
  $ldap_host       = undef,
  $ldap_base       = undef,
  $ldap_bind_dn    = undef,
  $ldap_password   = undef,
  $gitlab_crt      = '',
  $gitlab_key      = '',
  $https_redirect  = false,
  $aws_acccess_key = undef,
  $aws_secret_key  = undef

){

  package { 'epel-release' :
    ensure => installed
  }

  $gitlab_download_link = $::operatingsystem ? {
    CentOS     => 'https://downloads-packages.s3.amazonaws.com/centos-7.0.1406/gitlab-7.5.1_omnibus.5.2.0.ci-1.el7.x86_64.rpm',
    Redhat     => 'https://downloads-packages.s3.amazonaws.com/centos-7.0.1406/gitlab-7.5.1_omnibus.5.2.0.ci-1.el7.x86_64.rpm',
    Ubuntu     => 'https://downloads-packages.s3.amazonaws.com/ubuntu-14.04/gitlab_7.5.1-omnibus.5.2.0.ci-1_amd64.deb',
  }

  file { '/etc/gitlab/ssl' :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700'
  }

  file { '/etc/gitlab/ssl/gitlab.crt' :
    ensure  => present,
    content => $gitlab_crt,
    owner   => root,
    group   => root,
    mode    => '0644'
  }

  file { '/etc/gitlab/ssl/gitlab.key' :
    ensure  => present,
    content => $gitlab_key,
    owner   => root,
    group   => root,
    mode    => '0400'
  }

  class { '::gitlab' :
    puppet_manage_config          => true,
    puppet_manage_backups         => $enable_backup,
    gitlab_branch                 => '7.5.1',
    gitlab_download_link          => $gitlab_download_link,  # Should be pulled from Hiera
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
    ldap_uid                      => 'sAMAccountName',

    #ssl configuration
    ssl_certificate               => '/etc/gitlab/ssl/gitlab.crt',
    ssl_certificate_key           => '/etc/gitlab/ssl/gitlab.key',
    redirect_http_to_https        => true,
    require                       => File['/etc/gitlab/ssl/gitlab.crt', '/etc/gitlab/ssl/gitlab.key']

  }

  #Set up s3 backups if on AWS
  if $::hosting_platform == AWS {

    package { 's3cmd':
      ensure  => present,
      require => Package[epel-release]
    }
    cron  { 's3-backup-syc':
      command => "s3cmd sync /var/opt/gitlab/backups s3://lr-gitlab-backups --access_key=${aws_acccess_key} --secret_key=${aws_secret_key}",
      user    => root,
      hour    => 2,
      minute  => 30
    }
  }

  #ensure that nfs package is installed
  #determin the package name based on the OS
  $nfs_package = $::operatingsystem ? {
    CentOS     => 'nfs-utils',
    Redhat     => 'nfs-utils',
    Ubuntu     => 'nfs-common',
  }

  package { $nfs_package :
    ensure => present
  }

  if $::hosting_platform == 'internal' {
    if $enable_backup == true {
        mount { '/var/opt/gitlab/backups':
          ensure  => 'mounted',
          device  => $backup_location,
          fstype  => 'nfs',
          options => 'defaults',
          atboot  => true,
          require => Package [ $nfs_package ]
      }
    }
  }

  file_line { 'internal smtp relay config':
    ensure => present,
    line   => "relayhost = ${smtp_relay}",
    path   => '/etc/postfix/main.cf',
  }
}
