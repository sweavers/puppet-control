# Class profiles::nat
# This class will set up a nat instance primarily for use on AWS
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
class profiles::nat (

  $private_sub_net = undef

  ){

  # Enable ipv4 forwarding
  file { '/etc/sysctl.d/ip_forward.conf':
    ensure  => present,
    content => 'net.ipv4.ip_forward = 1',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec ['reload system config']
  }
  exec { 'reload system config' :
    command     => '/usr/sbin/sysctl -p',
    refreshonly => true
  }

  # IP tables rules will be added via hiera

}
