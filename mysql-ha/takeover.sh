#!/bin/bash
#
# takeover.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more information


DB_USER=root
DB_PASSWORD=rootpwd

. /usr/mysql-ha/common.sh

ATTEMPTS=3
#this line has two reasons: 
#1) it should be impossible but might just happen that we try and go for a takeover while the master has started to
#provide the service again (this SHOULD be IMPOSSIBLE since we forced a failover first, but if we put the words
#High Availability on this project's name, we might aswell expect unexpected things and be prepared
#2) a user with root privileges might accidentaly run this script, so we want to make sure that we really need
#to do a takeover

mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE && log "takeover attempt with master node up (error)" && exit 1

#stop replicating
echo "slave stop" | mysql -u${DB_USER} -p${DB_PASSWORD}

#start listening
ifconfig eth0 add $IP_CLUSTER

fping -c$ATTEMPTS $CLUSTER_IP && {
	log "takeover with master node still holding cluster ip, going to gratuitious ARP mode (error)"
	nohup /usr/mysql-ha/steal_master_ip.sh &
}

log "takeover complete (notify)"
exit 0
