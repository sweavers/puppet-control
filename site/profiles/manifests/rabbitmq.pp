# Class profiles::rabbitmq
#
# This class will manage rabbitmq installations
#
# Parameters:
#
# Requires:
# - puppetlabs/rabbitmq
#
# Sample Usage:
#   class { 'profiles::rabbitmq':
#     ????? => ?????
#   }
#
class profiles::rabbitmq(

  $port     = 5672,
  $version  = '3.4.4',

){

  class { '::rabbitmq':
    version => $version,
    port    => $port,
  }

}
