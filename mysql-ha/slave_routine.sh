#!/bin/bash
#
# slave_routine.sh
# this file is part of the mysql-ha suite
# Copyright 2002 Fernando Ipar - fipar@acm.org / fipar@users.sourceforge.net

# This program is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307 USA

. /usr/mysql-ha/common.sh



CHK_PROG="mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE"


attempt_kill()
{
	log "about to run mysql_kill on $MASTER_NODE"
	wrapper_safe_cmd.sh $SSH_PATIENCE ssh root@$MASTER_NODE /usr/mysql-ha/mysql_kill.sh || log "could not run mysql_kill.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
	sleep $MYSQL_KILL_WAIT
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && return 0 || return 1
}


attempt_restart()
{
	log "about to run mysql_restart on $MASTER_NODE"
	wrapper_safe_cmd.sh $SSH_PATIENCE ssh root@$MASTER_NODE /usr/mysql-ha/mysql_restart.sh || log "could not run mysql_restart.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
	sleep $MYSQL_RESTART_WAIT
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && return 0 || return 1
}


#see if we should be running
#file /tmp/nocluster acts as an inhibitor of the cluster.
#this mechanism should be improved for security in the future
shouldrun()
{
[ -f /tmp/nocluster ] && return 1 || return 0
}


main()
{
shouldrun || log "shouldrun was unsuccessfull (ok)"


CHK_PROG="mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE"
should_failover=0

wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && log "mysql responded (ok)" || {
	sleep $MONITOR_CHK_THRESHOLD
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && "mysql responded within CHK_THRESHOLD (warning)" || {
		fping -c $FPING_ATTEMPTS $MASTER_NODE && {
			attempt_kill && {
				log "mysql.monitor was succesfull after kill (notify)"
				exit 0
			}
			attempt_restart && {
				log "mysql.monitor was succesfull after restart (notify)"
				exit 0
			} 
			#this should change for a service running on the master node itself, so we can discover weird
			#problems like a loop on the scsi driver, it has happened to me!. in this case, linux is running ok, 
			#but it can't access the filesystem so nothing that depends on files can run (including mysql, but
			#also including remote shells, or anything that uses files/sockets). 
			should_failover=1
		} || {
			log "mysql.monitor failed but $MASTER_NODE was dead (error)"
		}
			/usr/mysql-ha/takeover.sh
			[ $should_failover -eq 1 ] && {
				log "mysql.monitor failed but $MASTER_NODE is running, going for the takeover (error)"
				wrapper_safe_cmd.sh $SSH_PATIENCE ssh root@$MASTER_NODE /usr/mysql-ha/failover.sh || {
					log "could not failover.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
					}
			}
			should_exit=1
			
	}
}

}


should_exit=0
while [ $should_exit -eq 0 ]; do
	main
	sleep $SLAVE_SLEEP_TIME
done

log "exiting loop (after takeover) (notify)"