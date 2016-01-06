# pg_ha_setup_done.rb

Facter.add('pg_ha_setup_done') do
    setcode '/bin/ls /var/lib/pgsql/pg_ha_setup_done > /dev/null 2>&1 ; echo $?'
end
