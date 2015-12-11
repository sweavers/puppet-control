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
    'rsync'
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

  file { "/etc/repmgr/${version}/auto_failover.sh" :
    ensure  => file,
    owner   => 'postgres',
    source  => 'puppet:///extra_files/postgres_auto_failover.sh',
    require => Package['repmgr94'],
    mode    => '0555'
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

  # include postgresql::client
  # include postgresql::lib::devel

  file { "/etc/repmgr/${version}/repmgr.conf" :
    ensure  => file,
    content => template('profiles/postgres_repmgr_config.erb'),
    require => Package["repmgr${shortversion}"],
    #before  => Exec['standby_register_repmgrd'],
  }

  file { '/etc/keepalived/keepalived.conf' :
    ensure  => file,
    content => template('profiles/postgres_keepalived_config.erb'),
  }

  service {'keepalived' :
    ensure => running,
    enable => true,
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

  exec { 'clone_database_master' :
    command => "/usr/pgsql-${version}/bin/repmgr -D /var/lib/pgsql/${version}/data/ -d repmgr -U repmgr --verbose standby clone ${master_hostname}",
    user    => 'postgres',
    cwd     => "/etc/repmgr/${version}/",
    unless  => 'psql -c "select pg_is_in_recovery();" | grep "^ t$"',
  } #->

  # service { "postgresql-${version}" :
  #   ensure => running,
  #   enable => true
  # } ->
  #
  # exec { 'standby_register_repmgrd' :
  #   command => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf standby register",
  #   user    => 'root',
  #   require => File['/root/.pgpass'],
  #   unless  => "/usr/pgsql-${version}/bin/repmgr -f /etc/repmgr/${version}/repmgr.conf cluster show | grep \"standby | host=${this_hostname}\"",
  # } ->
  #
  # service { 'repmgr' :
  #   ensure  => running,
  #   enable  => true,
  #   require => File['/usr/lib/systemd/system/repmgr.service']
  # }

}
