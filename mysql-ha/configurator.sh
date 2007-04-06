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

# store my pid. i should always get this as parameter
[ -n "$1" ] && echo $$ > $1

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

SUDO=$(cat $MYSQLHA_HOME/sudo_prefix)

AGENT_SOCK=/tmp/mysql-ha-ssh-agent.sock

[ -n "$(${SUDO}/sbin/fuser $AGENT_SOCK)" ] && {
	echo "killing old ssh-agent"
	${SUDO}/bin/kill $(${SUDO}/sbin/fuser $AGENT_SOCK 2>&1|awk -F: '{print $2}') 2>/dev/null
	for i in $(seq 10); do
		usleep 20
		echo -n "."
	done
	${SUDO}/bin/kill -9 $(${SUDO}/sbin/fuser $AGENT_SOCK 2>&1|awk -F: '{print $2}') 2>/dev/null
}

test -f $AGENT_SOCK && rm -f $AGENT_SOCK

[ -n "$1" ] && [ "$1" == "shutdown-master" ] && {
	echo "shutting down master"
	${SUDO}/sbin/ifconfig ${CLUSTER_DEVICE} $(${SUDO}/sbin/ifconfig ${CLUSTER_DEVICE}:0 | grep inet | awk '{print $2}' | awk -F: '{print $2}')
	exit
}

ssh-agent -a $AGENT_SOCK # TODO: we start the ssh-agent, but we don't stop it
export SSH_AUTH_SOCK=$AGENT_SOCK
ssh-add

#start mysqld if it's stopped
[ $($RC_SCRIPT status |grep -c stop) -eq 0 ] ||  {
	log "Starting mysqld (debug)"
	${SUDO}$RC_SCRIPT start
}

[ -n "$N_MASTER" ] && NODEOK=0 && {
	log "Configuring network interface (debug)"
	${SUDO}/sbin/ifconfig $CLUSTER_DEVICE |grep $CLUSTER_IP >/dev/null || { 
		currip=$(${SUDO}/sbin/ifconfig $CLUSTER_DEVICE|grep inet | awk '{print $2}'|awk -F: '{print $2}')
		${SUDO}/sbin/ifconfig $CLUSTER_DEVICE $CLUSTER_IP
		${SUDO}/sbin/ifconfig $CLUSTER_DEVICE add $currip
	}
	. $MYSQLHA_HOME/master_routine.sh
}
[ -n "$N_SLAVE" ] && NODEOK=0 && . $MYSQLHA_HOME/slave_routine.sh
[ -z "$NODEOK" ] && {
	echo "i couldn't figure out if i'm master or slave, aborting">&2
	[ -n "$1" ] && rm -f $1
	exit 1
}
