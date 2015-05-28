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
# - stephenrjohnson/puppet
# - zack/r10k
# - puppetlabs/firewall
#
# Sample Usage:
#  class { 'profiles::puppet::master':
#    control_repo => 'https://github.com/LandRegistry-Ops/puppet-control.git',
#  }
#
class profiles::puppet::master (

  $control_repo   = 'https://github.com/LandRegistry-Ops/puppet-control.git',
  $hiera_path     = '/etc/puppet/hiera.yaml',

){

  # stephenrjohnson/puppet
  class { '::puppet::master':
    dns_alt_names   => ['puppet'],
    environments    => 'directory',
    environmentpath => '$confdir/environments',
    hiera_config    => $hiera_path,
    autosign        => true, # replace with policy-based autosign app
    pluginsync      => true,
    storeconfigs    => true,
    reports         => 'store,puppetdb',
    require         => Class['::puppetdb']
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
    listen_address => '0.0.0.0'
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
