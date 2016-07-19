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
# - vshn/gitlab
# - puppetlabs/firewall
#
# Sample Usage:
#   class { 'profiles::gitlab': }
#
class profiles::gitlab (

  $external_url    = 'http://localhost',
  $enable_backup   = false,
  $backup_location = 'undef',
  $gitlab_crt      = '',
  $gitlab_key      = '',
  $ldap_config     = 'puppet:///site/profiles/files/ldap_conf.erb',

){

  file { '/etc/gitlab' :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700'
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
    external_url        => $external_url,
    require             => File['/etc/gitlab/ssl/gitlab.crt', '/etc/gitlab/ssl/gitlab.key'],

    gitlab_rails        => {
      gitlab_default_theme  => 4,
      #ldap_enabled          => false,
      #ldap_servers          => $ldap_config,
      backup_path           => '/var/opt/gitlab/backups',
      backup_keep_time      => '5184000', # In seconds, 5184000 = 60 days
    },

    nginx               => {
      redirect_http_to_https => true,
      ssl_certificate        => '/etc/gitlab/ssl/gitlab.crt',
      ssl_certificate_key    => '/etc/gitlab/ssl/gitlab.key',
    },

    logging             => {
      svlogd_size     => 209715200,
      svlogd_num      => 30,
      svlogd_timeout  => 86400,
      svlogd_filter   => 'gzip',
    },
  }


  #Set up s3 backups if on AWS
  if $::hosting_platform == AWS {

    package { 's3cmd':
      ensure  => present,
    }
    cron  { 's3-backup-syc':
      command => "s3cmd sync /var/opt/gitlab/backups s3://lr-gitlab-backups --access_key=${aws_acccess_key} --secret_key=${aws_secret_key}",
      user    => root,
      hour    => 2,
      minute  => 30
    }
  }

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

}
