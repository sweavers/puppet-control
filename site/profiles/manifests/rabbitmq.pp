# Class profiles::rabbitmq
#
# This class will manage rabbitmq installations
#
# Parameters:
#  ['port']    - Port which RabbitMQ should listen on. Defaults = 5672
#  ['version'] - Version of RabbitMQ to install. Default = 3.4.4
#
# Requires:
# - puppetlabs/rabbitmq
# - garethr/erlang
#
# Sample Usage:
#   class { 'profiles::rabbitmq':
#     version => '3.4.4'
#   }
#
class profiles::rabbitmq(

  $port              = 5672,
  $version           = '3.4.4',
  $delete_guest_user = true,
  $default_user      = 'guest',
  $default_pass      = 'guest',
  $cluster           = false,
  $cluster_nodes     = [],
  $erlang_cookie     = 'super_secret_key',
  $admin_enable      = false

){

  # Load SELinuux policy for RabbitMQ
  selinux::module { 'rabbit':
    ensure => 'present',
    source => 'puppet:///modules/profiles/rabbit.te'
  }

  # Red Hat uses weird version numbers
  if $::osfamily == 'RedHat' {
    $ver = "${version}-1"
    class { 'erlang': epel_enable => true }
  } else {
    $ver = $version
    package { 'erlang-base': ensure => 'latest' }
  }

  include ::erlang

  case $cluster {
    true : {
      class { '::rabbitmq':
        version                  => $ver,
        port                     => $port,
        default_user             => $default_user,
        default_pass             => $default_pass,
        delete_guest_user        => $delete_guest_user,
        cluster_nodes            => $cluster_nodes,
        cluster_node_type        => 'disc',
        erlang_cookie            => $erlang_cookie,
        wipe_db_on_cookie_change => true,
        config_cluster           => true,
        admin_enable             => $admin_enable,
        require                  => Class[erlang]
      }
    }
    default : {
      class { '::rabbitmq':
        version           => $ver,
        port              => $port,
        default_user      => $default_user,
        default_pass      => $default_pass,
        delete_guest_user => $delete_guest_user,
        admin_enable      => $admin_enable,
        require           => Class[erlang]
      }
    }
  }


  include stdlib

  create_resources('rabbitmq_user', hiera_hash('rabbitmq_users'))
  create_resources('rabbitmq_user_permissions', hiera_hash('rabbitmq_user_permissions'))

}
