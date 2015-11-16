class { 'ha':
  virtual_ip   => '192.168.99.10',
  interface    => 'eth0',
  lb_instances => {
    'default' => {
      'port'        => 80,
      'healthcheck' => '/',
      'backends'    => [ 'localhost:8080', 'localhost:8081']
    },
    'test'          => {
      'listen_port' => 9000,
      'healthcheck' => '/health',
      'backends'    => [ 'airbnb.com' ]
    }
  }
 }
