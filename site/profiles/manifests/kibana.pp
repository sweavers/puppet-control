# Class profiles::kibana
# This class will configure kibana
#
# Parameters:
#
# Requires:
# - evenup/kibana
#
# Sample Usage:
#   class { 'profiles::kibana': }
#
class profiles::kibana (

) {

  include ::kibana

}
