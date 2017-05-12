# Class profiles::logging
#
# This class will manage application server installations
#
# Requires:
# - filebeat
#

class profiles::logging_packetbeat(
  $log_receiver             = [],
  $log_fields               = hiera('filebeat_log_fields',[]),
  $version                  = '5.3.1-1',
  $http_logging_ports       = undef,
  $http_logging_enabled     = undef,
  $postgres_logging_ports   = undef,
  $postgres_logging_enabled = undef,
  $amqp_logging_ports       = undef,
  $amqp_logging_enabled     = undef,
  $manage_repo              = true,
){

  class { 'packetbeat':
    package_vers             => $version,
    log_receiver             => $log_receiver,
    log_fields               => $log_fields,
    http_logging_ports       => $http_logging_ports,
    http_logging_enabled     => $http_logging_enabled,
    postgres_logging_ports   => $postgres_logging_ports,
    postgres_logging_enabled => $postgres_logging_enabled,
    amqp_logging_ports       => $amqp_logging_ports,
    amqp_logging_enabled     => $amqp_logging_enabled,
    manage_repo              => $manage_repo,
  }

}
