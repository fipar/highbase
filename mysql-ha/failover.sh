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


. /usr/mysql-ha/common.sh



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

ifconfig $CLUSTER_DEVICE down
ifconfig $CLUSTER_DEVICE del $CLUSTER_IP

[ $SOFT_FAIL -eq 0 ] && {
	sync #this is potentially dangerous in case the service is down due to a disk error, 
	     #since this call may wait forever. still, if this was the case, ssh wouldn't probably
	     #work either so this script would never be executed (gratuitious ARP would have
	     #to do the job)
	$MYSQL_RC stop
	ps -fu mysql |awk '{print $2}'|xargs kill
	sleep $SIG_KILL_WAIT 
	ps -fu mysql |awk '{print $2}'|xargs kill -9
	log "failover finished, soft mode (notify)"
	exit 0
} || {
	sync
	log "starting failover, hard mode, shutting down box (notify)"
	nohup /sbin/shutdown -h now &
}