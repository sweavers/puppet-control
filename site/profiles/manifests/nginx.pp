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

  include ::nginx

}

