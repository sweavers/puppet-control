# Class profiles::logging
#
# This class will manage application server installations
#
# Requires:
# - filebeat
#

class profiles::logging(
  $log_receiver = [],
  $log_fields   = hiera('filebeat_log_fields',[]),
){
  class { 'filebeat':
    log_receiver => $log_receiver,
    log_fields   => $log_fields,
  }

}
