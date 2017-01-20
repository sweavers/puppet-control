/usr/pgsql-9.4/bin/repmgr -f /etc/repmgr/9.4/repmgr.conf cluster show 2> /dev/null | grep 'master.*'`hostname -s`
