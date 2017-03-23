#
class profiles::application (

  $applications  = hiera_hash('applications',false),

  ){

  include ::wsgi
  include ::stdlib

  # Define process check for bespoke applications
  define service_check(){
    @@nagios_service { "${::hostname}-lr-${name}" :
      ensure                => present,
      check_command         => "check_nrpe!check_service_procs\!2:15\!1:20\!${name}",
      mode                  => '0644',
      owner                 => root,
      use                   => 'generic-service',
      host_name             => $::hostname,
      check_period          => '24x7',
      contact_groups        => 'admins',
      notification_interval => 0,
      notifications_enabled => 0,
      notification_period   => '24x7',
      service_description   => "LR service ${name}"
    }
  }

  # Define http_check for bespoke applications - not currently in use
  # define http_check($bind){
  #   @@nagios_service { "${::hostname}-lr-${name}-http_check" :
  #     ensure                => present,
  #     check_command         => "check_nrpe!check_service_http\!'127.0.0.1'\!'${bind}'\!'200 OK'",
  #     mode                  => '0644',
  #     owner                 => root,
  #     use                   => 'generic-service',
  #     host_name             => $::hostname,
  #     check_period          => '24x7',
  #     contact_groups        => 'admins',
  #     notification_interval => 0,
  #     notification_period   => '24x7',
  #     service_description   => "LR http ${name}"
  #   }
  # }

  # Define tcp_check for bespoke applications
  define tcp_check($bind){
    unless $bind==0 or $bind=='0' or $bind=='' or $bind== undef {
      @@nagios_service { "${::hostname}-lr-${name}-tcp_check" :
        ensure                => present,
        check_command         => "check_nrpe!check_service_tcp\!'127.0.0.1'\!'${bind}'",
        mode                  => '0644',
        owner                 => root,
        use                   => 'generic-service',
        host_name             => $::hostname,
        check_period          => '24x7'
        contact_groups        => 'admins',
        notification_interval => 0,
        notifications_enabled => 0,
        notification_period   => '24x7',
        service_description   => "LR tcp ${name}"
      }
    }
  }



  if $applications {
    # Dirty hack to address hard coded logging location in manage.py
    file { '/var/log/applications/' :
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755'
    }

    # Create application resources for each application specified for server
    create_resources('wsgi::application', $applications,
      {require => File['/var/log/applications/']})

    # Create array of all bespoke applcation names for this server
    $services=keys($applications)

    # Create hash of all bespoke applications and their binds
    $bindhash = application_bind($applications)

    # Create process check for each application specified for server
    service_check{$services:}

    # Create http check for each application specified for server
    # create_resources(http_check, $bindhash)

    # Create tcp check for each application specified for server
    create_resources(tcp_check, $bindhash)

  }
}
