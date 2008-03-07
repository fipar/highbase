#!/bin/bash
#
# configuration-menu.sh
# this file is part of the highbase suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info. 

#
# asks the user for the configuration keys one by one, providing 
# default values when applicable
#

clear

HIGHBASE_HOME="$(dirname "$0")"
export HIGHBASE_HOME
. $HIGHBASE_HOME/compat.sh

. $BASHRC

grep "$HIGHBASE_HOME/role.include" $BASHRC >/dev/null || {
	echo ". $HIGHBASE_HOME/role.include" >> $BASHRC
	echo "export HIGHBASE_HOME=$HIGHBASE_HOME" >> $BASHRC
	echo >> $BASHRC
	}

[ $1 == "master" ] && cp -f $HIGHBASE_HOME/master.include $HIGHBASE_HOME/role.include
[ $1 == "slave" ] && cp -f $HIGHBASE_HOME/slave.include $HIGHBASE_HOME/role.include

chgrp highbase /etc/highbase.conf 2>/dev/null
chmod 640 /etc/highbase.conf

