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


CONF_FILE=/etc/mysql-ha/mysql-ha.conf

variables=$(awk -F= '{print $1}' < $CONF_FILE)
. $CONF_FILE
for variable in $variables; do
	eval "export $variable"
done

#call proper routine with nohup here. this means common.sh needs serious revision!