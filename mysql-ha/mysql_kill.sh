#!/bin/bash
#
# mysql_kill.sh
# This file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar
# see the file COPYING for more info


#i kill (MySQL internal KILL SQL command, hence the name of this script) every mysql process
#except for the replication thread (PID=1)
for pid in $(mysqladmin -u${DB_USER} -p${DB_PASSWORD} processlist|grep -v '^| Id'|awk -F\| '{print $2}'|awk '{print $1}'|grep -v ^$); do
	[ $pid -ne 1 ] && mysqladmin -u${DB_USER} -p${DB_PASSWORD} kill $pid
done