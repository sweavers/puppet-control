#!/usr/bin/env bash

echo "server_available_updates=$(yum check-update --quiet | grep '^[a-z0-9]' | wc -l)"
echo "server_last_update=$(cat /var/log/yum.log | grep Updated: | tail -1 | awk '{print $1 " " $2 " " $3}')"
