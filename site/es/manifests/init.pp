#
class es (
  $interface     = 'eth0',
  $cluster_name  = 'elasticsearch',
  $manage_java   = true,
  $minimum_nodes = 1,
  $shards        = 5,
  $replicas      = 2
){

  include stdlib
  validate_bool($manage_java)

  if ($interface == 'eth0') {
    $listen = $::ipaddress_eth0
  } elsif ($interface == 'eth1') {
    $listen = $::ipaddress_eth1
  } else {
    $listen = $::ipaddress
  }
  $repo_version = '1.7'
  $version      = '1.7.3'
  $data_dir = "/var/lib/elasticsearch/${cluster_name}/data"
  $backup_dir = '/backups'
  $log_dir =  "/var/lib/elasticsearch/${cluster_name}/logs"

  class { 'elasticsearch' :
    ensure       => present,
    manage_repo  => true,
    package_pin  => true,
    java_install => $manage_java,
    repo_version => $repo_version,
    version      => $version
  }

  elasticsearch::plugin { 'royrusso/elasticsearch-HQ' :
    instances => $cluster_name
  }

  elasticsearch::instance { $cluster_name :
    datadir => $data_dir,
    config  => {
      'cluster.name'  => $cluster_name,
      'path.repo'     => "[${backup_dir}]",
      'path.logs'     => $log_dir,
      'node'          => {
        'name'   => "${::hostname}-${cluster_name}",
        'master' => true,
        'data'   => true
      },
      'index'         => {
        'number_of_shards'   => $shards,
        'number_of_replicas' => $replicas,
      },
      'gateway'       => {
        'type'                => 'local',
        'recover_after_nodes' => 1,
        'recover_after_time'  => '2m',
        'expected_nodes'      => $minimum_nodes
      },
      'network'       => {
        'bind_host'    => '0.0.0.0',
        'publish_host' => $listen
      },
      'discovery.zen' => {
        'minimum_master_nodes' => 1,
        'ping'                 => {
          'multicast.enabled' => true
        }
      }
    }
  }

  #Create Elasticsearch backup directory
  file { $backup_dir :
    ensure  => directory,
    owner   => elasticsearch,
    group   => elasticsearch,
    require => Package ['elasticsearch']
  }

  package { 'jq' :
    ensure => installed
  }
}
