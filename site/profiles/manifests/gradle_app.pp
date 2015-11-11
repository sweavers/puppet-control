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
class profiles::gradle_app(

  $application   = undef,
  $bind          = '5000',
  $source        = 'undef',
  $vars          = {},
  $wsgi_entry    = undef,
  $manage        = true,
  $app_type      = 'wsgi',
  $gradle_applications  = hiera_hash('gradle_applications',false),
  $port          = 80,
  $ssl           = false,
  $ssl_protocols = 'TLSv1 SSLv3',
  $ssl_ciphers   = 'RC4:HIGH:!aNULL:MD5:@STRENGTH',
  $ssl_crt       = '',
  $ssl_key       = '',
  $nginx         = false

  ){

  include ::stdlib
  include ::profiles::deployment
  include ::profiles::nginx
  include ::gradle_deploy

  if $gradle_applications {
    create_resources('gradle_deploy::application', $gradle_applications)
  }

}
