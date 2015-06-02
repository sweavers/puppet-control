# Set role based on hostname
#if empty($machine_role) {
#  $machine_role = regsubst($::hostname, '^(.*)-\d+$', '\1')
#}
notify{"Machine Role: ${::role}": loglevel => alert,}
notify{"Machine Zone: ${::network_location}": loglevel => alert,}
notify{"Machine level: ${::machine_region}": loglevel => alert,}

# Default nodes
node default {

  if $virtual == 'xenhvm' {


    user {
        'webapp':
            ensure     => present,
            home       => '/var/webapp',
            shell      => '/bin/bash',
            uid        => '1003',
            managehome => true,
    }

    file {
        '/etc/sudoers.d/webapp':
            ensure  => file,
            source  => 'puppet:///modules/profiles/webapp',
            owner   => 'root',
            group   => 'root',
            mode    => '0644';
    }
      # enter puppet code
  }

  else {
    # enter puppet code


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
}
