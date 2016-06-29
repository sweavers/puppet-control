#
class profiles::application_remote (
  $ham_host       = undef,
  $ham_host_token = undef,
){
  include ::wsgi
  include ::stdlib

  if $ham_host and $ham_host_token {

    $applications = remote_json("${ham_host}/api/host/${::fqdn}", $ham_host_token)

    if $applications {
      # Dirty hack to address hard coded logging location in manage.py
      file { '/var/log/applications/' :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755'
      }
      create_resources('wsgi::application', $applications,
        {require => File['/var/log/applications/']})
    }

  } else{
    fail('Missing values from ham_host and ham_host_token')
  }

}
