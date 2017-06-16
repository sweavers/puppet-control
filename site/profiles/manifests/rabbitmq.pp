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

  $port                      = 5672,
  $version                   = '3.4.4',
  $delete_guest_user         = true,
  $default_user              = 'guest',
  $default_pass              = 'guest',
  $cluster                   = false,
  $cluster_nodes             = [],
  $erlang_cookie             = 'super_secret_key',
  $admin_enable              = false,
  $rabbitmq_users            = hiera_hash('rabbitmq_users', false),
  $rabbitmq_user_permissions = hiera_hash('rabbitmq_user_permissions', false),
  $rabbitmq_vhosts           = hiera_hash('rabbitmq_vhosts', false),
  $rabbitmq_policy           = hiera_hash('rabbitmq_policy', false),
  $time_period               = hiera('nagios_time_period', '24x7')

){

  include profiles::rabbitmq_monitoring

  # Load SELinuux policy for RabbitMQ
  selinux::module { 'rabbit':
    ensure => 'present',
    source => 'puppet:///modules/profiles/rabbit.te'
  }

  class { 'erlang': epel_enable => true }
  include ::erlang

  # Install rabbit direct from rabbit (if not epel version)
  if $version != '3.3.5' {
    package { "rabbitmq-server-${version}-1.noarch" :
      ensure   => 'installed',
      provider => 'rpm',
      source   => "https://www.rabbitmq.com/releases/rabbitmq-server/v${version}/rabbitmq-server-${version}-1.noarch.rpm",
      require  => Class[erlang]
    }
    notify { "rabbit-server package version ${version} installed direct from rabbit":}
  } else {
    notify { "rabbit-server package version ${version} will be installed from epel":}
  }

  case $cluster {
    true : {
      class { '::rabbitmq':
        version                  => "${version}-1",
        repos_ensure             => true,
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
        version           => "${version}-1",
        repos_ensure      => true,
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

  if $rabbitmq_users {
    create_resources('rabbitmq_user', $rabbitmq_users)
  }
  if $rabbitmq_user_permissions {
    create_resources('rabbitmq_user_permissions', $rabbitmq_user_permissions)
  }
  if $rabbitmq_vhosts {
    create_resources('rabbitmq_vhost', $rabbitmq_vhosts)
  }
  if $rabbitmq_policy {
    create_resources('rabbitmq_policy', $rabbitmq_policy)
  }
}
