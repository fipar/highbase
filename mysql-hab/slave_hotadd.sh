#!/bin/bash
#
# slave_hotadd.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

#
# when the master node goes down, the slave takes over the service (or
# at least it should, since this is the goal of the cluster ;). if you fix/replace
# your master and want to reintegrate it to your cluster, you must first
# run configuration-menu.sh to set it up as a slave, and then run this
# script to start the slave routine on the new slave node. 
#

[ -n "$MYSQLHA_HOME" ] || export MYSQLHA_HOME="/usr/mysql-ha" #you can either set this here or in the environment
. $MYSQLHA_HOME/common.sh

#start mysqld if it's stopped
[ $($RC_SCRIPT status |grep -c stop) -eq 0 ] || $RC_SCRIPT start

cat <<EOMSG
about to load data from master.
this might take a while and will lock your
tables for read on the master until finished. 

continue? (Y/n)
EOMSG
read option
[ "$option" == "n" ] && echo "ok, exiting, CLUSTER NOT RUNNING" && exit 1
echo "load data from master"  | mysql -u$DB_USER -p$DB_PASSWORD

[ -x /etc/init.d/mysql-had ] && /etc/init.d/mysql-had start || {
	echo "i couldn't find mysql-had on your init dir, starting with no log file">&2
	nohup $MYSQLHA_HOME/configurator.sh >/dev/null 2>&1
}