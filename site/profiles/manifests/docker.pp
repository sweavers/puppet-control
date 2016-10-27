class profiles::docker (


){

yumrepo { 'DockerRepository':
  ensure    => 'present',
  baseurl   => 'https://yum.dockerproject.org/repo/main/centos/$releasever/',
  enabled   => 1,
  gpgcheck  => 1,
  gpgkey    => 'https://yum.dockerproject.org/gpg'
}

package {'python-pip' :
    ensure => present,
}

package { 'docker-engine' :
    ensure => present,
    require => Yumrepo['DockerRepository']
  }

package {'backports.ssl-match-hostname' :
     provider => pip,
     ensure   => '3.5.0.1',
     require  => Package['python-pip']
}

package {'docker-compose' :
   provider => pip,
   ensure   => present,
   require  => Package['backports.ssl-match-hostname']
}

}
