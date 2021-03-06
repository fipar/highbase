#!/bin/bash
#
# configuration-menu.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info. 

#
# asks the user for the configuration keys one by one, providing 
# default values when applicable
#

clear

[ -n "$MYSQLHA_HOME" ] || export MYSQLHA_HOME="/usr/mysql-ha" #you can either set this here or in the environment
. $MYSQLHA_HOME/compat.sh

. $BASHRC


cat <<EOMSG



	configuration script for mysql-ha
	default values will be placed inside [] where available
	you must specify a value for every variable that doesn't 
	have a default
	
	
EOMSG

FIL=/etc/mysql-ha.conf

user=$USER
host=$HOSTNAME
datetime=$(date "+%m-%d-%Y %H:%M:%S")

cat <<EONOTICE>$FIL
#mysq-la configuration file
#this file was automatically generated by configuration-menu.sh for ${user}@{$host} at $datetime
#do not modify manually if you don't read the documentation first
#see man/info mysql-ha


EONOTICE

echo "CLUSTER_IP is the public IP that is shared between master and slave nodes, it is the unique service IP provided to the outside world"
while [ -z "$CLUSTER_IP" ]; do
	echo -n "CLUSTER_IP: "; read CLUSTER_IP
done
echo "CLUSTER_IP=$CLUSTER_IP" >>$FIL;echo

echo "CLUSTER_NETMASK is the network mask associated with the IP provided above"
while [ -z "$CLUSTER_NETMASK" ]; do
	echo -n "CLUSTER_NETMASK: "; read CLUSTER_NETMASK
done
echo "CLUSTER_NETMASK=$CLUSTER_NETMASK" >> $FIL;echo

echo "CLUSTER_BROADCAST is the broadcast address for the IP provided above"
while [ -z "$CLUSTER_BROADCAST" ]; do
	echo -n "CLUSTER_BROADCAST: "; read CLUSTER_BROADCAST
done
echo "CLUSTER_BROADCAST=$CLUSTER_BROADCAST" >> $FIL;echo

echo "CLUSTER_DEVICE is the network device to which we must attach the cluster IP"
while [ -z "$CLUSTER_DEVICE" ]; do
	echo -n "CLUSTER_DEVICE: [eth0] "; read CLUSTER_DEVICE; [ -z "$CLUSTER_DEVICE" ] && CLUSTER_DEVICE=eth0
done
echo "CLUSTER_DEVICE=$CLUSTER_DEVICE" >> $FIL;echo

echo "MYSQL_USER is the mysql database user used for service verification"
while [ -z "$MYSQL_USER" ]; do
	echo -n "MYSQL_USER: [replicator] "; read MYSQL_USER; [ -z "$MYSQL_USER" ] && MYSQL_USER=replicator
done
echo "MYSQL_USER=$MYSQL_USER" >> $FIL;echo

echo "MYSQL_PASSWORD is the password associated with the user provided above"
while [ -z "$MYSQL_PASSWORD" ]; do
	echo -n "MYSQL_PASSWORD: [replicatorpwd] "; read MYSQL_PASSWORD; [ -z "$MYSQL_PASSWORD" ] && MYSQL_PASSWORD=replicatorpwd
done
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> $FIL;echo

echo "MYSQL_DATABASE is the mysql database to verify"
while [ -z "$MYSQL_DATABASE" ]; do
	echo -n "MYSQL_DATABASE: [testdb] "; read MYSQL_DATABASE; [ -z "$MYSQL_DATABASE" ] && MYSQL_DATABASE=testdb
done
echo "MYSQL_DATABASE=$MYSQL_DATABASE" >> $FIL;echo

echo "ARP_DELAY goes straight to the .fakerc file, and it is the ammount of seconds that we wait between each gratuitious ARP packet"
while [ -z "$ARP_DELAY" ]; do
	echo -n "ARP_DELAY: [5] "; read ARP_DELAY; [ -z "$ARP_DELAY" ] && ARP_DELAY=5
done
echo "ARP_DELAY=$ARP_DELAY" >> $FIL;echo

#while [ -z "$DEFAULT_MAC_ADDR" ]; do
#	echo -n "DEFAULT_MAC_ADDR: "; read DEFAULT_MAC_ADDR
#done
#echo "DEFAULT_MAC_ADDR=$DEFAULT_MAC_ADDR" >> $FIL

echo "MASTER_SLEEP_TIME is the ammount of seconds the master routine sleeps between verifications of the slave node"
while [ -z "$MASTER_SLEEP_TIME" ]; do
	echo -n "MASTER_SLEEP_TIME: [60] "; read MASTER_SLEEP_TIME; [ -z "$MASTER_SLEEP_TIME" ] && MASTER_SLEEP_TIME=60
done
echo "MASTER_SLEEP_TIME=$MASTER_SLEEP_TIME" >> $FIL;echo

echo "SLAVE_SLEEP_TIME is the same but applied to the slave routine"
while [ -z "$SLAVE_SLEEP_TIME" ]; do
	echo -n "SLAVE_SLEEP_TIME: [60] "; read SLAVE_SLEEP_TIME; [ -z "$SLAVE_SLEEP_TIME" ] && SLAVE_SLEEP_TIME=60
