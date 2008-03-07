#!/bin/bash
#
# failover.sh
# this file is part of the highbase suite
# Copyrght (C) 2002 Fernando Ipar. see the file COPYING for more info
#

# the slave node will run this script if mysql-monitor
# fails but the master machine is still running
# this is run only AFTER mysql_kill.sh and mysql_restart.sh are
# tried

HIGHBASE_HOME="$(dirname "$0")"
export HIGHBASE_HOME
. $HIGHBASE_HOME/common.sh

#this line has two reasons:
#1) it should be impossible but might just happen that we try and go for a takeover while the master has started to
#provide the service again (this SHOULD be IMPOSSIBLE since we forced a failover first, but if we put the words
#High Availability on this project's name, we might aswell expect unexpected things and be prepared
#2) a user with root privileges might accidentaly run this script, so we want to make sure that we really need
#to do a takeover
$HIGHBASE_HOME/mysql-monitor "$CLUSTER_IP" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE" && log "failover attempt with master node up (error)" && exit 1


SUDO=$(cat $HIGHBASE_HOME/sudo_prefix)


#this is a boolean variable. if it is 0, then a soft failover
#is executed, otherwise, a hard failover is executed. 
#note that if it is NULL, a hard failover is executed aswell. 
#
#a soft failover means that i release the ip, shutdown mysql, kill any
#related process that might be otherwise running and sit waiting for
#someone to come fix me
#
#a hard failover means that i release the IP and shutdown the box.
SOFT_FAIL=1

[ -z "$SOFT_FAIL" ] && SOFT_FAIL=1

${SUDO}${IFCONFIG} -a | grep Link | awk '{print $1}' | while read ifname; do
        [ "$(${SUDO}${IFCONFIG} $ifname | grep inet|awk '{print $2}'|awk -F: '{print $2}')" == "$CLUSTER_IP" ] && ${SUDO}${IFCONFIG} $ifname del $CLUSTER_IP
done

[ $SOFT_FAIL -eq 0 ] && {
	sync #this is potentially dangerous in case the service is down due to a disk error, 
	     #since this call may wait forever. still, if this was the case, ssh wouldn't probably
	     #work either so this script would never be executed (gratuitious ARP would have
	     #to do the job)
	${SUDO}$RC_SCRIPT stop
	${SUDO}${PS} -fu mysql |awk '{print $2}'|xargs ${SUDO}${KILL}
	$SLEEP $(extractTime $SIG_KILL_WAIT)
	${SUDO}${PS} -fu mysql |awk '{print $2}'|xargs ${SUDO}${KILL} -9
	log "failover finished, soft mode (notify)"
	exit 0
} || {
	sync; sync
	log "starting failover, hard mode, shutting down box (notify)"
	nohup ${SUDO}${SHUTDOWN} -h now &
}
