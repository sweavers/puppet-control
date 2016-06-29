# Class profiles::custom_facts
#
# This class will create a custom facts file
#
# Requires:
#
# Sample Usage:
#   class { 'profiles::custom_facts': }
#
class profiles::custom_facts() {

  # Create facts directory
  file { '/etc/facter/facts.d/' :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700'
  }

  # Add executable fact
  file { '/etc/facter/facts.d/custom_facts.sh':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    source => 'puppet:///modules/profiles/custom_facts.sh'
  }

}
