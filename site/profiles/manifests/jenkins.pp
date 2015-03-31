# Class profiles::jenkins
# This class will manage Jenkins installations.
# Currently supports stand-alone only.
#
# Parameters:
#  ['jenkins_plugins'] - Accepts a hash of Jenkins Plugins
#
# Requires:
# - rtyler/jenkins
# - puppetlabs/firewall
#
# Sample Usage:
#   class { 'profiles::jenkins': }
#
# Hiera:
#   profiles::jenkins::plugins:
#     git:
#       version: latest
#
class profiles::jenkins (

  $plugins,
  $deploy_from_jenkins_rsa,

) {

  # rtyler/jenkins
  class { '::jenkins':
    plugin_hash        => $plugins,
    port               => 8080,
    configure_firewall => false,
  }

  file { '/var/lib/jenkins/.ssh':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0700'
  }

  file { '/var/lib/jenkins/.ssh/id_rsa':
    ensure  => 'present',
    content => $deploy_from_jenkins_rsa,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/var/lib/jenkins/.ssh']
  }

  # ensure artifact script is installed
  file { '/usr/bin/artifact':
    ensure => present,
    path   => '/usr/local/bin/artifact',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profiles/artifact.sh'
  }

  # ensure artifact script is installed
  file { '/usr/bin/deploy':
    ensure => present,
    path   => '/usr/local/bin/deploy',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profiles/deploy.sh'
  }

  # ensure app-deploy script is installed
  file { '/usr/bin/app-deploy':
    ensure => present,
    path   => '/usr/local/bin/app-deploy',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profiles/app-deploy.sh'
  }

  # ensure app-deploy script is installed
  file { '/usr/bin/app-deploy-api':
    ensure => present,
    path   => '/usr/local/bin/app-deploy-api',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profiles/app-deploy-api.sh'
  }

  # ensure app-deploy script is installed
  file { '/usr/bin/app-deploy-login-api':
    ensure => present,
    path   => '/usr/local/bin/app-deploy-login-api',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profiles/app-deploy-login-api.sh'
  }

  # ensure r10k is installed
  package { 'r10k':
    ensure   => 'installed',
    provider => 'gem',
  }
}
