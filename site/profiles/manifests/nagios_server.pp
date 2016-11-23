class profiles::nagios_server(){

  include nagios

  # Auto populate nagios configuration from puppetdb
  Nagios_host <<||>> {
   require => Package['nagios'],
   notify  => Service['nagios']
  }
}
