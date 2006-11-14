#!/bin/bash
#
# failover.sh
# this file is part of the mysql-ha suite
# Copyrght (C) 2002 Fernando Ipar. see the file COPYING for more info
#

# the slave node will run this script if mysql.monitor
# fails but the master machine is still running
# this is run only AFTER mysqk_kill.sh and mysql_restart.sh are
# tried


. $MYSQLHA_HOME/common.sh

SUDO=$(cat $MYSQLHA_HOME/sudo_prefix)


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

${SUDO}ifconfig -a | grep Link | awk '{print $1}' | while read ifname; do
        [ "$(${SUDO}ifconfig $ifname | grep inet|awk '{print $2}'|awk -F: '{print $2}')" == "$CLUSTER_IP" ] && ${SUDO}ifconfig $ifname del $CLUSTER_IP
done

[ $SOFT_FAIL -eq 0 ] && {
	sync #this is potentially dangerous in case the service is down due to a disk error, 
	     #since this call may wait forever. still, if this was the case, ssh wouldn't probably
	     #work either so this script would never be executed (gratuitious ARP would have
	     #to do the job)
	${SUDO}$RC_SCRIPT stop
	${SUDO}ps -fu mysql |awk '{print $2}'|xargs ${SUDO}kill
	sleep $SIG_KILL_WAIT 
	${SUDO}ps -fu mysql |awk '{print $2}'|xargs ${SUDO}kill -9
	log "failover finished, soft mode (notify)"
	exit 0
} || {
	sync; sync
	log "starting failover, hard mode, shutting down box (notify)"
	nohup ${SUDO}/sbin/shutdown -h now &
}
