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

  case $::osfamily{
    'RedHat': {
      $PKGLIST=['java-1.7.0-openjdk','ruby','scl-utils','rubygems']
    }
    'Debian': {$PKGLIST=['openjdk-7-jdk','ruby']
    }
    default: {$PKGLIST=[]
    }
  }

  ensure_packages($PKGLIST)

  package{'bundler':
    ensure   => installed,
    provider => gem
  }

  package{'rake':
    ensure   => installed,
    provider => gem
  }

}
