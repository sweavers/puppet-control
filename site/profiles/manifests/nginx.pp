# Class profiles::nginx
# This class will configure Nginx
#
# Parameters:
#
# Requires:
# - jfryman/nginx
#
# Sample Usage:
#   class { 'profiles::nginx': }
#
class profiles::nginx (

) {

  # Load SELinuux policy for NginX
  selinux::module { 'nginx':
    ensure => 'present',
    source => 'puppet:///modules/profiles/nginx.te'
  }

  include ::nginx

}
