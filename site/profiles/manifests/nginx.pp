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

  if $virtual == 'xenhvm' {

  	case $::hostname {
  		'digital-register-frontend-01': {

  			nginx::resource::vhost { 'digital.integration.beta.landregistryconcept.co.uk':
              
              listen_port     => 80,
              proxy           => 'http://127.0.0.1:8000',
              www_root        => '/var/jail',
              proxy_set_header=> [
              'X-Real-IP        $remote_addr',
              'X-Forwarded-For  $proxy_add_x_forwarded_for', # This directive is to address US100 "session stealing"
              'Host             $http_host',
              ],

  		    }

  	
        }
        'digital-register-frontend-02': {

        	nginx::resource::vhost { 'digital.preview.beta.landregistryconcept.co.uk':
             
              listen_port      => 80,
              proxy            => 'http://127.0.0.1:8000',
              www_root         => '/var/jail',
              proxy_set_header => [
              'X-Real-IP         $remote_addr',
              'X-Forwarded-For   $proxy_add_x_forwarded_for',
              'Host              $http_host',
              ]

            }

        }
  	}
  }
  else {
  		# enter puppet code
  }
  

}

