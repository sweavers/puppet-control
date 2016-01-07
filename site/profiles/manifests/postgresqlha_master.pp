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

class profiles::postgresqlha_master(

    $port          = 5432,
    $version       = '9.4',
    $shortversion  = '94',
    $remote        = true,
    $dbroot        = '/var/lib/pgsql',
    $databases     = hiera_hash('postgres_databases',false),
    $users         = hiera_hash('postgres_users', false),
    $pg_hba_rule   = hiera_hash('pg_hba_rule', false),
    $dbs           = hiera_hash('postgres_dbs', false)
  ){

  if $postgres_ha_setup_done != 0 {

    include ::stdlib

    $master_hostname = 'nodea'
    $pg_conf = "${dbroot}/${version}/data/postgresql.conf"

    $pkglist = [
      'keepalived',
      'rsync',
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
    } ->

    file { "$dbroot/.pgsql_profile" :
      ensure  => 'file',
      content => "export PATH=\$PATH:/usr/pgsql-${version}/bin/",
      owner   => 'postgres',
      group   => 'postgres',
      mode    => '0750',
      require => File[$dbroot]
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
      before                  => Package["repmgr${shortversion}"],
    }

    postgresql_conf { 'archive_command' :
      target  => $pg_conf,
      value   => 'rsync -aq %p barman@bart:primary/incoming/%f',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'wal_level' :
      target  => $pg_conf,
      value   => 'hot_standby',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'archive_mode' :
      target  => $pg_conf,
      value   => 'on',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'max_wal_senders' :
      target  => $pg_conf,
      value   => '10',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'wal_keep_segments' :
      target  => $pg_conf,
      value   => '5000',   # 80 GB required on pg_xlog
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'hot_standby' :
      target  => $pg_conf,
      value   => 'on',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'shared_preload_libraries' :
      target  => $pg_conf,
      value   => 'repmgr_funcs',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'max_replication_slots' :
      target  => $pg_conf,
      value   => '10',
      require => Class['postgresql::server'],
    }

    postgresql_conf { 'synchronous_commit' :
      target  => $pg_conf,
      value   => 'on',
      require => Class['postgresql::server'],
    }

    file { "/etc/repmgr/${version}/auto_failover.sh" :
      ensure  => file,
      owner   => 'postgres',
      source  => 'puppet:///extra_files/postgres_auto_failover.sh',
      require => Package["repmgr${shortversion}"],
      mode    => '0544'
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

    file { '/etc/ssh/ssh_config' :
      ensure => file,
      source => 'puppet:///extra_files/postgres_ssh_config',
      owner  => 'root',
      mode   => '0644',
      notify => Service['sshd']
    }

    file { '/etc/puppetlabs/facter/facts.d/postgres_ha_setup_done.sh' :
      ensure => file,
      source => 'puppet:///extra_files/postgres_ha_setup_done.sh',
      owner  => 'root',
      mode   => '0755'
    } ->

    file { '/var/lib/pgsql/.ssh' :
      ensure => directory,
      owner  => 'postgres',
      mode   => '0700',
    } ->

    file { '/var/lib/pgsql/.ssh/authorized_keys' :
      ensure  => file,
      content => template('profiles/postgres_authorized_keys.erb'),
      owner   => 'postgres',
      mode    => '0600',
    } ->

    file { '/var/lib/pgsql/.ssh/id_rsa' :
      ensure  => file,
      content => template('profiles/postgres_id_rsa.erb'),
      owner   => 'postgres',
      mode    => '0600',
    } ->

    file { '/var/lib/pgsql/.ssh/id_rsa.pub' :
      ensure  => file,
      content => template('profiles/postgres_id_rsa_public.erb'),
      owner   => 'postgres',
      mode    => '0644',
    }

    include postgresql::client
    include postgresql::server::contrib
    include postgresql::lib::devel

    if $users {
      create_resources('postgresql::server::role', $users)
    }

    if $databases {
      create_resources('postgresql::server::db', $databases)
    }

    if $pg_hba_rule {
      create_resources('postgresql::server::pg_hba_rule', $pg_hba_rule)
    }

    file { "/etc/repmgr/${version}/repmgr.conf" :
      ensure  => file,
      content => template('profiles/postgres_repmgr_config.erb'),
      require => Package["repmgr${shortversion}"],
      before  => Exec['master_register_repmgrd'],
    }

    file { '/etc/keepalived/keepalived.conf' :
      ensure  => file,
      content => template('profiles/postgres_keepalived_config.erb'),
    }

    service {'keepalived' :
      ensure => running,
      enable => true,
    }

    postgresql::server::role { 'repmgr':
      login         => true,
      superuser     => true,
      replication   => true,
      password_hash => postgresql_password('repmgr', hiera('repmgr_password') )
    } ->

    postgresql::server::role { 'barman':
      login         => true,
      superuser     => true,
      password_hash => postgresql_password('barman', hiera('barman_password') )
    } ->

    postgresql::server::database { 'repmgr' :
      owner  => 'repmgr'
    } ->
    # Running postgresql-9.4 as a systemd service causes issues when postgres
    # clustering is being manged by repmgr, so we stop and disable it immediatly
    # after installation by puppet. Postgres is managed by pg_ctl from then on.
    exec { 'stop_postgres' :
      command => "/bin/systemctl stop postgresql-${version}",
      user    => 'root',
    } ->

    exec { 'disable_postgres' :
      command => "/bin/systemctl disable postgresql-${version}",
      user    => 'root',
    } ->

    exec { 'master_start_postgres' :
      command => "/usr/pgsql-${version}/bin/pg_ctl -D ${postgresql::globals::datadir} start",
      user    => 'postgres',
    } ->

    file { '/usr/lib/systemd/system/repmgr.service' :
      ensure  => file,
      owner   => 'postgres',
      group   => 'postgres',
      mode    => '0664',
      content => template('profiles/repmgrd.service.erb')
    } ->

    file { '/var/lib/pgsql/.pgpass' :
      ensure  => file,
      content => template('profiles/pgpass.erb'),
      owner   => 'postgres',
      group   => 'postgres',
      mode    => '0600',
    } ->

    file { '/root/.pgpass' :
      ensure  => file,
      content => template('profiles/pgpass.erb'),
      mode    => '0600',
    } ->

    exec { 'master_register_repmgrd' :
      command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf master register",
      user    => 'root',
      require => File['/root/.pgpass'],
      unless  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show",
    } ->

    service { 'repmgr' :
      ensure  => running,
      enable  => true,
      require => File['/usr/lib/systemd/system/repmgr.service']
    } ->

    exec { 'reload_postgres' :
      command => "/usr/pgsql-${version}/bin/pg_ctl -D ${postgresql::globals::datadir} reload -m immediate",
      user    => 'postgres',
    } ->

    file { '/var/lib/pgsql/postgres_ha_setup_done' :
      ensure  => file,
      owner   => 'postgres',
      group   => 'postgres',
      require => Service['repmgr'],
    }
  }
}
