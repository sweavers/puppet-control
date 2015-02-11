# Class: profiles::puppet::agent
#
# This class installs and configures a Puppet Agent
#
# Parameters:
#  ['environment'] - FQDN of Puppet Master server
#  ['environment'] - Region of this puppet node. Defaults to 'production'
#  ['arguments']   - Puppet Agent arguments
#  ['run_hours']   - Cron-style hour setting for when to apply Puppet runs
#  ['run_days']    - Cron-style day setting for when to apply Puppet runs
#
# Sample Usage:
#  class { 'profiles::puppet::agent':
#    environment => 'development',
#    run_hours   => '*'
#    run_days    => '*'
#  }
#
class profiles::puppet::agent (

  $master_fqdn = 'puppet',
  $environment = 'production',
  $arguments   = '--no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
  $run_hours   = '08-16',
  $run_days    = '1-5',

){

  # stephenrjohnson/puppet
  class { '::puppet::agent':
    puppet_server       => $master_fqdn,
    environment         => $environment,

    # Scheduling
    puppet_run_style    => 'external',
    puppet_run_interval => 30,
    splay               => true,
    ordering            => 'title-hash',
  }

  # Only carry out Puppet runs inside of a specific time window
  cron { 'puppet-agent':
    command => "/usr/bin/puppet agent ${arguments}",
    user    => root,
    minute  => [0,30],
    hour    => $run_hours,
    weekday => $run_days,
  }

}
