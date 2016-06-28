# yum_updates.rb
# Additional Facts for when yum update was last run and amount of yum packages to update
#

Facter.add('yum_available_updates') do
  setcode do
    Facter::Core::Execution.exec('yum check-update --quiet | grep "^[a-z0-9]" | wc -l')
  end
end

Facter.add('yum_last_update') do
  setcode do
    Facter::Core::Execution.exec('cat /var/log/yum.log | grep Updated: | tail -1 | awk \'{print $1 " " $2 " " $3}\'')
  end
end
