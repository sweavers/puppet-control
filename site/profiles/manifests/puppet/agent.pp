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
  $arguments   = '--no-daemonize --onetime --logdest syslog > /dev/null 2>&1',
  $run_hours   = '08-16',
  $run_days    = '1-5',
  $environment = hiera( environment , 'production')

){

  # Set up puppetlabs repos
  yumrepo { 'puppetlabs-deps':
    baseurl  => "http://yum.puppetlabs.com/el/\$releasever/dependencies/\$basearch",
    descr    => 'Puppet Labs Dependencies $releasever - $basearch ',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
  }

  yumrepo { 'puppetlabs':
    baseurl  => "http://yum.puppetlabs.com/el/\$releasever/products/\$basearch",
    descr    => 'Puppet Labs Products $releasever - $basearch',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
  }

  # Install puppet
  package { 'puppet':
    ensure  => present,
    require => Yumrepo['puppetlabs-deps','puppetlabs']
  }

  # Ensure service is not running so that agent runs can be controlled by cron
  service { 'puppet':
    ensure  => stopped,
    enable  => false,
    require => Package['puppet']
  }

  # Ensure that the puppet agent config file is only written from the template on the first run
  if $::puppet_agent_initial_setup_done != 1 {

    # Create the agent config file from template
    file { '/etc/puppet/puppet.conf':
      ensure  => file,
      content => template('profiles/puppet-agent.conf.erb'),
      require => Package['puppet']
    } ->

    # Create a fact confirming that the initial set up is complete.
    file { '/etc/puppetlabs/facter/facts.d/puppet_agent_initial_setup_done.sh':
      ensure  => file,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => "echo 'puppet_agent_initial_setup_done=1'"
    }
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
