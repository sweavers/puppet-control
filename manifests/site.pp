# Global defaults for all nodes

# Include classes specified in Hiera
hiera_include('classes')

# Default executable path
Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
}

# Default file permissions to root:root
File {
  owner => 'root',
  group => 'root',
}
