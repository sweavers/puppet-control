# Class profiles::postgresql
#
# This class will manage MongoDB installations
#
# Parameters:
#  ['port']     - Port which MongoDB should listen on. Defaults = 27018
#  ['version']  - Version of MongoDB to install. Default = 2.6.7
#  ['remote']   - Should MongoDB listen for remote connections. Defaults true
#  ['dbroot']   - Location installation should be placed. Defaults = /mongodb
#  ['dbpath']   - Location of database. Defaults to $dbroot/data
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
class profiles::postgresql(

  $port     = 5432,
  $version  = '9.3',
  $remote   = true,
  $dbroot   = '/postgres',

){


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
    confdir             => "${dbroot}",
    require             => File[$dbroot]
  } ->

  class { 'postgresql::server':
    port             => $port,
    listen_addresses => $bind,
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

  include postgresql::client
  include postgresql::server::contrib
  include postgresql::server::postgis

}