done
echo "SLAVE_SLEEP_TIME=$SLAVE_SLEEP_TIME" >> $FIL;echo

echo "SSH_PATIENCE specifies the ammount of seconds we wait before we decide that an remote command cannot be executed due to timeout"
while [ -z "$SSH_PATIENCE" ]; do
	echo -n "SSH_PATIENCE: [20] "; read SSH_PATIENCE; [ -z "$SSH_PATIENCE" ] && SSH_PATIENCE=20
done
echo "SSH_PATIENCE=$SSH_PATIENCE" >> $FIL;echo

echo "MONITOR_PATIENCE is the ammount of seconds we wait before we decide the service verification has timed out"
while [ -z "$MONITOR_PATIENCE" ]; do
	echo -n "MONITOR_PATIENCE: [10] "; read MONITOR_PATIENCE; [ -z "$MONITOR_PATIENCE" ] && MONITOR_PATIENCE=10
done
echo "MONITOR_PATIENCE=$MONITOR_PATIENCE" >> $FIL;echo

echo "MONITOR_CHK_THRESHOLD is the ammount of seconds we sleep after we get a negative service verification, before performing a second one"
while [ -z "$MONITOR_CHK_THRESHOLD" ]; do
	echo -n "MONITOR_CHK_THRESHOLD: [20] "; read MONITOR_CHK_THRESHOLD; [ -z "$MONITOR_CHK_THRESHOLD" ] && MONITOR_CHK_THRESHOLD=20
done
echo "MONITOR_CHK_THRESHOLD=$MONITOR_CHK_THRESHOLD" >> $FIL;echo

echo "MYSQL_KILL_WAIT is the ammount of seconds we sleep after doing a remote mysql_kill, before performing a verification"
while [ -z "$MYSQL_KILL_WAIT" ]; do
	echo -n "MYSQL_KILL_WAIT: [5] "; read MYSQL_KILL_WAIT; [ -z "$MYSQL_KILL_WAIT" ] && MYSQL_KILL_WAIT=5
done
echo "MYSQL_KILL_WAIT=$MYSQL_KILL_WAIT" >> $FIL;echo

echo "MYSQL_RESTART_WAIT is the same as above, applied to a remote restart_mysql"
while [ -z "$MYSQL_RESTART_WAIT" ]; do
	echo -n "MYSQL_RESTART_WAIT: [5] "; read MYSQL_RESTART_WAIT; [ -z "$MYSQL_RESTART_WAIT" ] && MYSQL_RESTART_WAIT=5
done
echo "MYSQL_RESTART_WAIT=$MYSQL_RESTART_WAIT" >> $FIL;echo

echo "FPING_ATTEMPTS is the ammount of times fping tries to contact the remote host"
while [ -z "$FPING_ATTEMPTS" ]; do
	echo -n "FPING_ATTEMPTS: [3] "; read FPING_ATTEMPTS; [ -z "$FPING_ATTEMPTS" ] && FPING_ATTEMPTS=3
done
echo "FPING_ATTEMPTS=$FPING_ATTEMPTS" >> $FIL;echo

echo "SLAVE is the hostname/ip of the slave host"
while [ -z "$SLAVE" ]; do
	echo -n "SLAVE: [mysql-slave] "; read SLAVE; [ -z "$SLAVE" ] && SLAVE=mysql-slave
done
echo "SLAVE=$SLAVE" >> $FIL;echo

echo "SIG_KILL_WAIT, after performing a kill of every mysql process during failover, this is the ammount of seconds we wait before performing a kill -9"
while [ -z "$SIG_KILL_WAIT" ]; do
	echo -n "SIG_KILL_WAIT: [5] "; read SIG_KILL_WAIT; [ -z "$SIG_KILL_WAIT" ] && SIG_KILL_WAIT=5
done
echo "SIG_KILL_WAIT=$SIG_KILL_WAIT" >> $FIL;echo

echo "DB_USER specifies the mysql database user to be used when doing kills on the database"
while [ -z "$DB_USER" ]; do
	echo -n "DB_USER: [root] "; read DB_USER; [ -z "$DB_USER" ] && DB_USER=root
done
echo "DB_USER=$DB_USER" >> $FIL;echo

echo "DB_PASSWORD is the password for the user provided above"
while [ -z "$DB_PASSWORD" ]; do
	echo -n "DB_PASSWORD: [rootpwd] "; read DB_PASSWORD; [ -z "$DB_PASSWORD" ] && export DB_PASSWORD=rootpwd
done
echo "DB_PASSWORD=$DB_PASSWORD" >> $FIL;echo

[ -n "$N_SLAVE" -o -n "$N_MASTER" ] && {
	echo done
	exit 0
}
NODE=2
echo
while [ $NODE -ne 0 -a $NODE -ne 1 ] ; do
	echo "almost done, now enter 0 if this node is the master, or 1 if it is the slave: "; read NODE
	[ $NODE -eq 0 ] && cat $MYSQLHA_HOME/master.include >> $BASHRC
	[ $NODE -eq 1 ] && cat $MYSQLHA_HOME/slave.include >> $BASHRC
done

echo "done"
