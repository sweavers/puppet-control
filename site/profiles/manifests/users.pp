# Class profiles::users
# This class will manage adminsusers on a host.
# It's important to note that it is currently only possible
# to add one 'set' of users and they must therefore all be specified
# in one place - this will need to be fixed.
#
# Parameters: #Paramiters accepted by the class
# ['users_array'] - array (currently not worrking default value usedd)
#
# Requires: #Modules required by the class
# - mthibaut/users
#
# Sample Usage:
# class { 'profiles::users': }
#
# Hiera:
#
#users_sysadmins:
#  john:
#    ensure: present
#    uid: 1000
#    gid: staff
#    groups:
#    comment: John Doe
#    managehome: true
#    ssh_authorized_keys:
#      john_key:
#        type: 'ssh-rsa'
#        key:  'mykeydata=='
#  tom:
#    ensure: present
#    uid: 1010
#    gid: staff
#    groups:
#    comment: TomJ Doe
#    managehome: true
#    ssh_authorized_keys:
#      tom_key:
#        type: 'ssh-rsa'
#        key:  'mykeydata=='
#
class profiles::users (

  $users_array = ['sysadmins', 'users']

  ){


  # mthibaut/users
  users { $users_array : }

}
