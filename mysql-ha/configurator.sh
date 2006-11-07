#!/bin/bash
#
# configurator.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

#
# simple configuration parser, it basically reads the variable names from the
# configuration file, sources the file, and exports the variables
#
# configurator is the only thing that needs to be run in order to start
# the cluster (once it's properly installed and configured)
# it is this script that starts either master_routine.sh or slave_routine.sh
# depending on which node we are in


[ -n "$MYSQLHA_HOME" ] || export MYSQLHA_HOME="/usr/mysql-ha" #you can either set this here or in the environment
. $MYSQLHA_HOME/compat.sh

. $BASHRC

CONF_FILE=/etc/mysql-ha.conf

variables=$(grep '=' $CONF_FILE|awk -F= '{print $1}')
. $CONF_FILE
for variable in $variables; do
	eval "export $variable"
done

. $MYSQLHA_HOME/common.sh

#start mysqld if it's stopped
[ $($RC_SCRIPT status |grep -c stop) -eq 0 ] || $RC_SCRIPT start

[ -n "$N_MASTER" ] && NODEOK=0 && {
	ifconfig $CLUSTER_DEVICE |grep $CLUSTER_IP >/dev/null || { 
		currip=$(ifconfig $CLUSTER_DEVICE|grep inet | awk '{print $2}'|awk -F: '{print $2}')
		ifconfig $CLUSTER_DEVICE $CLUSTER_IP
		ifconfig $CLUSTER_DEVICE add $currip
	}
	. $MYSQLHA_HOME/master_routine.sh
}
[ -n "$N_SLAVE" ] && NODEOK=0 && . $MYSQLHA_HOME/slave_routine.sh
[ -z "$NODEOK" ] && {
	echo "i couldn't figure out if i'm master or slave, aborting">&2
	exit 1
}
