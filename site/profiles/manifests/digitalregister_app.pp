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

  $PKGLIST=['python','python-devel','python-pip']

  package { 'epel-release' :
    ensure => installed
  }

  package{ $PKGLIST :
    ensure  => installed,
    require => Package[epel-release]
  }

  file{'LR Python package':
    ensure => 'file',
    path   => '/tmp/lr-python3-3.4.3-1.x86_64.rpm',
    source => 'puppet:///modules/profiles/lr-python3-3.4.3-1.x86_64.rpm'
  }

  # Install custom Python 3.4.3 build
  package{ 'lr-python3-3.4.3-1.x86_64.rpm' :
    ensure   => installed,
    provider => rpm,
    source   => '/tmp/lr-python3-3.4.3-1.x86_64.rpm',
    require  => File['LR Python package']
  }

  file{'/usr/bin/pip3' :
    ensure  => link,
    target  => '/usr/local/bin/pip3',
    require => Package['lr-python3-3.4.3-1.x86_64.rpm']
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

  nginx::resource::vhost { 'api_proxy':
    server_name    => [ $::hostname ],
    listen_port    => 80,
    #proxy_set_header => ['X-Forward-For $proxy_add_x_forwrded_for',
      #'Host $http_host'],
    proxy_redirect => 'off',
    proxy          => 'http://127.0.0.1:8000',

  }
}
