# Class profiles::firewall
# This class will configures and manages IP tables.
#
# Parameters: #Paramiters accepted by the class
# - none
#
# Requires: #Modules required by the class
# - puppetlabs/firewall
#
# Sample Usage:
# class { 'profiles::firewall': }
#
# Hiera:
# - none NB look ups are required my_fw classes
#
# class profiles::firewall {
#
#   # Puppetlabs/firewall
#   # ensure furewall is installed and runing
#   class { '::firewall' :
#   }->
#   # remove firewall rules not managed by puppet
#   resources { 'firewall':
#     purge => true
#   }->
#   # ensure default pre firewall rules are applied (e.g. ssh)
#   class { 'profiles::my_fw::pre' :
#   }->
#   # ensure default post firewall rules are applied (e.g. drop all)
#   class { 'profiles::my_fw::post': }
# }
