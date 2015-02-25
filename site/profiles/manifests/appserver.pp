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

  $supervisor_conf = '/etc/supervisor.d/*.conf'

){

  $supervisor_dir = any2array($supervisor_conf)

  class { 'supervisord':
    inet_server => true,
    install_pip => true,
    config_dirs => $supervisor_dir
  }

}
