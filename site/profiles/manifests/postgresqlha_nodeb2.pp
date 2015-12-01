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


class profiles::postgresqlha_nodeb2(

    $port          = 5432,
    $version       = '9.4',
    $shortversion  = '94',
    $remote        = true,
    $dbroot        = '/var/lib/pgsql/',
    # $databases     = hiera_hash('postgres_databases',false),
    # $users         = hiera_hash('postgres_users', false),
    $pg_hba_rule   = hiera_hash('pg_hba_rule', false),
    # $dbs           = hiera_hash('postgres_dbs', false),
    $repmgr_hash   = 'md58ea99ab1ec3bd8d8a6162df6c8e1ddcd',

  ){

  $pg_conf = "${dbroot}/${version}/data/postgresql.conf"

  include ::stdlib

  $pkglist = [
    'rsync',
    'keepalived',
    'haproxy',
    "repmgr${shortversion}"
  ]
  ensure_packages($pkglist)

  user { 'postgres' :
    ensure     => present,
    comment    => 'PostgreSQL Database Server',
    system     => true,
    home       => $dbroot,
    managehome => true,
    shell      => '/bin/bash',
  }

  file { $dbroot :
    ensure  => 'directory',
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => User[postgres]
  }

  class { 'postgresql::globals' :
    manage_package_repo  => true,
    version              => $version,
    datadir              => "${dbroot}/${version}/data",
    confdir              => "${dbroot}/${version}/data",
    postgresql_conf_path => $pg_conf,
    needs_initdb         => true,
    service_name         => "postgresql-${version}",
    require              => File[$dbroot],
  }

  # # Set bind address to 0.0.0.0 if remote is enabled, 127.0.0.1 if not
  # # Merge remote into an address array if it's anything other than a boolean
  if $remote == true {
    $bind = '*'
  } elsif $remote == false {
    $bind = '127.0.0.1'
  } else {
    $bind_array = delete(any2array($remote),'127.0.0.1')
    $bind = join(concat(['127.0.0.1'],$bind_array),',')
  }

  class { 'postgresql::server':
    port                    => $port,
    listen_addresses        => $bind,
    ip_mask_allow_all_users => '0.0.0.0/0',
    require                 => Class['postgresql::globals'],
    before                  => Package["repmgr${shortversion}"],
  }

  postgresql_conf { 'archive_command':
    target  => $::pg_conf,
    value   => 'cd .',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'wal_level':
    target  => $::pg_conf,
    value   => 'hot_standby',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'archive_mode':
    target  => $::pg_conf,
    value   => 'on',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'max_wal_senders':
    target  => $::pg_conf,
    value   => '10',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'wal_keep_segments':
    target  => $::pg_conf,
    value   => '5000',   # 80 GB required on pg_xlog
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'hot_standby':
    target  => $::pg_conf,
    value   => 'on',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'shared_preload_libraries':
    target  => $::pg_conf,
    value   => 'repmgr_funcs',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'max_replication_slots':
    target  => $::pg_conf,
    value   => '10',
    require => Class['postgresql::server'],
  }

  postgresql_conf { 'synchronous_commit':
    target  => $::pg_conf,
    value   => 'on',
    require => Class['postgresql::server'],
  }

  if $::osfamily == 'RedHat' {
    file { '/usr/lib/systemd/system/postgresql.service':
      ensure => link,
      target => "/usr/lib/systemd/system/postgresql-${version}.service",
      force  => true,
      before => Class[Postgresql::Server]
    }
  }


  file { "/etc/repmgr/${version}/auto_failover.sh":
    ensure  => file,
    source  => 'puppet:///extra_files/postgres_auto_failover.sh',
    require => Package['repmgr94']
  }

  file { '/etc/haproxy/haproxy.cfg':
    ensure  => file,
    source  => 'puppet:///extra_files/postgres_haproxy.cfg',
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

  # case $version {
  #   '9.3': { $postgis_version = 'postgis2_93' }
  #   '9.4': { $postgis_version = 'postgis2_94' }
  #   default: { $postgis_version = 'postgis2_93' }
  # }

  file { 'PSQL History':
    ensure  => 'file',
    path    => "${dbroot}/.psql_history",
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File[$dbroot]
  }

  include postgresql::client
  #include postgresql::server::contrib
  #include postgresql::server::postgis

  # package { $postgis_version :
  #   ensure => installed,
  # }

  include postgresql::lib::devel

  # if $users {
  #   create_resources('postgresql::server::role', $users)
  # }
  #
  # if $databases {
  #   create_resources('postgresql::server::db', $databases)
  # }
  #
  #Will allow hba rules to be set for specific users/dbs via hiera
  # if $pg_hba_rule {
  #   create_resources('postgresql::server::pg_hba_rule', $pg_hba_rule)
  # }



  file { "/etc/repmgr/${version}/repmgr.conf":
    ensure  => file,
    source  => 'puppet:///extra_files/postgres_repmgr_nodeb.conf',
    require => Package["repmgr${shortversion}"],
    before  => Exec['standby_register_repmgrd'],
  }

  file { '/etc/keepalived/keepalived.conf':
    ensure => file,
    source => 'puppet:///extra_files/postgres_keepalived_nodeb.conf',
  }

  # file { "/var/lib/pgsql/${version}/data/postgresql.conf":
  #   ensure => file,
  #   source => 'puppet:///extra_files/postgres_postgresql.conf',
  # }

  # file { '/var/lib/pgsql/data/pg_hba.conf':
  #   ensure => file,
  #   source => 'puppet:///extra_files/postgres_pg_hba.conf',
  # }

  service {'keepalived':
    ensure => running,
    enable => true,
  }

  # postgresql::server::role { 'repmgr':
  #   #ensure        => present,
  #   login         => true,
  #   superuser     => true,
  #   replication   => true,
  #   password_hash => $repmgr_hash
  # } ->

  # postgresql::server::database { 'repmgr':
  #   #ensure => present,
  #   owner  => 'repmgr'#,
  #   #require => Postgresql::server::role['repmgr']
  # } ->

  file { '/usr/lib/systemd/system/repmgr.service':
    ensure  => file,
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0664',
    content => template('profiles/repmgrd.service.erb')
  } ->

  file { '/var/lib/pgsql/.pgpass':
    ensure => file,
    source => 'puppet:///extra_files/.pgpass',
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0600',
  } ->

  file { '/root/.pgpass':
    ensure => file,
    source => 'puppet:///extra_files/.pgpass',
    mode   => '0600',
  } ->

  # exec { 'delete_data_dir':
  #   command => "rm -rf /var/lib/pgsql/${version}/data/*",
  #   user    => root,
  #   require => Package["repmgr${shortversion}"],
  #   unless  => "su - postgres -c 'psql -c \"select pg_is_in_recovery();\" | grep \"^ t$\"'",
  # } ->

  exec { 'clone_database_master':
    command => "/usr/pgsql-${version}/bin/repmgr -D /var/lib/pgsql/${version}/data/ -U repmgr --verbose standby clone nodea -F",
    user    => 'postgres',
    cwd     => "/etc/repmgr/${version}/",
    unless  => "su - postgres -c 'psql -c \"select pg_is_in_recovery();\" | grep \"^ t$\"'",
  } ->

  exec { 'standby_register_repmgrd':
    command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf standby register",
    user    => 'root',
    require => File['/root/.pgpass'],
    unless  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show | grep nodeb",
    #onlyif  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show | grep -v '* master' | grep host=nodea"],
  } ->

  service { 'repmgr':
    ensure  => running,
    enable  => true,
    require => File['/usr/lib/systemd/system/repmgr.service']
  }

}
