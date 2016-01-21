# Class profiles::postgresql
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
#
# pg_hba_rule:
#   test:
#     description: test
#     type: host
#     database: all
#     user: all
#     address: 0.0.0.0/0
#     auth_method: md5
#
# pg_db_grant:
#   deployment_select_sor:
#     privilege: SELECT
#     db: systemofrecord
#     role: deployment

class profiles::postgresql(

  $port          = 5432,
  $version       = '9.3',
  $remote        = true,
  $dbroot        = '/postgres',
  $databases     = hiera_hash('postgres_databases',false),
  $users         = hiera_hash('postgres_users', false),
  $pg_hba_rule   = hiera_hash('pg_hba_rule', false),
  $pg_db_grant   = hiera_hash('pg_db_grant', false)

){

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
    datadir             => "${dbroot}/data",
    confdir             => "${dbroot}/data",
    needs_initdb        => true,
    service_name        => 'postgresql', # confirm on ubuntu
    require             => File[$dbroot]
  } ->

  class { 'postgresql::server':
    port                    => $port,
    listen_addresses        => $bind,
    # The following needs to be replaced with propper hba managment
    ip_mask_allow_all_users => '0.0.0.0/0',
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

  package { $postgis_version :
    ensure => installed,
  }

  include postgresql::lib::devel

  if $databases {
    create_resources('postgresql::server::db', $databases)
  }
  if $users {
    create_resources('postgresql::server::role', $users)
  }
  #Will allow hba rules to be set for specific users/dbs via hiera
  if $pg_hba_rule {
    create_resources('postgresql::server::pg_hba_rule', $pg_hba_rule)
  }
  if $pg_db_grant {
    create_resources('postgresql::server::database_grant', $pg_db_grant)
  }

}
