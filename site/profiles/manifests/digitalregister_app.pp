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

  $application   = undef,
  $bind          = '5000',
  $source        = 'undef',
  $vars          = {},
  $wsgi_entry    = undef,
  $manage        = true,
  $app_type      = 'wsgi',
  $applications  = hiera_hash('applications',false),
  $port          = 80,
  $frontend_url  = [ $::hostname ],
  $frontend_ssl  = false,
  $api_ssl       = false,
  $ssl_protocols = 'TLSv1 SSLv3',
  $ssl_ciphers   = 'RC4:HIGH:!aNULL:MD5:@STRENGTH',
  $ssl_crt       = '',
  $ssl_key       = ''

  ){

  include ::stdlib
  include ::profiles::deployment
  include ::profiles::nginx
  include ::wsgi

  #  Install required packages for Python

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

  if $applications {
    create_resources('wsgi::application', $applications)
  }

  if $::puppet_role == 'digital-register-frontend' {
    #Dirty hack required for static error page (should be removed asap)
    #set up static error page
    vcsrepo { '/usr/share/nginx/html/digital-register-static-error-page':
      ensure   => present,
      provider => git,
      source   => 'https://github.com/LandRegistry/digital-register-static-error-page.git',
      before   => File['/etc/ssl/keys/']
    }
  }

  # Set up Nginx proxy
  file { '/etc/ssl/keys/' :
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0700'
  }

  file { '/etc/ssl/certs/ssl.crt' :
    ensure  => present,
    content => $ssl_crt,
    owner   => root,
    group   => root,
    mode    => '0644'
  }

  file { '/etc/ssl/keys/ssl.key' :
    ensure  => present,
    content => $ssl_key,
    owner   => root,
    group   => root,
    mode    => '0400',
    require => File['/etc/ssl/keys/']
  }

  nginx::resource::vhost { 'https_redirect':
    server_name      => [ $frontend_url ],
    listen_port      => $port,
    www_root         => '/usr/share/nginx/html',
    vhost_cfg_append => {
            'return' => '301 https://$server_name$request_uri'}
  }

  if $::puppet_role == 'digital-register-frontend' {

    $FRNTEND_PKGS = ['cairo','pango','gdk-pixbuf2','libffi-devel',
                    'libxslt-devel','libxml2-devel']

    package{ $FRNTEND_PKGS :
      ensure  => installed,
      require => Package[epel-release]
    }

    nginx::resource::vhost { 'frontend_proxy':
      server_name       => [ $frontend_url ],
      listen_port       => 443,

      proxy_set_header  => ['X-Forward-For $proxy_add_x_forwarded_for',
        'X-Real-IP $remote_addr', 'Client-IP $remote_addr', 'Host $http_host'],

      proxy_redirect    => 'off',
      proxy             => 'http://127.0.0.1:5000',
      ssl               => $frontend_ssl,
      ssl_cert          => '/etc/ssl/certs/ssl.crt',
      ssl_key           => '/etc/ssl/keys/ssl.key',
      ssl_protocols     => $ssl_protocols,
      ssl_ciphers       => $ssl_ciphers,
      require           => File['/etc/ssl/certs/ssl.crt',
                                '/etc/ssl/keys/ssl.key'],

      vhost_cfg_prepend => {
          'error_page' => '502 /index.html',
          'root'       => '/usr/share/nginx/html/digital-register-static-error-page/service-unavailable'
          },

      raw_append        => ['','location /index.html {',
        '  root /usr/share/nginx/html/digital-register-static-error-page/service-unavailable;'
        ,'  internal;','}']
    }
  } else {
    nginx::resource::vhost { 'api_proxy':
      server_name    => [ $::hostname ],
      listen_port    => 80,
      # proxy_set_header => ['X-Forward-For $proxy_add_x_forwarded_for',
      # 'X-Real-IP $remote_addr', 'Client-IP $remote_addr', 'Host $http_host'],
      proxy_redirect => 'off',
      proxy          => 'http://127.0.0.1:5000',
      ssl            => $api_ssl,
      ssl_cert       => '/etc/ssl/certs/ssl.crt',
      ssl_key        => '/etc/ssl/keys/ssl.key',
      ssl_protocols  => $ssl_protocols,
      ssl_ciphers    => $ssl_ciphers,
      require        => File['/etc/ssl/certs/ssl.crt',
      '/etc/ssl/keys/ssl.key'],
    }
  }
}
