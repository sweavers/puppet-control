# Class profiles::postgresqlHA_standby
#
# This class will manage PostgreSQL standby node installations
#
# Requires:
# - puppetlabs/stdlib


class profiles::postgresqlha_standby (
    $version       = '9.4',
    $shortversion  = '94',
    $dbroot        = '/var/lib/pgsql/',
  ){

  $this_hostname = $::hostname
  $master_hostname = 'nodea'

  $pg_conf = "${dbroot}/${version}/data/postgresql.conf"

  include ::stdlib

  $pkglist = [
    'keepalived',
    'haproxy'
  ]

  exec { 'get_postgres_94' :
    command => "yum localinstall http://yum.postgresql.org/${version}/redhat/rhel-6-x86_64/pgdg-centos94-${version}-1.noarch.rpm -y",
    user    => 'root',
    before  => Package["postgresql${shortversion}-server"]
  } ->

  package { "postgresql${shortversion}-server" :
    ensure => present
  } ->

  package { "repmgr${shortversion}" :
    ensure => present
  }

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

  file { 'PSQL History':
    ensure  => 'file',
    path    => "${dbroot}/.psql_history",
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0750',
    require => File[$dbroot]
  }

  # include postgresql::client
  # include postgresql::lib::devel

  file { "/etc/repmgr/${version}/repmgr.conf":
    ensure  => file,
    content => template('profiles/postgres_repmgr_config.erb'),
    require => Package["repmgr${shortversion}"],
    before  => Exec['standby_register_repmgrd'],
  }

  file { '/etc/keepalived/keepalived.conf':
    ensure  => file,
    content => template('profiles/postgres_keepalived_config.erb'),
  }

  service {'keepalived':
    ensure => running,
    enable => true,
  }

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

  exec { 'clone_database_master':
    command => "/usr/pgsql-${version}/bin/repmgr -D /var/lib/pgsql/${version}/data/ -d repmgr -U repmgr --verbose standby clone ${master_hostname}",
    user    => 'postgres',
    cwd     => "/etc/repmgr/${version}/",
    unless  => 'psql -c "select pg_is_in_recovery();" | grep "^ t$"',
  } ->

  service { "postgresql-${version}":
    ensure => running,
    enable => true
  } ->

  exec { 'standby_register_repmgrd':
    command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf standby register",
    user    => 'root',
    require => File['/root/.pgpass'],
    unless  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show | grep \"standby | host=${this_hostname}\"",
  } ->

  service { 'repmgr':
    ensure  => running,
    enable  => true,
    require => File['/usr/lib/systemd/system/repmgr.service']
  }

}
