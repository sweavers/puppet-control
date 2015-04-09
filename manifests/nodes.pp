# Set role based on hostname
if empty($machine_role) {
  $machine_role = regsubst($::hostname, '^(.*)-\d+$', '\1')
}

# Default nodes
node default {

  if $virtual == 'xenu' {

    user {
        'webapp':
            ensure  => present,
            home    => '/home/webapp',
            shell   => '/bin/bash',
            uid     => '1003',
            gid     => '1003';
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
}

}
