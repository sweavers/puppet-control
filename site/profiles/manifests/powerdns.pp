# Class profiles::powerdns
#
# This class will manage PowerDNS installations which use PostgreSQL
#
# Requires:
# - puppetlabs/stdlib
# - landregistry/powerdns
#
class profiles::powerdns (

  $config = hiera_hash('powerdns',undef)

){

  include ::stdlib

  class { powerdns::server::authoritive :
    ensure     => present,
    port       => 53,
    password   => ${config['password'],
    api_port   => ${config['api_port'],
    soa_name   => ${config['soa_name'],
    soa_mail   => ${config['soa_mail'],
    postgresql => ${config['postgresql']
  }

}
