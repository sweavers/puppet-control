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

class profiles::postgresqlha_barman(

    $port         = 5432,
    $version      = '9.4',
    $shortversion = '94',
    $remote       = true,
    $dbroot       = '/var/lib/pgsql'
  ){

  include ::stdlib

  # $master_hostname = 'nodea'
  $pg_conf = "${dbroot}/${version}/data/postgresql.conf"

  $pkglist = [
    # 'keepalived',
    # "repmgr${shortversion}"
    'barman'
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
    service_name         => "postgresql-${version}", # confirm on ubuntu
    require              => File[$dbroot],
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

  class { 'postgresql::server' :
    port                    => $port,
    listen_addresses        => $bind,
    ip_mask_allow_all_users => '0.0.0.0/0',
    require                 => Class['postgresql::globals'],
    # before                  => Package['repmgr94'],
  }

  # postgresql_conf { 'archive_command' :
  #   target  => $pg_conf,
  #   value   => 'cd .',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'wal_level' :
  #   target  => $pg_conf,
  #   value   => 'hot_standby',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'archive_mode' :
  #   target  => $pg_conf,
  #   value   => 'on',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'max_wal_senders' :
  #   target  => $pg_conf,
  #   value   => '10',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'wal_keep_segments' :
  #   target  => $pg_conf,
  #   value   => '5000',   # 80 GB required on pg_xlog
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'hot_standby' :
  #   target  => $pg_conf,
  #   value   => 'on',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'shared_preload_libraries' :
  #   target  => $pg_conf,
  #   value   => 'repmgr_funcs',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'max_replication_slots' :
  #   target  => $pg_conf,
  #   value   => '10',
  #   require => Class['postgresql::server'],
  # }
  #
  # postgresql_conf { 'synchronous_commit' :
  #   target  => $pg_conf,
  #   value   => 'on',
  #   require => Class['postgresql::server'],
  # }

  if $::osfamily == 'RedHat' {
    file { '/usr/lib/systemd/system/postgresql.service' :
      ensure => link,
      target => "/usr/lib/systemd/system/postgresql-${version}.service",
      force  => true,
      before => Class[Postgresql::Server]
    }
  }

  # file { "/etc/repmgr/${version}/auto_failover.sh" :
  #   ensure  => file,
  #   owner   => 'postgres',
  #   source  => 'puppet:///extra_files/postgres_auto_failover.sh',
  #   require => Package['repmgr94'],
  #   mode    => '0544'
  # }

  # case $version {
  #   '9.3': { $postgis_version = 'postgis2_93' }
  #   '9.4': { $postgis_version = 'postgis2_94' }
  #   default: { $postgis_version = 'postgis2_93' }
  # }
  #
  # file { 'PSQL History' :
  #   ensure  => 'file',
  #   path    => "${dbroot}/.psql_history",
  #   owner   => 'postgres',
  #   group   => 'postgres',
  #   mode    => '0750',
  #   require => File[$dbroot]
  # }

  include postgresql::client
  include postgresql::server::contrib
  #include postgresql::server::postgis

  # package { $postgis_version :
  #   ensure => installed,
  # }

  include postgresql::lib::devel

  # if $users {
  #   create_resources('postgresql::server::role', $users)
  # }

  # if $databases {
  #   create_resources('postgresql::server::db', $databases)
  # }

  # if $pg_hba_rule {
  #   create_resources('postgresql::server::pg_hba_rule', $pg_hba_rule)
  # }

  service {'sshd' :
    ensure => running,
    enable => true,
  }

  file { '/etc/ssh/ssh_config' :
    ensure => file,
    source => 'puppet:///extra_files/postgres_ssh_config',
    owner  => 'root',
    mode   => '0644',
    notify => Service['sshd']
  }

  file { '/etc/barman.conf' :
    ensure => file,
    owner  => 'barman',
    source => 'puppet:///extra_files/postgres_barman_config',
    mode   => '0600',
  }

  file { '/var/lib/pgsql/.ssh' :
    ensure => directory,
    owner  => 'postgres',
    mode   => '0700',
  } ->

  file { '/var/lib/barman/.ssh/authorized_keys' :
    ensure  => file,
    content => template('profiles/postgres_authorized_keys.erb'),
    owner   => 'barman',
    mode    => '0600',
  } ->

  file { '/var/lib/barman/.ssh/id_rsa' :
    ensure  => file,
    content => template('profiles/postgres_id_rsa.erb'),
    owner   => 'barman',
    mode    => '0600',
  } ->

  file { '/var/lib/barman/.ssh/id_rsa.pub' :
    ensure  => file,
    content => template('profiles/postgres_id_rsa_public.erb'),
    owner   => 'barman',
    mode    => '0644',
  }

  file { '/var/lib/barman/.pgpass' :
    ensure  => file,
    content => template('profiles/pgpass_barman_server.erb'),
    owner   => 'barman',
    group   => 'barman',
    mode    => '0600',
  }

  # file { "/etc/repmgr/${version}/repmgr.conf" :
  #   ensure  => file,
  #   content => template('profiles/postgres_repmgr_config.erb'),
  #   require => Package["repmgr${shortversion}"],
  #   before  => Exec['master_register_repmgrd'],
  # }

  # file { '/etc/keepalived/keepalived.conf' :
  #   ensure  => file,
  #   content => template('profiles/postgres_keepalived_config.erb'),
  # }

  # service {'keepalived' :
  #   ensure => running,
  #   enable => true,
  # }
  #
  # postgresql::server::role { 'repmgr':
  #   login         => true,
  #   superuser     => true,
  #   replication   => true,
  #   password_hash => postgresql_password('repmgr', hiera('repmgr_password') )
  # } ->
  #
  # postgresql::server::database { 'repmgr' :
  #   owner  => 'repmgr'
  # } ->

  # file { '/usr/lib/systemd/system/repmgr.service' :
  #   ensure  => file,
  #   owner   => 'postgres',
  #   group   => 'postgres',
  #   mode    => '0664',
  #   content => template('profiles/repmgrd.service.erb')
  # } ->

  # file { '/var/lib/pgsql/.pgpass' :
  #   ensure  => file,
  #   content => template('profiles/pgpass.erb'),
  #   owner   => 'postgres',
  #   group   => 'postgres',
  #   mode    => '0600',
  # } ->
  #
  # file { '/root/.pgpass' :
  #   ensure  => file,
  #   content => template('profiles/pgpass.erb'),
  #   mode    => '0600',
  # } ->

  # exec { 'master_register_repmgrd' :
  #   command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf master register",
  #   user    => 'root',
  #   require => File['/root/.pgpass'],
  #   unless  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show",
  # } ->
  #
  # service { 'repmgr' :
  #   ensure  => running,
  #   enable  => true,
  #   require => File['/usr/lib/systemd/system/repmgr.service']
  # } ->
  #
  # exec { 'restart_postgres' :
  #   command => "/bin/systemctl restart postgresql-${version}",
  #   user    => 'root',
  # }
}
