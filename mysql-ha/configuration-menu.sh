#!/bin/bash
#
# configuration-menu.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info. 

#
# asks the user for the configuration keys one by one, providing 
# default values when applicable
#

cat <<EOMSG
	configuration script for mysql-ha
	default values will be placed inside [] where available
	you must specify a value for every variable that doesn't 
	have a default
	
	
EOMSG

FIL=/etc/mysql-ha.conf

while [ -z "$CLUSTER_IP" ]; do
	echo -n "CLUSTER_IP (the public IP that is shared between master and slave nodes): "; read CLUSTER_IP
done
echo "CLUSTER_IP=$CLUSTER_IP" >$FIL

while [ -z "$CLUSTER_NETMASK" ]; do
	echo -n "CLUSTER_NETMASK: "; read CLUSTER_NETMASK
done
echo "CLUSTER_NETMASK=$CLUSTER_NETMASK" >> $FIL

while [ -z "$CLUSTER_BROADCAST" ]; do
	echo -n "CLUSTER_BROADCAST: "; read CLUSTER_BROADCAST
done
echo "CLUSTER_BROADCAST=$CLUSTER_BROADCAST" >> $FIL

while [ -z "$CLUSTER_DEVICE" ]; do
	echo -n "CLUSTER_DEVICE: [eth0] "; read CLUSTER_DEVICE; [ -z "$CLUSTER_DEVICE" ] && CLUSTER_DEVICE=eth0
done
echo "CLUSTER_DEVICE=$CLUSTER_DEVICE" >> $FIL

while [ -z "$MYSQL_USER" ]; do
	echo -n "MYSQL_USER: [replicator] "; read MYSQL_USER; [ -z "$MYSQL_USER" ] && MYSQL_USER=replicator
done
echo "MYSQL_USER=$MYSQL_USER" >> $FIL

while [ -z "$MYSQL_PASSWORD" ]; do
	echo -n "MYSQL_PASSWORD: [replicatorpwd] "; read MYSQL_PASSWORD; [ -z "$MYSQL_PASSWORD" ] && MYSQL_PASSWORD=replicatorpwd
done
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> $FIL

while [ -z "$MYSQL_DATABASE" ]; do
	echo -n "MYSQL_DATABASE: [testdb] "; read MYSQL_DATABASE; [ -z "$MYSQL_DATABASE" ] && MYSQL_DATABASE=testdb
done
echo "MYSQL_DATABASE=$MYSQL_DATABASE" >> $FIL

while [ -z "$ARP_REFRESH_TIME" ]; do
	echo -n "ARP_REFRESH_TIME: [5] "; read ARP_REFRESH_TIME; [ -z "$ARP_REFRESH_TIME" ] && ARP_REFRESH_TIME=5
done
echo "ARP_REFRESH_TIME=$ARP_REFRESH_TIME" >> $FIL

while [ -z "$DEFAULT_MAC_ADDR" ]; do
	echo -n "DEFAULT_MAC_ADDR: "; read DEFAULT_MAC_ADDR
done
echo "DEFAULT_MAC_ADDR=$DEFAULT_MAC_ADDR" >> $FIL

while [ -z "$MASTER_SLEEP_TIME" ]; do
	echo -n "MASTER_SLEEP_TIME: [60] "; read MASTER_SLEEP_TIME; [ -z "$MASTER_SLEEP_TIME" ] && MASTER_SLEEP_TIME=60
done
echo "MASTER_SLEEP_TIME=$MASTER_SLEEP_TIME" >> $FIL

while [ -z "$SLAVE_SLEEP_TIME" ]; do
	echo -n "SLAVE_SLEEP_TIME: [60] "; read SLAVE_SLEEP_TIME; [ -z "$SLAVE_SLEEP_TIME" ] && SLAVE_SLEEP_TIME=60
done
echo "SLAVE_SLEEP_TIME=$SLAVE_SLEEP_TIME" >> $FIL

while [ -z "$SSH_PATIENCE" ]; do
	echo -n "SSH_PATIENCE: [40] "; read SSH_PATIENCE; [ -z "$SSH_PATIENCE" ] && SSH_PATIENCE=40
done
echo "SSH_PATIENCE=$SSH_PATIENCE" >> $FIL

while [ -z "$MONITOR_PATIENCE" ]; do
	echo -n "MONITOR_PATIENCE: [20] "; read MONITOR_PATIENCE; [ -z "$MONITOR_PATIENCE" ] && MONITOR_PATIENCE=20
done
echo "MONITOR_PATIENCE=$MONITOR_PATIENCE" >> $FIL

while [ -z "$MONITOR_CHK_THRESHOLD" ]; do
	echo -n "MONITOR_CHK_THRESHOLD: [330] "; read MONITOR_CHK_THRESHOLD; [ -z "$MONITOR_CHK_THRESHOLD" ] && MONITOR_CHK_THRESHOLD=300
done
echo "MONITOR_CHK_THRESHOLD=$MONITOR_CHK_THRESHOLD" >> $FIL

while [ -z "$MYSQL_KILL_WAIT" ]; do
	echo -n "MYSQL_KILL_WAIT: [60] "; read MYSQL_KILL_WAIT; [ -z "$MYSQL_KILL_WAIT" ] && MYSQL_KILL_WAIT=60
done
echo "MYSQL_KILL_WAIT=$MYSQL_KILL_WAIT" >> $FIL

while [ -z "$MYSQL_RESTART_WAIT" ]; do
	echo -n "MYSQL_RESTART_WAIT: [60] "; read MYSQL_RESTART_WAIT; [ -z "$MYSQL_RESTART_WAIT" ] && MYSQL_RESTART_WAIT=60
done
echo "MYSQL_RESTART_WAIT=$MYSQL_RESTART_WAIT" >> $FIL

while [ -z "$FPING_ATTEMPTS" ]; do
	echo -n "FPING_ATTEMPTS: [3] "; read FPING_ATTEMPTS; [ -z "$FPING_ATTEMPTS" ] && FPING_ATTEMPTS=3
done
echo "FPING_ATTEMPTS=$FPING_ATTEMPTS" >> $FIL

while [ -z "$SLAVE" ]; do
	echo -n "SLAVE: [msqyl-slave] "; read SLAVE; [ -z "$SLAVE" ] && SLAVE=mysql-slave
done
echo "SLAVE=$SLAVE" >> $FIL

while [ -z "$SIG_KILL_WAIT" ]; do
	echo -n "SIG_KILL_WAIT: [5] "; read SIG_KILL_WAIT; [ -z "$SIG_KILL_WAIT" ] && SIG_KILL_WAIT=5
done
echo "SIG_KILL_WAIT=$SIG_KILL_WAIT" >> $FIL

while [ -z "$DB_USER" ]; do
	echo -n "DB_USER: [root] "; read DB_USER; [ -z "$DB_USER" ] && DB_USER=root
done
echo "DB_USER=$DB_USER" >> $FIL

while [ -z "$DB_PASSWORD" ]; do
	echo -n "DB_PASSWORD: [rootpwd] "; read DB_PASSWORD; [ -z "$DB_PASSWORD" ] && export DB_PASSWORD=rootpwd
done
echo "DB_PASSWORD=$DB_PASSWORD" >> $FIL

echo "done"