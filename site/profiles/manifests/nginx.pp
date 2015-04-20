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

  if $hostname == 'digital-register-frontend-\d\d' {

  	nginx::resource::vhost { 'digital.integration.beta.landregistryconcept.co.uk' :

  	  listen_port  => 80,
  	  proxy        => 'http://127.0.0.1:8000',
  	  www_root     => '/var/jail',
  	  proxy_set_header => [
  	    'X-Real-IP        $remote_addr',
  	    'X-Forwarded-For  $proxy_add_x_forwarded_for',  # This directive addresses session stealing US100
  	  ],


  	}
  else {
  		# enter puppet code
  	}
  }

}

