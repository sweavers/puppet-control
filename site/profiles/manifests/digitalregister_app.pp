# Class profiles::digitalregister_app
#
# This class will manage api server installations
#
# Requires:
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::digitalregister_app': }
#
class profiles::digitalregister_app{

  include ::stdlib
  include ::profiles::deployment
  include ::profiles::nginx

  #  Install required packages for Ruby and Java
  case $::osfamily{
    'RedHat': {
      $PKGLIST=['python','python-devel','python-pip','epel-release']
      $PYTHON='lr-python3-3.4.3-1.x86_64'
      $PYPGK="${PYTHON}.rpm"
      $PKGMAN='rpm'
    }
    'Debian': {
      $PKGLIST=['python','python-dev','python-pip']
      $PYTHON='lr-python3_3.4.3_amd64'
      $PYPGK="${PYTHON}.deb"
      $PKGMAN='dpkg'
    }
    default: {
      fail("Unsupported OS type - ${::osfamily}")
    }
  }
  ensure_packages($PKGLIST)

  file{'LR Python package':
    ensure => 'file',
    path   => "/tmp/${PYPGK}",
    source => "puppet:///modules/profiles/${PYPGK}"
  }

  # Install custom Python 3.4.3 build
  package{ $PYTHON :
    ensure   => installed,
    provider => $PKGMAN,
    source   => "/tmp/${PYPGK}",
    require  => File['LR Python package']
  }

  file{'/usr/bin/pip3' :
    ensure  => link,
    target  => '/usr/local/bin/pip3',
    require => Package[$PYTHON]
  }

  package{'gunicorn' :
    ensure   => installed,
    provider => pip3,
    require  => File['/usr/bin/pip3']
  }

  package{'flask' :
    ensure   => installed,
    provider => pip3,
    require  => File['/usr/bin/pip3']
  }

}
