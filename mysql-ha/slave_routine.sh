#!/bin/bash
#
# slave_routine.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar, see the file COPYING for more info

. /usr/mysql-ha/common.sh

#timeout in seconds for the ssh command
#take into consideration that this is not just an ssh timeout, 
#if the failover/takeover procedure is delayed, it will be deemed
#as timeout too...
SSH_PATIENCE=40
#timeout in seconds for the mysql.monitor command
MONITOR_PATIENCE=20

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
	wrapper_safe_cmd.sh $SSH_PATIENCE ssh root@$MASTER_NODE /usr/mysql-ha/mysql_kill.sh || log "could not run mysql_kill.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
	sleep $T_KILL
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && return 0 || return 1
}


attempt_restart()
{
	log "about to run mysql_restart on $MASTER_NODE"
	wrapper_safe_cmd.sh $SSH_PATIENCE ssh root@$MASTER_NODE /usr/mysql-ha/mysql_restart.sh || log "could not run mysql_restart.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
	sleep $T_RESTART
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && return 0 || return 1
}


#see if we should be running
#file /tmp/nocluster acts as an inhibitor of the cluster.
#this mechanism should be improved for security in the future
shouldrun()
{
[ -f /tmp/nocluster ] && return 1 || return 0
}


#main()
shouldrun || log "shouldrun was unsuccessfull (ok)"


CHK_PROG="mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE"

wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && log "mysql responded (ok)" || {
	sleep $CHK_THRESHOLD
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && "mysql responded within CHK_THRESHOLD (warning)" || {
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
			FAILOVER_OK=0
			wrapper_safe_cmd.sh $SSH_PATIENCE ssh root@$MASTER_NODE /usr/mysql-ha/failover.sh || {
				log "could not failover.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
				FAILOVER_OK=1
				}

		} || {
			log "mysql.monitor failed but $MASTER_NODE was dead (error)"
		}
			/usr/mysql-ha/takeover.sh $FAILOVER_OK
	}
}

