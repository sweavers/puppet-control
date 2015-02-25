# Class profiles::mongodb
#
# This class will manage MongoDB installations
#
# Parameters:
#  ['port']     - Port which MongoDB should listen on. Defaults = 27018
#  ['version']  - Version of MongoDB to install. Default = 2.6.7
#  ['remote']   - Should MongoDB listen for remote connections. Defaults true
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

  $port     = 27017,
  $version  = '2.6.7',
  $remote   = true,

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

  # Red Hat uses weird version numbers
  if $::osfamily == 'RedHat' {
    $ver = "${version}-1"
  } else {
    $ver = $version
  }

  # Use 10gen repositories instead of distribution's
  class { 'mongodb::globals':
    manage_package_repo => true,
    version             => $ver
  }->

  class { 'mongodb::client':
    require => Class['Mongodb::globals']
  }

  class { 'mongodb::server':
    ensure  => present,
    port    => $port,
    bind_ip => $bind,
    verbose => true,
    auth    => true,
    journal => true,
    rest    => false,
    require => [Class['Mongodb::client']]
  }

  package { ['mongodb-org-tools']:
    ensure => present,
    before => Class['mongodb::server']
  }

}
