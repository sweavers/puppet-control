# Class profiles::ntp
# This class will configure ntp for beta.
#
# Parameters: #Paramiters accepted by the class
#  ['ntp_server_array']   - array
#  ['ntp_restrict_array'] - array
#
# Requires: #Modules required by the class
# - puppetlabs/ntp
#
# Sample Usage:
#   class { 'profiles::ntp': }
#
# Hiera:
#   profiles::ntp::ntp_server_array:
#     - 2.uk.pool.ntp.org
#     - 3.uk.pool.ntp.org
#   profiles::ntp::ntp_restrict_array:
#     - 127.0.1.0
#     - 127.0.1.1
#
class profiles::ntp (

  $ntp_server_array   = ['0.uk.pool.ntp.org', '1.uk.pool.ntp.org',],
  $ntp_restrict_array = ['127.0.0.1']

) {

  # puppetlabs/ntp
    class { '::ntp':
      package_ensure => 'present',
      servers        => $ntp_server_array,
      restrict       => $ntp_restrict_array
    }
}

