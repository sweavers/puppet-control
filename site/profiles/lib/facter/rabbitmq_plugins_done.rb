# rabbitmq_plugins_done.rb

Facter.add('rabbitmq_plugins_done') do
    setcode '/usr/bin/ls /var/lib/rabbitmq/.plugins_done > /dev/null 2>&1 ; echo $?'
end
