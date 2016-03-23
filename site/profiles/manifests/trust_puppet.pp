# Trust Puppet CA
class profiles::trust_puppet () {

  security::trust_ca { '/var/lib/puppet/ssl/certs/ca.pem' :
    ensure => present
  }

}
