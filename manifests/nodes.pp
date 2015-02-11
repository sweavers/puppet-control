# Set role based on hostname
if empty($machine_role) {
  $machine_role = regsubst($::hostname, '^(.*)-\d+$', '\1')
}

# Default nodes
node default {
}
