#!/bin/bash
# postgres_server_is_master.bash

IN_RECOVERY=$(su - postgres -c  "/bin/psql -tc 'select pg_is_in_recovery();'" 2> /dev/null)
if [ "${IN_RECOVERY}" == ' f' ] ; then
  echo postgres_server_is_master=t
else
  echo postgres_server_is_master=f
fi
