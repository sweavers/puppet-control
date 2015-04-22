# Set role based on hostname
if empty($machine_role) {
  $machine_role = regsubst($::hostname, '^(.*)-\d+$', '\1')
}

# Default nodes
node default {

  if $virtual == 'xenhvm' {

    case $hostname {
        "digital-register-frontend-01": {
            nginx::resource::vhost{ 'digital.integration.beta.landregistryconcept.co.uk':
              proxy  => 'http://127.0.0.1:8000',
            }
        }
        "digital-register-frontend-02":  {
            nginx::resource::vhost{ 'digital.preview.beta.landregistryconcept.co.uk':
              proxy  => 'http://127.0.0.1:8000',
            }
        }
        default: {

        }
    }

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

  elsif $virtual == 'virtualbox' {
      
      

  } else {
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
