#
class profiles::application (
  $applications = hiera_hash('applications',false)
){
  include ::wsgi
  include ::stdlib

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

}
