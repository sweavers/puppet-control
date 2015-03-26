# Class profiles::logbrokerextranet
#
# Sample Usage:
#   class { 'profiles::logbrokerextranet': }
#
class profiles::redis {

include ::redis

package { 'redis' :
  ensure  => installed,
  }
}
