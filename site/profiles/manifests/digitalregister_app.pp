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
class profiles::digitalregister_app(

  $application  = undef,
  $bind         = '5000',
  $source       = 'undef',
  $vars         = {},
  $wsgi_entry   = undef,
  $manage       = true,
  $app_type     = 'wsgi',
  $applications = hiera_hash('applications',false),

  ){

  include ::stdlib
  include ::profiles::deployment
  include ::profiles::nginx
  include ::wsgi

  #  Install required packages for Ruby and Java

  $PKGLIST=['python','python-devel','python-pip']

  package { 'epel-release' :
    ensure => installed
  }

  package{ $PKGLIST :
    ensure  => installed,
    require => Package[epel-release]
  }

  # Dirty hack to address hard coded logging location in manage.py
  file { '/var/log/applications/' :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  # Dirty hack required to complie pip dependacies for frontend (should be
  # removed ASAP)
  package { 'gcc-c++' :
    ensure => present
  }

  # Load SELinuux policy for Nginx_proxy
  selinux::module { 'nginx_proxy':
    ensure => 'present',
    source => 'puppet:///modules/profiles/nginx_proxy.te'
  }

  # # Set up wsgi application
  # wsgi::application { $application :
  #   bind       => $bind ,
  #   source     => $source,
  #   vars       => $vars,
  #   wsgi_entry => $wsgi_entry,
  #   app_type   => $app_type,
  #   manage     => $manage,
  #   require    => File['/var/log/applications/']
  # }

  if $applications {
    create_resources('applications', $applications)
  }

  # Set up Nginx proxy
  nginx::resource::vhost { 'api_proxy':
    server_name    => [ $::hostname ],
    listen_port    => 80,
    #proxy_set_header => ['X-Forward-For $proxy_add_x_forwarded_for',
      #'Host $http_host'],
    proxy_redirect => 'off',
    proxy          => 'http://127.0.0.1:5000',
  }
}
