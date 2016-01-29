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
  $version      = '9.4',
  $ssh_keys     = hiera_hash('postgresqlha_keys',false)
  ){

  $custom_hosts = template('profiles/postgres_hostfile_generation.erb')

  file { '/etc/hosts' :
    ensure  => file,
    content => $custom_hosts,
    owner   => 'root',
    mode    => '0644',
  }

  $pkglist = [
    'rsync',
    'barman'
  ]
  ensure_packages($pkglist)

  exec { 'get_pbarman' :
    command => "yum localinstall http://yum.postgresql.org/${version}/redhat/rhel-6-x86_64/pgdg-centos94-${version}-1.noarch.rpm -y",
    user    => 'root',
    before  => Package['barman']
  } ->

  service {'sshd' :
    ensure => running,
    enable => true,
  }

  file { '/etc/barman.conf' :
    ensure  => file,
    owner   => 'barman',
    group   => 'barman',
    content => template('profiles/postgres_barman_config.erb'),
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
  }

}
