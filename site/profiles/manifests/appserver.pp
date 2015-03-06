# Class profiles::appserver
#
# This class will manage application server installations
#
# Requires:
# - ajcrowe/supervisord
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::appserver': }
#
class profiles::appserver(

  $supervisor_conf = '/etc/supervisor.d/*.conf'

){

  include ::stdlib
  include ::profiles::deployment

  $supervisor_dir = any2array($supervisor_conf)

  class { 'supervisord':
    inet_server => true,
    install_pip => true,
    config_dirs => $supervisor_dir
  }

  file { '/etc/supervisord.d/':
    ensure  => directory,
    owner   => root,
    group   => deployment,
    mode    => '0775',
    require => Class[Profiles::Deployment]
  }

  #  Install required packages for Ruby and Java
  case $::osfamily{
    'RedHat': {
      $PKGLIST=['java-1.7.0-openjdk','java-1.7.0-openjdk-devel','python',
                'python-devel','ruby','rubygems','autoconf','automake',
                'binutils','bison','flex','gcc','gcc-c++','gettext','libtool',
                'make','patch','pkgconfig','redhat-rpm-config','rpm-build',
                'rpm-sign']
      $PYTHON='lr-python3-3.4.3-1.x86_64.rpm'
      $PKGMAN='rpm'
    }
    'Debian': {
      $PKGLIST=['openjdk-7-jdk','python','python-dev','ruby']
      $PYTHON='lr-python3_3.4.3_amd64.deb'
      $PKGMAN='dpkg'
    }
    default: {
      fail("Unsupported OS type - ${::osfamily}")
    }
  }
  ensure_packages($PKGLIST)

  file{'LR Python package':
    ensure => 'file',
    path   => "/tmp/${PYTHON}",
    source => "puppet:///modules/profiles/${PYTHON}"
  }

  # Install custom Python 3.4.3 build
  package{'LR Python 3':
    ensure   => installed,
    provider => $PKGMAN,
    source   => "/tmp/${PYTHON}",
    require  => File['LR Python package']
  }

  package{['bundler','rake']:
    ensure   => installed,
    provider => gem
  }

  package{['virtualenv','virtualenvwrapper']:
    ensure   => installed,
    provider => pip
  }

}
