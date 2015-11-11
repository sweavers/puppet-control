# Class profiles::postgresqlHA
#
# This class will manage PostgreSQL installations
#
# Parameters:
#  ['port']     - Port which PostgreSQL should listen on. Defaults = 5432
#  ['version']  - Version of PostgreSQL to install. Default = 9.3
#  ['remote']   - Should PostgreSQL listen for remote connections. Defaults true
#  ['dbroot']   - Location installation should be placed. Defaults = /postgres
#
# Requires:
# - puppetlabs/postgresql
# - puppetlabs/stdlib
#
# Sample Usage:
#   class { 'profiles::postgresql':
#     remote => ['192.168.1.2']
#   }
#
# Hiera Lookups:
#
# postgres_databases:
#   systemofrecord:
#    user: systemofrecord
#    password: md511c5a6395e27555ef43eb7b05c76d7c1
#    owner: systemofrecord

# postgres_users:
#   deployment:
#     password_hash: md5dddbab2fa26c65fadeaa8b1076329a14
#
##
# pg_hba_rule:
#   test:
#     description: test
#     type: host
#     database: all
#     user: all
#     address: 0.0.0.0/0
#     auth_method: md5
#

class profiles::postgresqlha_nodec(

  $port          = 5432,
  $version       = '9.4',
  $remote        = true,
  $dbroot        = '/postgres',
  $databases     = hiera_hash('postgres_databases',false),
  $users         = hiera_hash('postgres_users', false),
  $pg_hba_rule   = hiera_hash('pg_hba_rule', false)

){

  file { '/etc/repmgr/9.4/repmgr.conf':
    ensure => file,
    source => "/vagrant/puppet-control/site/profiles/files/postgres_repmgr_nodec.conf",
  }

  file { '/etc/keepalived/keepalived.conf':
    ensure => file,
    source => "/vagrant/puppet-control/site/profiles/files/postgres_keepalived_nodec.conf",
  }

  service {'keepalived':
    ensure => running,
    enable => true,
  }

}
