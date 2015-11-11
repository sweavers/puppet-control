echo "Promoting Standby at `date '+%Y-%m-%d %H:%M:%S'`" >>/var/log/repmgr/repmgr.log
/usr/pgsql-9.4/bin/repmgr -f /etc/repmgr/9.4/repmgr.conf --verbose standby promote >>/var/log/repmgr/repmgr.log
