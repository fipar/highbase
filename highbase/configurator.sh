#!/bin/bash
#
# configurator.sh
# this file is part of the highbase suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

#
# simple configuration parser, it basically reads the variable names from the
# configuration file, sources the file, and exports the variables
#
# configurator is the only thing that needs to be run in order to start
# the cluster (once it's properly installed and configured)
# it is this script that starts either master_routine.sh or slave_routine.sh
# depending on which node we are in

# get my options

pidf=
operation=
encrypted=0

CONF_FILE=/etc/highbase.conf

variables=$(grep '=' $CONF_FILE|awk -F= '{print $1}')
. $CONF_FILE
for variable in $variables; do
	eval "export $variable"
done


while getopts "p:o:e:" oname; do
	case $oname in
		p ) pidf=$OPTARG;;
		o ) operation=$OPTARG;;
		e ) encrypted=$OPTARG;;
	esac
done

. $(dirname "$0")/role.include

SUDO=$(cat $(dirname "$0")/sudo_prefix)

AGENT_SOCK=/tmp/highbase-ssh-agent.sock

# start the ssh agent
start_agent() {
	# TODO: we start the ssh-agent, but we don't stop it here
	ssh-agent -a $AGENT_SOCK
	export SSH_AUTH_SOCK=$AGENT_SOCK
	ssh-add
}


# stop the ssh agent if it's running
stop_agent() {
	[ -n "$(${SUDO}${FUSER} $AGENT_SOCK)" ] && {
		echo "killing old ssh-agent"
		${SUDO}${KILL} $(${SUDO}${FUSER} $AGENT_SOCK 2>&1|awk -F: '{print $2}') 2>/dev/null
		for i in $(seq 10); do
			$SLEEP $(extractTime 20ms)
			echo -n "."
		done
		${SUDO}${KILL} -9 $(${SUDO}${FUSER} $AGENT_SOCK 2>&1|awk -F: '{print $2}') 2>/dev/null
	}

	rm -f $AGENT_SOCK
}


. $HIGHBASE_HOME/compat.sh
. $BASHRC

. $HIGHBASE_HOME/common.sh

[ -n "$operation" ] && [ "$operation" == "shutdown-master" ] && {
	[ -n "$N_MASTER" ] || exit
	echo "shutting down master"
	${SUDO}${IFCONFIG} ${CLUSTER_DEVICE} $(${SUDO}${IFCONFIG} ${CLUSTER_DEVICE}:0 | grep inet | awk '{print $2}' | awk -F: '{print $2}')
	exit
}


[ -n "$operation" ] && [ "$operation" == "start-agent" ] && {
	# if we're starting the agent, then this is all we need to run 
	stop_agent
	start_agent
	exit
} 

# if the dsa key is encrypted, we don't need to start the agent, since it's already started through
# a previous invocation of configurator with the -o start-agent option 
[ $encrypted -eq 0 ] && start_agent

# store my pid. i should always get this as parameter
[ -n "$pidf" ] && echo $$ > $pidf

#start mysqld if it's stopped
[ $(${SUDO}$RC_SCRIPT status |grep -c stop) -eq 0 ] ||  {
	log "Starting mysqld (debug)"
	${SUDO}$RC_SCRIPT start
}


[ -n "$N_MASTER" ] && NODEOK=0 && {
	log "Configuring network interface (debug)"
	${SUDO}${IFCONFIG} $CLUSTER_DEVICE |grep $CLUSTER_IP >/dev/null || { 
		currip=$(${SUDO}${IFCONFIG} $CLUSTER_DEVICE|grep inet | awk '{print $2}'|awk -F: '{print $2}')
		${SUDO}${IFCONFIG} $CLUSTER_DEVICE $CLUSTER_IP
		${SUDO}${IFCONFIG} $CLUSTER_DEVICE add $currip
	}
	. $HIGHBASE_HOME/master_routine.sh
}
[ -n "$N_SLAVE" ] && NODEOK=0 && . $HIGHBASE_HOME/slave_routine.sh
[ -z "$NODEOK" ] && {
	echo "i couldn't figure out if i'm master or slave, aborting" >&2
	[ -n "$1" ] && rm -f $1
	exit 1
}

