# Class: profiles::puppet::master
#
# This class installs and configures a Puppet Master
#
# Parameters:
#  ['control_repo'] - URI of control repository
#  ['hiera_path']   - Path where hiera configuration file is placed
#
# Requires:
# - puppetlabs/puppetdb
# - zack/r10k
# - puppetlabs/firewall
#
# Sample Usage:
#  class { 'profiles::puppet::master':
#    control_repo => 'https://github.com/LandRegistry-Ops/puppet-control.git',
#  }
#
class profiles::puppet::master (

  $control_repo = 'https://github.com/LandRegistry-Ops/puppet-control.git',
  $hiera_path   = '/etc/puppet/hiera.yaml',

  ){

    include ::nginx

    # Install puppet-server package
    package { 'puppet-server' :
      ensure  => installed
    }

    # file_line { 'Add alt dns names' :
    #   path  => '/etc/puppet/puppet.conf',
    #   line  => "dns_alt_names = puppet, ${::fqdn}",
    #   after => 'ssldir = $vardir/ssl'
    # }

    # #Generate puppet cert
    # # Clean existing certs
    # $crt_clean_cmd  = "puppet cert clean ${::fqdn}"
    # # Gen the cert
    # $crt_gen_cmd   = "puppet certificate --ca-location=local --dns_alt_names= puppet, ${::fqdn} generate ${::fqdn}"
    # # Sign the cert
    # $crt_sign_cmd  = "puppet cert sign --allow-dns-alt-names ${::fqdn}"
    # # find is required to move the cert into the certs directory which is
    # # where it needs to be for puppetdb to find it
    # $cert_find_cmd = "puppet certificate --ca-location=local find ${::fqdn}"

    # # Execute the commands
    # exec { 'Create certs if not present':
    #   command   => "${crt_clean_cmd} ; ${crt_gen_cmd} && ${crt_sign_cmd} && ${cert_find_cmd}",
    #   unless    => "/bin/ls /var/lib/puppet/ssl/certs/${::fqdn}.pem",
    #   path      => '/usr/bin:/usr/local/bin',
    #   logoutput => on_failure,
    #   require   => Package ['puppet-server']
    # }

    # # Add environment path to puppet.conf
    # file_line { 'Add environmentpath':
    #   path    => '/etc/puppet/puppet.conf',
    #   line    => 'environmentpath = /etc/puppet/environments',
    #   after   => "dns_alt_names = puppet, ${::fqdn}",
    #   require => File_line ['Add alt dns names']
    # }

    # Configure puppet
    file { '/etc/puppet/puppet.conf':
      content => template('profiles/puppet.conf.erb'),
      owner   => puppet,
      group   => puppet,
      mode    => '0644'
    }

    # package { 'puppetdb-terminus':
    #   ensure => installed
    # }

    file { '/etc/puppet/environments' :
      ensure  => directory,
      owner   => puppet,
      group   => puppet,
      mode    => '0644',
      recurse => true
    }

    # Install build dependancies
    $build_dependencies = ['make', 'gcc'] #'rubygems','ruby-devel'
    package { $build_dependencies :
      ensure => installed
    }

    # Install required gems
    $gems = ['rack', 'unicorn']
    package { $gems :
      ensure   => installed,
      provider => gem,
      require  => Package [ $build_dependencies, 'rubygems','ruby-devel']
    }

    # Copy standard puppet rack config
    file { '/etc/puppet/config.ru' :
      ensure  => present,
      owner   => 'puppet',
      group   => 'puppet',
      source  => '/usr/share/puppet/ext/rack/config.ru',
      require => Package ['puppet-server']
    }

    # Create unicorn config
    file {'/etc/puppet/unicorn.conf' :
      ensure => present,
      owner  => 'puppet',
      group  => 'puppet',
      source => 'puppet:///modules/profiles/puppet_master_unicorn.conf'
    }

    # Ensure unicorn logging target is present
    file { '/var/log/unicorn_stderr.log' :
      ensure => present,
      owner  => 'puppet',
      group  => 'puppet'
    }

    # Configure Nginx
    file { '/etc/nginx/conf.d/puppetmaster.conf':
      content => template('profiles/puppetmaster.conf.erb'),
      owner   => root,
      group   => root,
      mode    => '0600',
      notify  => Service['nginx']
    }

    # Configure Nginx
    # nginx::resource::upstream { 'puppetmaster_unicorn':
    #   members => ['unix:/var/run/puppet/puppetmaster_unicorn.sock fail_timeout=0'],
    # }
    #
    # nginx::resource::vhost { 'puppetmaster_proxy':
    #   server_name         => [ $::fqdn ],
    #   listen_port         => 8140,
    #   ssl                 => true,
    #   ssl_session_timeout => '5m',
    #   ssl_cert            => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
    #   ssl_key             => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    #   ssl_ciphers         => 'SSLv2:-LOW:-EXPORT:RC4+RSA',
    #   proxy_set_header    => ['Host $http_host','X-Real-IP $remote_addr','X-Forwarded-For $proxy_add_x_forwarded_for', 'X-Client-Verify $ssl_client_verify', 'X-Client-DN $ssl_client_s_dn', 'X-SSL-Issuer $ssl_client_i_dn',  ],
    #   proxy_redirect      => 'off',
    #   proxy               => 'http://puppetmaster_unicorn',
    #   vhost_cfg_append    => {
    #     'ssl_verify_client'      => 'optional',
    #     'ssl_client_certificate' => '/var/lib/puppet/ssl/ca/ca_crt.pem'
    #   }
    # }

    file { '/etc/systemd/system/puppetmaster-unicorn.service' :
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/profiles/puppetmaster-unicorn.service',
      notify  => Exec ['systemctl daemon-reload'],
      require => Package ['unicorn']
    }

    exec {'systemctl daemon-reload' :
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true
    }

    service { 'puppetmaster-unicorn' :
      ensure  => running,
      require => File ['/etc/systemd/system/puppetmaster-unicorn.service']
    }

    # zack/r10k
    class { '::r10k':
      configfile                => '/etc/puppet/r10k.yaml',
      configfile_symlink        => '/etc/r10k.yaml',
      manage_configfile_symlink => true,
      manage_modulepath         => false,
      sources                   => {
        'control' => {
          'remote'  => $control_repo,
          'basedir' => "${::settings::confdir}/environments",
          'prefix'  => false
        }
      }
    }

    # puppetlabs/puppetdb
    class { '::puppetdb':
      listen_address     => '0.0.0.0',
      ssl_set_cert_paths => true,
      ssl_cert_path      => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
      ssl_key_path       => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
      ssl_ca_cert_path   => '/var/lib/puppet/ssl/certs/ca.pem',
      require            => Service ['puppetmaster-unicorn']
    }

    class { 'puppetdb::master::config':
      puppetdb_server => $::fqdn,
      puppetdb_port   => 8081
    }

    user { 'puppetdb' :
      groups => puppet
    }

    # Manage hiera file
    file { $hiera_path :
      ensure => present,
      path   => $hiera_path,
      owner  => 'puppet',
      group  => 'puppet',
      mode   => '0644',
      source => 'puppet:///modules/profiles/hiera.yaml'
    }

    file { '/usr/local/bin/secrets':
      ensure => present,
      path   => '/usr/local/bin/secrets',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/profiles/secrets.sh'
    }

    # Clean up redundant folders
    file { '/etc/puppet/templates':
      ensure => absent,
      force  => true
    }

    file { '/etc/puppet/modules':
      ensure => absent,
      force  => true
    }
}
