# yum_updates.rb
# Additional Facts for when yum update was last run and amount of yum packages to update
#

require 'fileutils'

# Create facts directory if it doesn't exist
FileUtils.mkdir_p '/etc/facter/facts.d/'

# Create a new file called yum_updates.txt
open('/etc/facter/facts.d/yum_updates.txt', 'w') { |f|
  # Create a variable called "yum_available_updates" and write the amount of yum updates available to it
  value = Facter::Core::Execution.exec('yum check-update --quiet | grep "^[a-z0-9]" | wc -l')
  f.puts "yum_available_updates=" + value

  # Create a variable called "yum_last_update" and write the last time an update was run
  value = Facter::Core::Execution.exec('cat /var/log/yum.log | grep Updated: | tail -1 | awk \'{print $1 " " $2 " " $3}\'')
  f.puts "yum_last_update=" + value
}
