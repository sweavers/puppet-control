# Class profiles::postgresq_standalone
#
# This class will manage PostgreSQL installations
#
# Parameters:
#  ['port']     - Port which PostgreSQL should listen on. Defaults = 5432
#  ['version']  - Version of PostgreSQL to install. Default = 9.4
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

class profiles::postgresql_standalone(
    $port          = 5432,
    $version       = '9.4',
    $remote        = true,
    $dbroot        = '/var/lib/pgsql',
    $databases     = hiera_hash('postgres_databases',false),
    $users         = hiera_hash('postgres_users', false),
    $extensions    = hiera_hash('postgres_extensions',false),
    $dbs           = hiera_hash('postgres_dbs', false),
    $ssh_keys      = hiera_hash('postgresqlha_keys',false),
    $postgres_conf = hiera_hash('postgres_conf',undef)
  ){

  case $version {
    '9.3': { $postgis_version = 'postgis2_93' }
    '9.4': { $postgis_version = 'postgis2_94' }
    '9.5': { $postgis_version = 'postgis2_95' }
    default: { $postgis_version = 'postgis2_94' }
  }

  $shortversion = regsubst($version, '\.', '')
  $custom_hosts = template('profiles/postgres_hostfile_generation.erb')

  file { '/etc/hosts' :
    ensure  => file,
    content => $custom_hosts,
    owner   => 'root',
    mode    => '0644',
  }

  $pkglist = [
    'rsync',
    'barman',
  ]

  ensure_packages( $pkglist , { 'before' => 'File[/var/lib/barman/.ssh]', 'require' => 'Class[postgresql::server]' } )

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
  } ->

  file { "${dbroot}/.pgsql_profile" :
    ensure  => 'file',
    content => "export PATH=\$PATH:/usr/pgsql-${version}/bin/",
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File[$dbroot]
  }

  file_line { 'enable_pgsql_profile' :
    ensure  => present,
    line    => "[ -f ${dbroot}/.pgsql_profile ] && source ${dbroot}/.pgsql_profile",
    match   => "^#*[ -f ${dbroot}/.pgsql_profile ] && source ${dbroot}/.pgsql_profile",
    path    => "${dbroot}/.bash_profile",
    require => File[$dbroot]
  }


  include ::stdlib

  package { $postgis_version :
    ensure  => installed,
    require => Class['postgresql::server'],
  }

  $barman_hostname = template('profiles/postgres_barman_hostname.erb')
  $pg_conf         = 'postgresql.conf'
  $pg_aux_conf     = 'postgresql.aux.conf'

  class { 'postgresql::globals' :
    manage_package_repo  => true,
    version              => $version,
    datadir              => "${dbroot}/${version}/data",
    confdir              => "${dbroot}/${version}/data",
    postgresql_conf_path => "${dbroot}/${version}/data/${pg_conf}",
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
  }

  postgresql_conf { 'include' :
    target  => $postgresql::globals::postgresql_conf_path,
    value   => "${postgresql::globals::confdir}/${pg_aux_conf}",
    require => Class['postgresql::server'],
  }

  $default_postgres_conf = {
    archive_command          => "\'rsync -aq %p barman@${barman_hostname}:primary/incoming/%f\'",
    archive_mode             => 'on',
    wal_level                => 'hot_standby',
  }

  if $postgres_conf { $hash = merge($default_postgres_conf, $postgres_conf)
  } else {
    $hash = $default_postgres_conf
  }

  file { "${postgresql::globals::confdir}${pg_aux_conf}" :
    content => template('profiles/postgres_aux_conf.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
    before  => Postgresql_conf['include'],
  }

  file { 'PSQL History' :
    ensure  => 'file',
    path    => "${dbroot}/.psql_history",
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File[$dbroot]
  }

  service {'sshd' :
    ensure => running,
    enable => true,
  }

  file { '/etc/puppetlabs/facter/facts.d/postgres_setup_done.sh' :
    ensure => file,
    source => 'puppet:///modules/profiles/postgres_setup_done.sh',
    owner  => 'root',
    mode   => '0755'
  } ->

  file { '/var/lib/pgsql/.ssh' :
    ensure => directory,
    owner  => 'postgres',
    mode   => '0700',
  } ->

  file { '/var/lib/pgsql/.ssh/config' :
    ensure  => file,
    content => 'StrictHostKeyChecking no',
    owner   => 'postgres',
    mode    => '0600',
  } ->

  file { '/var/lib/pgsql/.ssh/authorized_keys' :
    ensure  => file,
    content => $ssh_keys['public'],
    owner   => 'postgres',
    mode    => '0600',
  } ->

  file { '/var/lib/pgsql/.ssh/id_rsa' :
    ensure  => file,
    content => $ssh_keys['private'],
    owner   => 'postgres',
    mode    => '0600',
  } ->

  file { '/var/lib/pgsql/.ssh/id_rsa.pub' :
    ensure  => file,
    content => $ssh_keys['public'],
    owner   => 'postgres',
    mode    => '0644',
  }

  include postgresql::client
  include postgresql::server::contrib
  include postgresql::lib::devel

  if $users {
    create_resources('postgresql::server::role', $users,
      {before => Postgresql::Server::Role['barman']})
  }

  if $extensions {
    create_resources('postgresql::server::extension', $extensions)
  }

  if $databases {
    create_resources('postgresql::server::db', $databases,
      {before =>
        Postgresql::Server::Role['barman']})
  }

  $pg_hba_rules = parseyaml(template('profiles/postgres_hba_conf.erb'))
  create_resources('postgresql::server::pg_hba_rule', $pg_hba_rules,
    {before => Postgresql::Server::Role['barman']})


  postgresql::server::role { 'barman':
    login         => true,
    superuser     => true,
    password_hash => postgresql_password('barman', hiera('barman_password') )
  }

  file { '/var/lib/pgsql/.pgpass' :
    ensure  => file,
    content => template('profiles/pgpass_standalone.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
  } ->

  file { '/root/.pgpass' :
    ensure  => file,
    content => template('profiles/pgpass_standalone.erb'),
    mode    => '0600',
  }

  file { '/var/lib/barman/.ssh' :
    ensure => directory,
    owner  => 'barman',
    group  => 'barman',
    mode   => '0700'
  } ->

  file { '/var/lib/barman/.ssh/config' :
    ensure  => file,
    content => 'StrictHostKeyChecking no',
    owner   => 'barman',
    group   => 'barman',
    mode    => '0600',
  } ->

  file { '/var/lib/barman/.ssh/authorized_keys' :
    ensure  => file,
    content => $ssh_keys['public'],
    owner   => 'barman',
    group   => 'barman',
    mode    => '0600',
  } ->

  file { '/var/lib/barman/.ssh/id_rsa' :
    ensure  => file,
    content => $ssh_keys['private'],
    owner   => 'barman',
    group   => 'barman',
    mode    => '0600',
  } ->

  file { '/var/lib/barman/.ssh/id_rsa.pub' :
    ensure  => file,
    content => $ssh_keys['public'],
    owner   => 'barman',
    group   => 'barman',
    mode    => '0644',
  } ->

  file { '/var/lib/barman/.pgpass' :
    ensure  => file,
    content => template('profiles/pgpass_barman_server.erb'),
    owner   => 'barman',
    group   => 'barman',
    mode    => '0600',
  } ->

  file { '/var/lib/barman/primary' :
    ensure => directory,
    owner  => 'barman',
    group  => 'barman',
  } ->

  file { '/var/lib/barman/primary/incoming' :
    ensure => directory,
    owner  => 'barman',
    group  => 'barman',
  } ->

  cron { 'barman_backup_primary' :
    ensure  => present,
    user    => 'barman',
    command => 'barman backup primary',
    hour    => '17',
    minute  => '0',
    weekday => '5',
  } ->

  file { '/etc/barman.conf' :
    ensure  => file,
    owner   => 'barman',
    group   => 'barman',
    content => template('profiles/postgres_barman_config.erb'),
    mode    => '0600',
    require => Package['barman'],
  } ->

  cron { 'barman_cron' :
    ensure  => present,
    user    => 'barman',
    command => 'barman cron',
    minute  => '0',
  }

  if $::postgres_setup_done != 0 {

    exec { 'restart_postgres' :
      command => "systemctl restart postgresql-${version}; sleep 10",
      user    => 'root',
      require => Package['barman'],
    }

    exec { 'initalize_barman' :
      command => '/bin/barman switch-xlog primary',
      user    => 'barman',
      require => File['/etc/barman.conf'],
    }

    file { '/var/lib/pgsql/postgres_setup_done' :
      ensure  => file,
      owner   => 'postgres',
      group   => 'postgres',
      require => File['/etc/barman.conf'],
    }
  }
}
