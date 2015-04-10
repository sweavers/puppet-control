# Class profiles::python3
#
# Will install python 3 on a node.
#
# Sample Usage:
#   class { 'profiles::python3': }
#
class profiles::digitalregisterfeeder {

  include ::stdlib
  include ::profiles::rabbitmq
  $feeder_dependecies = hiera_array('feeder_pip_packages')
  #  Install required packages for Ruby and Java
  case $::osfamily{
    'RedHat': {
      $PKGLIST=['java-1.7.0-openjdk','java-1.7.0-openjdk-devel','python',
      'python-devel','ruby','rubygems','autoconf','automake',
      'binutils','bison','flex','gcc','gcc-c++','gettext','libtool',
      'make','patch','pkgconfig','redhat-rpm-config','rpm-build',
      'rpm-sign']
      $PYTHON='lr-python3-3.4.3-1.x86_64'
      $PYPGK="${PYTHON}.rpm"
      $PKGMAN='rpm'
    }
    'Debian': {
      $PKGLIST=['openjdk-7-jdk','python','python-dev','ruby']
      $PYTHON='lr-python3_3.4.3_amd64'
      $PYPGK="${PYTHON}.deb"
      $PKGMAN='dpkg'
    }
    default: {
      fail("Unsupported OS type - ${::osfamily}")
    }
  }
  ensure_packages($PKGLIST)

  file{'LR Python package' :
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

# Install celery

  file{'/usr/bin/pip3' :
    ensure  => link,
    target  => '/usr/local/bin/pip3',
    require => Package[$PYTHON]
}

  package{ '$feeder_pip_packages' :
    ensure   => installed,
    provider => pip3,
    require  => File['/usr/bin/pip3']
}

}
