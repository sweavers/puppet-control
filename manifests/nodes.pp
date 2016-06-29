# Set role based on hostname
#if empty($machine_role) {
#  $machine_role = regsubst($::hostname, '^(.*)-\d+$', '\1')
#}
notify{"Puppet Role: ${::puppet_role}": loglevel => debug,}
notify{"Network Location: ${::network_location}": loglevel => debug,}
notify{"Application Environment: ${::application_environment}": loglevel => debug,}

# Default nodes
node default {

  user {
      'webapp':
          ensure     => absent,
          home       => '/var/webapp',
          shell      => '/bin/bash',
          uid        => '1003',
          managehome => true,
  }

  file {
      '/etc/sudoers.d/webapp':
          ensure => absent,
          source => 'puppet:///modules/profiles/webapp',
          owner  => 'root',
          group  => 'root',
          mode   => '0644';
  }

  # Create 'lr-admin' group on all hosts
  group { 'lr-admin' :
    ensure => present,
    gid    => 2000
  }

  # Configure passwordless sudo for 'lr-admin' group
  sudo::conf { 'lr-admin' :
    priority => 20,
    content  => '%lr-admin  ALL=(ALL)  NOPASSWD: ALL',
  }

  # Create accounts from Hiera data
  create_resources( 'account', hiera_hash('accounts', {require => Group['lr-admin']}) )

  # Disable root login with password
  user { root :
    ensure   => present,
    password => '!'
  }

}
