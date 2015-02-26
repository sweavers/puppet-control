# Create lr-admin group on all hosts

group { 'lr-admin':
  ensure => present,
  gid    => 2000,
}

create_resources( 'account', hiera_hash('accounts', {require => Group['lr-admin']}) )
