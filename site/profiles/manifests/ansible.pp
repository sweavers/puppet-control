# Class profiles::ansible_master
# This class will manage ansible installations.
#
# Parameters:
#  ['jenkins_plugins'] - Accepts a hash of Jenkins Plugins
#
# Sample Usage:
#   class { 'profiles::ansible_master': }
#
#

class profiles::ansible (

  $ansible_user = deployment

  ){

  # Install  ansible
  ensure_packages(['ansible'])

  #  Set up the anssible hosts file
  file { '/etc/ansible/hosts':
    ensure  => present,
    content => template('profiles/ansible_hosts.erb'),
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package['ansible']
  }

  # Populate host file from puppetdb
  File_line <<||>> {
    path    => '/etc/ansible/hosts',
    tag     => 'ansible_hosts',
    require => File['/etc/ansible/hosts']
  }

  # Disable stric host checking
  file_line { '/etc/ansible/ansible.cfg':
    path  => '/etc/ansible/ansible.cfg',
    line  => 'host_key_checking = False',
    match => '^#host_key_checking.$*'
  }

  # Create basic playbook to run puppet agent
  file { '/etc/ansible/puppet_agent.yaml':
    ensure  => present,
    content => template('profiles/puppet_agent.yaml.erb'),
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package['ansible']
  }

  # Create basic playbook to switch machines between puppet environments
  file { '/etc/ansible/puppet_environment.yaml':
    ensure  => present,
    content => template('profiles/puppet_environment.yaml.erb'),
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package['ansible']
  }
}
