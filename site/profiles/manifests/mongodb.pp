# Class profiles::puppet
#
# This class will manage Puppet Agent and Master installations
#
# Parameters:
#  ['master'] - Boolean.
#
# Requires:
# - Hello
#
# Sample Usage:
#   class { 'profiles::puppet': }
#
class profiles::mongodb(

  $port    = 27018,
  $dbroot  = '/mongodb/',
  $dbpath  = 'data/',
  $config  = 'config/',
  $logpath = 'log/',

){

  file { $dbroot:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0777',
  }

  class {'mongodb::server':
    ensure  => present,
    port    => $port,
    verbose => true,
    auth    => true,
    dbpath  => "${dbroot}/${dbpath}",
    config  => "${dbroot}/${config}",
    journal => true,
    logpath => "${dbroot}/${logpath}/${::hostname}.log",
    rest    => true,
    require => File[$dbroot]
  }

}
