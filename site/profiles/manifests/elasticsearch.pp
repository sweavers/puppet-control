# Class profiles::elasticsearch
#
# Will install elasticsearch on a node.
#
# Sample Usage:
#   class { 'profiles::elasticsearch': }
#
class profiles::elasticsearch(
  $clustername = 'unknown',
  $nodenumber  = '00'
){

  class {'::elasticsearch' :
    manage_repo  => true,
    repo_version => 1.4,
    java_install => true,
    config       => {
      'cluster.name' => $clustername
      }
  }

  elasticsearch::instance { "es-${nodenumber}": }

}
