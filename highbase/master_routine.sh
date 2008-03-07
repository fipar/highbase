#!/bin/bash
#
# master_routine.sh
# this file is part of the highbase suite
# Copyright (C) 2002 Fernando Ipar, see the file COPYING for more info

HIGHBASE_HOME="$(dirname "$0")"
export HIGHBASE_HOME
. $HIGHBASE_HOME/common.sh

shouldrun() {
	[ -f /tmp/nocluster ] && return 1 || return 0
}

main() {
	shouldrun || log "shouldrun returned false (ok)"

	if [ -n "${MYSQL_USER}" ]; then
		echo "Horrible error, no configuration."
		exit 1
	fi

	CHK_PROG="${HIGHBASE_HOME}/mysql-monitor \"$SLAVE\" \"$MYSQL_USER\" \"$MYSQL_PASSWORD\" \"$MYSQL_DATABASE\""

	$CHK_PROG && log "mysql-monitor was succesfull (ok)" || {
		$SLEEP $(extractTime $MONITOR_CHK_THRESHOLD)
		$CHK_PROG && log "mysql-monitor was successfull in $SLAVE within CHK_THRESHOLD (warning)" || {
			log "mysql-monitor was unsuccssessfull in $SLAVE (warning)"
		}
	}
}

while :; do
	main
	sleep $MASTER_SLEEP_TIME
done

