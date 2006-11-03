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


. $MYSQLHA_HOME/compat.sh

. $BASHRC

grep "$MYSQLHA_HOME/role.include" $BASHRC >/dev/null || {
	echo ". $MYSQLHA_HOME/role.include" >> $BASHRC
	echo "export MYSQLHA_HOME=$MYSQLHA_HOME" >> $BASHRC
	echo >> $BASHRC
	}

[ $1 == "master" ] && cp -f $MYSQLHA_HOME/master.include $MYSQLHA_HOME/role.include
[ $1 == "slave" ] && cp -f $MYSQLHA_HOME/slave.include $MYSQLHA_HOME/role.include


