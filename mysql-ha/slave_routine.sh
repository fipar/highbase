#!/bin/bash
#
# slave_routine.sh
# this file is part of the highbase suite
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

HIGHBASE_HOME="$(dirname "$0")"
export HIGHBASE_HOME
. $HIGHBASE_HOME/common.sh

CHK_PROG="$HIGHBASE_HOME/mysql-monitor \"$CLUSTER_IP\" \"$MYSQL_USER\" \"$MYSQL_PASSWORD\" \"$MYSQL_DATABASE\""

SSH_USER=$(< $HIGHBASE_HOME/ssh_user)
SUDO=$(< $HIGHBASE_HOME/sudo_prefix)
FPING=$HIGHBASE_HOME/extern/fping

#
# we try to kill every mysql process on the master node, except for the replication thread, just in case the node isn't responding
# becaused it's choked by a bad client, a deadlock, etc.
attempt_kill() {
	log "about to run mysql_kill on $MASTER_NODE (warning)"
	$HIGHBASE_HOME/wrapper_safe_cmd.sh $SSH_PATIENCE $HIGHBASE_HOME/pwrap ssh ${SSH_USER}@$MASTER_NODE $HIGHBASE_HOME/mysql_kill.sh || log "could not run mysql_kill.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
	$SLEEP $(extractTime $MYSQL_KILL_WAIT)
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && return 0 || return 1
}

attempt_restart() {
	log "about to run mysql_restart on $MASTER_NODE (warning)"
	wrapper_safe_cmd.sh $SSH_PATIENCE $HIGHBASE_HOME/pwrap ssh ${SSH_USER}@$MASTER_NODE $HIGHBASE_HOME/restart_mysql.sh || log "could not run mysql_restart.sh on $MASTER_NODE due to timeout abortion of safe_cmd.sh (error)"
	$SLEEP $(extractTime $MYSQL_RESTART_WAIT)
	wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && return 0 || return 1
}

#see if we should be running
#file /tmp/nocluster acts as an inhibitor of the cluster.
#this mechanism should be improved for security in the future
shouldrun() {
	[ -f /tmp/nocluster ] && return 1 || return 0
}

main() {
	shouldrun || { 
		log "shouldrun was unsuccessfull (ok)"
		sleep $SLAVE_SLEEP_TIME
		continue
	}

	if [ -n "${MYSQL_USER}" ]; then
		echo "Horrible error, no configuration."
		exit 1
	fi

	MYSQL_VER=`mysql --version |awk '{ print $5 }' |awk -F. '{ print $1 }'`

	[ "$MYSQL_VER" == "3" ] && {
		SLAVE_STATUS=`echo "show slave status" | mysql -u$DB_USER -p$DB_PASSWORD |awk '{ print $7 }' |sed -n -e /Yes/p`
	}

	## In MySQL version 4.x the replication thread has two parts, for now we'll
	#  assume that SLAVE_STATUS is "Yes" only if both parts are active
	[ "$MYSQL_VER" != "3" ] && {
		SLAVE_STATUS=`echo "show slave status" | mysql -u"$DB_USER" -p"$DB_PASSWORD" |awk '{ print $10 $11 }' |sed -n -e /No/p`
		## this could be YesNo, NoYes, NoNo, or blank
		[ "$SLAVE_STATUS" == "" ] && SLAVE_STATUS="Yes"
	}

	[ "$SLAVE_STATUS" == "Yes" ] && MYSQL_REPL=1
	[ "$SLAVE_STATUS" != "Yes" -a "$MYSQL_REPL" == "1" ] && {
		MYSQL_REPL=0
		log "slave stopped (notify)"
	}

	#CHK_PROG="$HIGHBASE_HOME/mysql-monitor \"$MASTER_NODE\" \"$MYSQL_USER\" \"$MYSQL_PASSWORD\" \"$MYSQL_DATABASE\""
	should_failover=0

	#this new little config change allows for a faster recovery if you know most of the times mysql will be down 
	#instead of just choked with processess
	#notice that by default, WE NO LONGER ATTEMPT TO KILL ALL MYSQL PROCESSES, we just go straight into the restart procedure, 
	#thus saving a few seconds
	[ -n "$ATTEMPT_KILL" ] || ATTEMPT_KILL=0

	$HIGHBASE_HOME/wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && log "mysql responded (ok)" || {
		$SLEEP $(extractTime $MONITOR_CHK_THRESHOLD)
		$HIGHBASE_HOME/wrapper_safe_cmd.sh $MONITOR_PATIENCE $CHK_PROG && "mysql responded within MONITOR_CHK_THRESHOLD (warning)" || {
			${SUDO}${FPING} -c $FPING_ATTEMPTS $MASTER_NODE && {
				[ $ATTEMPT_KILL -eq 1 ] &&  attempt_kill && {
					log "mysql-monitor was succesfull after kill (notify)"
					return 0
				}
				attempt_restart && {
					log "mysql-monitor was succesfull after restart (notify)"
					return 0
				} 
				#this should change for a service running on the master node itself, so we can discover weird
				#problems like a loop on the scsi driver, it has happened to me!. in this case, linux is running ok, 
				#but it can't access the filesystem so nothing that depends on files can run (including mysql, but
				#also including remote shells, or anything that uses files/sockets). 
				should_failover=1
			} || {
				log "mysql-monitor failed but $MASTER_NODE was dead (error)"
			}
			$HIGHBASE_HOME/takeover.sh
			[ $should_failover -eq 1 ] && {
				log "mysql-monitor failed but $MASTER_NODE is running, going for the failover (error)"
				$HIGHBASE_HOME/wrapper_safe_cmd.sh $SSH_PATIENCE $HIGHBASE_HOME/pwrap ssh ${SSH_USER}@$MASTER_NODE $HIGHBASE_HOME/failover.sh || {
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
