class { 'ha' :
  virtual_ip  => '192.168.99.10',
  backends    => [ '192.168.99.11:9200', '192.168.99.12:9200' ],
  interface   => 'eth1',
  healthcheck => '/'
}
class { 'es' :
  name          => 'highavailability',
  interface     => 'eth1',
  minimum_nodes => 2
}
