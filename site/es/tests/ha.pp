class { 'ha' :
  virtual_ip   => '192.168.99.10',
  interface    => 'eth1',
  lb_instances => {
    'elasticsearch' => {
      'backends'    => [ '192.168.99.11:9200', '192.168.99.12:9200', '192.168.99.13:9200' ],
      'healthcheck' => '/'
    }
  }
}
class { 'es' :
  cluster_name  => 'showandtell',
  interface     => 'eth1',
  minimum_nodes => 2
}
