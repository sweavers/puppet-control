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
class profiles::nginx_selinux (

) {

  # Load SELinuux policy for NginX
  selinux::module { 'nginx_proxy':
    ensure => 'present',
    source => 'puppet:///modules/profiles/nginx_proxy.te'
  }
  # Load SELinuux policy for NginX
  selinux::module { 'nginx_unreservedport_name_connect':
    ensure => 'present',
    source => 'puppet:///modules/profiles/nginx_unreservedport_name_connect.te'
  }

}
