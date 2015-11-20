# Class profiles::postgresqlHA
#
# This class will manage PostgreSQL installations
#
# Parameters:
#  ['port']     - Port which PostgreSQL should listen on. Defaults = 5432
#  ['version']  - Version of PostgreSQL to install. Default = 9.3
#  ['remote']   - Should PostgreSQL listen for remote connections. Defaults true
#  ['dbroot']   - Location installation should be placed. Defaults = /postgres
#
# Requires:
# - puppetlabs/postgresql
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::postgresql':
#     remote => ['192.168.1.2']
#   }
#
# Hiera Lookups:
#
# postgres_databases:
#   systemofrecord:
#    user: systemofrecord
#    password: md511c5a6395e27555ef43eb7b05c76d7c1
#    owner: systemofrecord

# postgres_users:
#   deployment:
#     password_hash: md5dddbab2fa26c65fadeaa8b1076329a14
#
##
# pg_hba_rule:
#   test:
#     description: test
#     type: host
#     database: all
#     user: all
#     address: 0.0.0.0/0
#     auth_method: md5
#

class profiles::postgresqlha(

    $port          = 5432,
    $version       = '9.4',
    $shortversion  = '94',
    $remote        = true,
    $dbroot        = "/var/lib/pgsql/${version}",
    $databases     = hiera_hash('postgres_databases',false),
    $users         = hiera_hash('postgres_users', false),
    $pg_hba_rule   = hiera_hash('pg_hba_rule', false),
    $dbs           = hiera_hash('postgres_dbs', false)

  ){


  package {"repmgr${shortversion}":
    ensure => present,
    before => [
        File["/etc/repmgr/${version}/auto_failover.sh"],
        File["/etc/repmgr/${version}/repmgr.conf"],
    ],
  }

  package {'rsync':
    ensure => present,
  }

  package {'keepalived':
    ensure => present,
  }

  package {'haproxy':
    ensure => present,
  }

  file { "/etc/repmgr/${version}/auto_failover.sh":
    ensure => file,
    source => '/vagrant/puppet-control/site/profiles/files/postgres_auto_failover.sh',
  }

  file { '/etc/haproxy/haproxy.cfg':
    ensure  => file,
    source  => '/vagrant/puppet-control/site/profiles/files/postgres_haproxy.cfg',
    require => Package['haproxy'],
    notify  => Service['haproxy']
  }

  service {'haproxy':
    ensure    => running,
    enable    => true,
    require   => File['/etc/haproxy/haproxy.cfg'],
    subscribe => File['/etc/haproxy/haproxy.cfg']
  }

  # service {"postgresql-${version}":
  #   ensure => running,
  #   enable => true,
  # }

  case $version {
    '9.3': { $postgis_version = 'postgis2_93' }
    '9.4': { $postgis_version = 'postgis2_94' }
    default: { $postgis_version = 'postgis2_93' }
  }

  # Set bind address to 0.0.0.0 if remote is enabled, 127.0.0.1 if not
  # Merge remote into an address array if it's anything other than a boolean
  if $remote == true {
    $bind = '*'
  } elsif $remote == false {
    $bind = '127.0.0.1'
  } else {
    $bind_array = delete(any2array($remote),'127.0.0.1')
    $bind = join(concat(['127.0.0.1'],$bind_array),',')
  }

  class { 'postgresql::globals':
    manage_package_repo => true,
    version             => $version,
    datadir             => "${dbroot}/${version}/data",
    confdir             => "${dbroot}/${version}/data",
    needs_initdb        => true,
    service_name        => "postgresql-${version}", # confirm on ubuntu
    require             => File[$dbroot]
  } ->

  class { 'postgresql::server':
    port                    => $port,
    listen_addresses        => $bind,
    # The following needs to be replaced with propper hba managment
    ip_mask_allow_all_users => '0.0.0.0/0',
    before                  => [
          Package[ "repmgr${shortversion}"],
          File["/var/lib/pgsql/${version}/data/postgresql.conf"],
    ],
  }

  user { 'postgres':
    ensure     => present,
    comment    => 'PostgreSQL Database Server',
    system     => true,
    home       => $dbroot,
    managehome => true,
    shell      => '/bin/bash',
  }

  file { $dbroot:
    ensure  => 'directory',
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => User[postgres]
  }

  file { 'PSQL History':
    ensure  => 'file',
    path    => "${dbroot}/.psql_history",
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File[$dbroot]
  }

  if $::osfamily == 'RedHat' {
    file { '/usr/lib/systemd/system/postgresql.service':
      ensure => link,
      target => "/usr/lib/systemd/system/postgresql-${version}.service",
      force  => true,
      before => Class[Postgresql::Server]
    }
  }


  include stdlib
  include postgresql::client
  include postgresql::server::contrib
  #include postgresql::server::postgis

  # package { $postgis_version :
  #   ensure => installed,
  # }

  include postgresql::lib::devel

  if $users {
    create_resources('postgresql::server::role', $users)
    if $dbs {
      create_resources('postgresql::server::database', $dbs)
    }
  }

  if $databases {
    create_resources('postgresql::server::db', $databases)
  } ->

  #Will allow hba rules to be set for specific users/dbs via hiera
  if $pg_hba_rule {
    create_resources('postgresql::server::pg_hba_rule', $pg_hba_rule)
  }



  file { "/etc/repmgr/${version}/repmgr.conf":
    ensure => file,
    source => '/vagrant/puppet-control/site/profiles/files/postgres_repmgr_nodea.conf',
    before => Exec['master_register_repmgrd'],

  }

  file { '/etc/keepalived/keepalived.conf':
    ensure => file,
    source => '/vagrant/puppet-control/site/profiles/files/postgres_keepalived_nodea.conf',
  }

  file { "/var/lib/pgsql/${version}/data/postgresql.conf":
    ensure => file,
    source => '/vagrant/puppet-control/site/profiles/files/postgres_postgresql.conf',
  }




  # file { '/var/lib/pgsql/data/pg_hba.conf':
  #   ensure => file,
  #   source => '/vagrant/puppet-control/site/profiles/files/postgres_pg_hba.conf',
  # }

  service {'keepalived':
    ensure => running,
    enable => true,
  }



  file { '/root/.pgpass':
    ensure => file,
    source => '/vagrant/puppet-control/site/profiles/files/.pgpass',
    mode   => '0600',
  } ->

  exec { 'master_register_repmgrd':
    command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf master register",
    user    => 'root',
  } ->

  exec { 'start_repmgrd':
    command => "/usr/pgsql-${version}/bin/repmgrd -f /etc/repmgr/${version}/repmgr.conf --daemonize",
    user    => 'postgres',
  }

}
