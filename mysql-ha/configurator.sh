#!/bin/bash
#
# configurator.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

#
# simple configuration parser, it basically reads the variable names from the
# configuration file, sources the file, and exports the variables
# it should be run before anything on the cluster, in fact, configurator should
# run and then itself call either master_routine.sh or slave_routine.sh depending
# on which node we are in
#


. /etc/bashrc

CONF_FILE=/etc/mysql-ha.conf

variables=$(grep '=' $CONF_FILE|awk -F= '{print $1}')
. $CONF_FILE
for variable in $variables; do
	eval "export $variable"
done

. /usr/mysql-ha/common.sh


[ -n "$N_MASTER" ] && NODEOK=0 && /usr/mysql-ha/master_routine.sh
[ -n "$N_SLAVE" ] && NODEOK=0 && /usr/mysql-ha/slave_routine.sh
[ -z "$NODEOK" ] && {
	echo "i couldn't figure out if i'm master or slave, aborting">&2
	exit 1
}
