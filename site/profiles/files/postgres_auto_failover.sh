sed -i -e 's/#BARMAN# //' -e '/archive_command = false/ d' /var/lib/pgsql/9.4/data/postgresql.conf
/usr/pgsql-9.4/bin/pg_ctl reload
/usr/pgsql-9.4/bin/repmgr -f /etc/repmgr/9.4/repmgr.conf --verbose standby promote
