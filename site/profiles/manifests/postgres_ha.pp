# Class profiles::postgresqlHA
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

class profiles::postgres_ha(
    $port           = 5432,
    $version        = '9.4',
    $remote         = true,
    $dbroot         = '/var/lib/pgsql',
    $databases      = hiera_hash('postgres_databases',false),
    $users          = hiera_hash('postgres_users', false),
    $dbs            = hiera_hash('postgres_dbs', false),
    $ssh_keys       = hiera_hash('postgresqlha_keys',false),
    $postgres_conf  = hiera_hash('postgres_conf',undef),
    $extensions     = hiera_hash('postgres_extensions',undef),
    $pg_hba_rule    = hiera_hash('postgres_hba_rule',undef),
    $pg_db_grant    = hiera_hash('postgres_db_grant',undef),
    $pg_table_grant = hiera_hash('postgres_table_grant',undef),
    $pg_grant       = hiera_hash('postgres_grant',undef)
  ){

  $shortversion = regsubst($version, '\.', '')
  $custom_hosts = template('profiles/postgres_hostfile_generation.erb')
  $postgis_version = "postgis2_${shortversion}"


  file { '/etc/hosts' :
    ensure  => file,
    content => $custom_hosts,
    owner   => 'root',
    mode    => '0644',
  }

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

  selinux::module { 'keepalivedlr' :
    ensure => 'present',
    source => 'puppet:///modules/profiles/keepalived_lr.te'
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
    content => template('profiles/postgres_pgsql_profile.erb'),
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File[$dbroot]
  }

  include ::stdlib

  package { $postgis_version :
    ensure  => installed,
    require => Class['postgresql::server'],
  }

  $master_hostname = template('profiles/postgres_master_hostname.erb')
  $vip_hostname    = template('profiles/postgres_vip_hostname.erb')
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
    before                  => Package["repmgr${shortversion}"],
  }

  postgresql_conf { 'include' :
    target  => $postgresql::globals::postgresql_conf_path,
    value   => "${postgresql::globals::confdir}/${pg_aux_conf}",
    require => Class['postgresql::server'],
  }

  $default_postgres_conf = {
    archive_command          => "\'rsync -aq %p barman@${barman_hostname}:primary/incoming/%f\'",
    archive_mode             => 'on',
    hot_standby              => 'on',
    max_replication_slots    => '10',
    max_wal_senders          => '10',
    shared_preload_libraries => 'repmgr_funcs',
    synchronous_commit       => 'on',
    wal_keep_segments        => '5000',
    wal_level                => 'hot_standby',
    wal_log_hints            => 'on',
  }

  if $postgres_conf { $hash = merge($default_postgres_conf, $postgres_conf)
  } else {
    $hash = $default_postgres_conf
  }

  file { "${postgresql::globals::confdir}/${pg_aux_conf}" :
    content => template('profiles/postgres_aux_conf.erb'),
    require => Class['postgresql::server'],
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600'
  }

  file_line { 'enable_pgsql_profile' :
    ensure  => present,
    line    => "[ -f ${dbroot}/.pgsql_profile ] && source ${dbroot}/.pgsql_profile",
    match   => "^#*[ -f ${dbroot}/.pgsql_profile ] && source ${dbroot}/.pgsql_profile",
    path    => "${dbroot}/.bash_profile",
    require => Class['postgresql::server']
  }

  file { "/etc/repmgr/${version}/auto_failover.sh" :
    ensure  => file,
    owner   => 'postgres',
    content => template('profiles/postgres_auto_failover.erb'),
    require => Package["repmgr${shortversion}"],
    mode    => '0544'
  }

  file { "${dbroot}/repmgr.conf" :
    ensure  => link,
    owner   => 'postgres',
    target  => "/etc/repmgr/${version}/repmgr.conf",
    require => Package["repmgr${shortversion}"]
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

  file { '/etc/puppetlabs/facter/facts.d/postgres_server_is_master.bash' :
    ensure => file,
    source => 'puppet:///modules/profiles/postgres_server_is_master.bash',
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

  if $::postgres_server_is_master == 't' or ($::hostname == $master_hostname and $::postgres_server_is_master == undef) {

    if $users {
      create_resources('postgresql::server::role', $users)
    }
    if $databases {
      create_resources('postgresql::server::db', $databases)
    }
    if $extensions {
      create_resources('postgresql::server::extension', $extensions)
    }
    if $pg_hba_rule {
      create_resources('postgresql::server::pg_hba_rule', $pg_hba_rule)
    }
    if $pg_db_grant {
      create_resources('postgresql::server::database_grant', $pg_db_grant)
    }
    if $pg_table_grant {
      create_resources('postgresql::server::table_grant', $pg_table_grant)
    }
    if $pg_grant {
      create_resources('postgresql::server::grant', $pg_grant)
    }
  }

  if $::postgres_server_is_master == undef {
    if $::hostname == $master_hostname {

      $repmgr_role = 'master'

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

      exec { 'initalize_xlog' :
        command => 'psql -c \'select pg_switch_xlog();\'',
        user    => 'postgres'
      } ->

      exec { 'restart_postgres' :
        command => "/bin/systemctl restart postgresql-${version}",
        user    => 'root',
        require => File ["${postgresql::globals::confdir}/${pg_aux_conf}"],
        before  => Exec['register_repmgrd'],
      }

    } else {

      $repmgr_role = 'standby'

      exec { 'stop_postgres' :
        command => "/bin/systemctl stop postgresql-${version}",
        user    => 'root',
        require => Class['postgresql::server']
      } ->

      exec { 'empty_postgres_data_dir' :
        command => "rm -rf ${postgresql::globals::datadir}/*",
        user    => 'postgres',
      } ->

      exec { 'clone_postgres' :
        command => "/usr/pgsql-${version}/bin/repmgr -r -F -D /var/lib/pgsql/${version}/data/ -d repmgr -U repmgr ${::wal_keep_segments} --verbose standby clone ${vip_hostname}",
        user    => 'postgres',
        cwd     => "/etc/repmgr/${version}/",
        timeout => '0',
        require => File["/etc/repmgr/${version}/repmgr.conf"]
      } ->

      exec { 'start_postgres' :
        command => "/bin/systemctl start postgresql-${version}",
        user    => 'root',
        before  => Exec['register_repmgrd']
      }

    }

  }

  $pg_hba_rules = parseyaml(template('profiles/postgres_hba_conf_file.erb'))
  create_resources('postgresql::server::pg_hba_rule', $pg_hba_rules)

  file { '/root/postgres_recover_former_master.bash' :
    content => template('profiles/postgres_recover_former_master.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0744'
  } ->

  file { '/root/postgres_standby_switchover.bash' :
    content => template('profiles/postgres_standby_switchover.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0744'
  } ->

  file { '/etc/sudoers.d/11_postgres' :
    content => template('profiles/sudoers.postgres.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0440'
  } ->

  file { "/etc/repmgr/${version}/repmgr.conf" :
    ensure  => file,
    content => template('profiles/postgres_repmgr_conf_file.erb'),
    require => Package["repmgr${shortversion}"],
    before  => Exec['register_repmgrd']
  } ->

  file { '/etc/keepalived/keepalived.conf' :
    ensure  => file,
    content => template('profiles/postgres_keepalived_conf_file.erb'),
    notify  => Service['keepalived'],
  } ->

  file { '/etc/keepalived/health_check.sh' :
    ensure  => file,
    content => template('profiles/keepalived_health_check.erb'),
    owner   => 'root',
    mode    => '0544',
  }

  service {'keepalived' :
    ensure  => running,
    enable  => true,
    require => [
      File['/etc/keepalived/keepalived.conf'],
      File['/etc/keepalived/health_check.sh']
    ],
  }

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

  exec { 'register_repmgrd' :
    command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf ${repmgr_role} register --force",
    user    => 'postgres',
    unless  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show 2> /dev/null | grep -q ${::hostname}",
  } ->

  service { 'repmgr' :
    ensure  => running,
    enable  => true,
    require => File['/usr/lib/systemd/system/repmgr.service']
  }

}
