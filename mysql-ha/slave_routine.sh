#!/bin/bash
#
# slave_routine.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar, see the file COPYING for more info

. /usr/mysql-ha/common.sh

#cuando una comprobacion falla, se usa este valor para esperar antes de
#realizar la siguiente y dar por muerto al nodo
#when mysql.monitor fails, we wait this time (secs) until we check again
#to see if the master is really gone
CHK_THRESHOLD=300


#time we wait before checking, after running mysql_kill
KILL_WAIT=60

#time we wait before checking, after running mysql_restart
RESTART_WAIT=60


#when we decide the master is gone, we try to fping it to see if the machine is
#running. we try ATTEMPTS times, waiting ATTEMPTS_SLEEP between attempts. 
ATTEMPTS=3
ATTEMPTS_SLEEP=5

CHK_PROG="mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE"


attempt_kill()
{
	log "about to run mysql_kill on $MASTER_NODE"
	ssh root@$MASTER_NODE /usr/mysql-ha/mysql_kill.sh
	sleep $T_KILL
	$CHK_PROG && return 0 || return 1
}


attempt_restart()
{
	log "about to run mysql_restart on $MASTER_NODE"
	ssj root@$MASTER_NODE /usr/mysql-ha/mysql_restart.sh
	sleep $T_RESTART
	$CHK_PROG && return 0 || return 1
}


#see if we should be running
shouldrun()
{
[ -f /tmp/nocluster ] && return 1 || return 0
}


#main()
shouldrun || log "shouldrun was unsuccessfull (ok)"


CHK_PROG="mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE"

$CHK_PROG && log "mysql responded (ok)" || {
	sleep $CHK_THRESHOLD
	$CHK_PROG && "mysql responded within CHK_THRESHOLD (warning)" || {
		fping -c$ATTEMPTS $MASTER_NODE && {
			attempt_kill && {
				log "mysql.monitor was succesfull after kill (notify)"
				exit 0
			}
			attempt_restart && {
				log "mysql.monitor was succesfull after restart (notify)"
				exit 0
			} 
			log "mysql.monitor failed but $MASTER_NODE is running, going for the takeover (error)"
			#this should change for a service running on the master node itself, so we can discover weird
			#problems like a loop on the scsi driver, it has happened to me!. in this case, linux is running ok, 
			#but it can't access the filesystem so nothing that depends on files can run (including mysql, but
			#also including remote shells, or anything that uses files/sockets). 
			ssh root@$MASTER_NODE /usr/mysql-ha/failover.sh

		} || {
			log "mysql.monitor failed but $MASTER_NODE was dead (error)"
		}
			/usr/mysql-ha/takeover.sh
	}
}

