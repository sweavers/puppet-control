# Class profiles::geos_addins
#
# This class will manage geos_addins
#
# Sample Usage:
#   class { 'profiles::geos_addins': }
#
class profiles::geos_addins{

  include ::stdlib
  include ::profiles::deployment

  #  Install required packages for Ruby and Java
  case $::osfamily{
    'RedHat': {
      $PKGLIST=['geos','geos-devel']
    }
    'Debian': {
      $PKGLIST=['libgeos-ruby1.8','libgeos-dev']
    }
    default: {
      fail("Unsupported OS type - ${::osfamily}")
    }
  }
  ensure_packages($PKGLIST)
}
