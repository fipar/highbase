#!/bin/bash
#
# master_routine.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar, see the file COPYING for more info

shouldrun()
{
[ -f /tmp/nocluster ] && return 1 || return 0
}

main()
{

shouldrun || log "shouldrun returned false (ok)"


CHK_PROG="mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $SLAVE"

$CHK_PROG && log "mysql.monitor was succesfull (ok)" || {
	sleep $MONITOR_CHK_THRESHOLD
	$CHK_PROG && log "mysql.monitor was successfull in $SLAVE within CHK_THRESHOLD (warning)" || {
		log "mysql.monitor was unsuccssessfull in $SLAVE (warning)"
	}
}

}

while :; do
	main
	sleep $MASTER_SLEEP_TIME
done