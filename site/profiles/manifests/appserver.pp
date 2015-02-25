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

){

  class { 'supervisord':
    inet_server => true,
    install_pip => true
  }

}
