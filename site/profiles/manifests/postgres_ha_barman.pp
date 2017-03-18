# Class profiles::postgresqlha_barman
#
# This class will manage Postgres Barman installations
#

class profiles::postgres_ha_barman(
  $version      = '9.4',
  $ssh_keys     = hiera_hash('postgresqlha_keys',false)
  ){

  $shortversion = regsubst($version, '\.', '')
  $custom_hosts = template('profiles/postgres_hostfile_generation.erb')

  file { '/etc/hosts' :
    ensure  => file,
    content => $custom_hosts,
    owner   => 'root',
    mode    => '0644',
    before  => Package['barman'],
  }

  $pkglist = [
    'rsync',
    "postgresql${shortversion}",
    'barman'
  ]
  ensure_packages($pkglist)

  exec { 'get_postgres' :
    command => "yum localinstall http://yum.postgresql.org/${version}/redhat/rhel-7-x86_64/pgdg-centos${shortversion}-${version}-3.noarch.rpm -y",
    user    => 'root',
    before  => Package["postgresql${shortversion}"]
  } ->

  service {'sshd' :
    ensure => running,
    enable => true,
  } ->

  file { '/etc/barman.conf' :
    ensure  => file,
    owner   => 'barman',
    group   => 'barman',
    content => template('profiles/postgres_barman_conf_file.erb'),
    mode    => '0600',
    require => Package['barman'],
  } ->

  file { '/var/lib/barman/.ssh' :
    ensure => directory,
    owner  => 'barman',
    group  => 'barman',
    mode   => '0700',
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
    content => template('profiles/pgpass.erb'),
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

  file { '/var/lib/barman/.bash_profile' :
    ensure  => present,
    content => "export PATH+=:/usr/pgsql-${version}/bin",
    owner   => 'barman',
    group   => 'barman',
    mode    => '0700',
  } ->

  file { '/var/lib/barman/.bashrc' :
    ensure  => present,
    content => "export PATH+=:/usr/pgsql-${version}/bin",
    owner   => 'barman',
    group   => 'barman',
    mode    => '0700',
  } ->

  # exec { 'initialise_barman' :
  #   command => 'barman receive-wal --create-slot primary && barman cron && barman switch-xlog && barman cron',
  #   user    => 'barman',
  #   require => [
  #     Package["postgresql${shortversion}"],
  #     Package['barman']
  #   ],
  #   unless  => 'test -s /var/lib/barman/primary/wals/xlog.db',
  # } ->

  cron { 'barman_cron' :
    ensure  => present,
    user    => 'barman',
    command => 'barman cron',
    minute  => '*',
  }

}
