# Class profiles::appserver
#
# This class will manage application server installations
#
# Parameters:
#  ['port']     - Port which MongoDB should listen on. Defaults = 27018
#
# Requires:
# - ajcrowe/supervisord
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::appserver': }
#
class profiles::appserver(

  $supervisor_conf = undef

){

  class { 'supervisord':
    inet_server => true,
    install_pip => true,
    conf_dir    => $supervisor_conf
  }

}
