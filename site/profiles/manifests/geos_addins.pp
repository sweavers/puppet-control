# Class profiles::geos_addins
#
# This class will manage geos_addins
#
# Sample Usage:
#   class { 'profiles::geos_addins': }
#
class profiles::geos_addins{

  include ::stdlib

  #  Install required packages for Ruby and Java
  case $::osfamily{
    'RedHat': {
      $PKGLIST=['geos','geos-devel']
      $PROVIDER= 'yum'
    }
    'Debian': {
      $PKGLIST=['libgeos-ruby1.8','libgeos-dev']
      $PROVIDER= 'apt'
    }
    default: {
      fail("Unsupported OS type - ${::osfamily}")
    }
  }
  package { $PKGLIST :
    ensure   => installed,
    provider => $PROVIDER,
    }
}
