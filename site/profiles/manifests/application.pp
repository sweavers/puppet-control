#
class profiles::application (
  $applications = hiera_hash('applications',false)
){
  include ::wsgi
  include ::stdlib

  if $applications {
    create_resources('wsgi::application', $applications)
  }

}
