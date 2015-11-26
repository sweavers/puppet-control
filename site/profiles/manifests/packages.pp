#
class profiles::packages (

  $packages = hiera_array(packages)

){
    include ::stdlib

    if $packages {
      package{ $packages :
        ensure  => installed,
      }
    }
  }
