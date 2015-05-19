# Class profiles::default_fw::pre
# This class configures default firewall rules to be applied firts
#
# Parameters: #Paramiters accepted by the class
# ['ssh_port'] - integer
#
# Requires: #Modules required by the class
# - puppetlabs/firewall
#
# Sample Usage:
# class { 'profiles::firewall': }
#
# Hiera:
# <EXAMPLE OF ANY REQUIRED HIERA STRUCTURE>
#

class profiles::default_fw::pre (

  $ssh_port = '22'

){

  Firewall {
    require => undef,
  }

  # Default firewall rules
  firewall { '000 accept all icmp':
    proto  => 'icmp',
    action => 'accept',
  }->
  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }->
  firewall { '002 reject local traffic not on loopback interface':
    iniface     => '!lo',
    proto       => 'all',
    destination => '127.0.0.1/8',
    action      => 'reject',
  }->
  firewall { '003 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }->
  firewall { '004 ensure ssh port is open':
    port   => $ssh_port,
    proto  => 'tcp',
    state  => 'NEW',
    action => 'accept',
  }
}
