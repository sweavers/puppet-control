# Class profiles::mongodb
#
# This class will manage MongoDB installations
#
# Parameters:
#  ['port']     - Port which MongoDB should listen on. Defaults = 27018
#  ['version']  - Version of MongoDB to install. Default = 2.6.7
#  ['remote']   - Should MongoDB listen for remote connections. Defaults true
#  ['password'] - Hex encoded MD5 of $username:mongo:$password for admin user
#  ['dbroot']   - Location installation should be placed. Defaults = /mongodb
#  ['dbpath']   - Location of database. Defaults to $dbroot/data
#  ['logpath']  - Location of log directory. Default = $dbroot/log
#
# Requires:
# - puppetlabs/mongodb
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::mongodb':
#     remote => ['192.168.1.2']
#   }
#
class profiles::mongodb(

  $port     = 27018,
  $version  = '2.6.7',
  $remote   = true,
  $password = '81cfce99f33d674bdd240d8c9d8ae44d', # 'mongodb'
  $dbroot   = '/mongodb',
  $dbpath   = 'data/',

){


  # Set bind address to 0.0.0.0 if remote is enabled, 127.0.0.1 if not
  # Merge remote into an address array if it's anything other than a boolean
  if $remote == true {
    $bind = '0.0.0.0'
  } elsif $remote == false {
    $bind = '127.0.0.1'
  } else {
    $bind_array = delete(any2array($remote),'127.0.0.1')
    $bind = concat(['127.0.0.1'],$bind_array)
  }

  # Use 10gen repositories instead of distribution's
  class { 'mongodb::globals':
    manage_package_repo => true,
    version             => $version
  }->

  class { 'mongodb::client':
    require => Class['Mongodb::globals']
  }

  class { 'mongodb::server':
    ensure  => present,
    port    => $port,
    bind_ip => $bind, # ? error
    verbose => true,
    auth    => true,
    dbpath  => "${dbroot}/${dbpath}",
    journal => true,
    rest    => false,
    require => [Class['Mongodb::client'],File[$dbroot]]
  }

  user { 'mongodb':
    ensure     => present,
    comment    => 'MongoDB Database Server',
    system     => true,
    home       => $dbroot,
    managehome => true,
    shell      => '/usr/sbin/nologin',
  }

  file { $dbroot:
    ensure  => 'directory',
    owner   => 'mongodb',
    group   => 'mongodb',
    mode    => '0750',
    require => User[mongodb]
  }

  package { ['mongodb-org-tools']:
    ensure => present,
    before => Class['mongodb::server']
  }

}
