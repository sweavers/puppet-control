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
class profiles::vagrant{

  include ::stdlib
  include ::profiles::nginx
  include ::profiles::postgresql

  Exec {
    path      =>  ['/bin/', '/usr/bin'],
  }

  $phantomjs_resources  =  hiera('phantomjs_resources')
  $env_vars             =  hiera_array('env_vars')
  $ssh_config           =  hiera_array('ssh_config')

  #  Install required packages for Ruby and Java
  case $::osfamily{
    'RedHat': {
      $PKGLIST=['java-1.7.0-openjdk','java-1.7.0-openjdk-devel','python',
        'python-devel','ruby','rubygems','autoconf','automake',
        'binutils','bison','flex','gcc','gcc-c++','gettext','libtool',
        'make','patch','pkgconfig','redhat-rpm-config','rpm-build',
        'rpm-sign','libxml2','libxslt','libxml2-devel','wget',
        'psmisc','rabbitmq-server']
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

  package {
      'python-pip':
          ensure      => installed,
          provider    => yum,
          require     => Package[$PKGLIST];
  }

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
    ensure => link,
    target => '/usr/local/bin/pip3',
  }


  file{'/etc/profile.d/env_vars' :
    ensure  => file,
    content => $env_vars,
  } ~>

  file{'/tmp/phantomjs.sh' :
    ensure => present,
    source => $phantomjs_resources,

  }

  exec{'phantomjs' :
    command => 'bash phantomjs.sh',
    cwd     => '/tmp',
    timeout => 0,
    require => File['/tmp/phantomjs.sh'],
  }

  package{'foreman' :
    ensure   => installed,
    provider => gem,
    require  => Package[$PKGLIST],
  }

  package{['setuptools','virtualenv','virtualenvwrapper'] :
    ensure   => installed,
    provider => pip3,
    require  => File['/usr/bin/pip3'],
  }

  file{'/home/vagrant/land-registry-python-venvs' :
    ensure => directory,

  }

  file{'/var/log/applications' :
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file{'/home/vagrant/.ssh/config' :
    ensure  => file,
    content => $ssh_config,
  }

  file{'/home/vagrant/.bash_profile' :
    ensure => file,
    source => 'puppet:///modules/profiles/.bash_profile',
  }

}
