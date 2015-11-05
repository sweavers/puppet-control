class { ha:
  backends   => ['google.com'],
  interface  => 'eth0',
  virtual_ip => '192.168.99.10'
}
