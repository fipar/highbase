#!/bin/bash
#
# configuration-wrapper.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info. 

#
# provides a configuration tool according to the available resources
#

clear

[ -n "$MYSQLHA_HOME" ] || export MYSQLHA_HOME="/usr/mysql-ha" #you can either set this here or in the environment

# set your lang here on in the environment
# note that this is not LANG because we don't use real locales
[ -n "$lang" ] || export lang=en

# check for python and run the corresponding configurator (wxpython is verified from in there)
[ -n "$(type -a python)" -a -z "$($MYSQLHA_HOME/check-wxpython.py)" ] && {
	$MYSQLHA_HOME/configuration-wxpython.py
	exit
}

# check for dialog backend and run the corresponding configurator
[ -n "$(type -a dialog)" ] && {
	$MYSQLHA_HOME/configuration-dialog.sh
	exit
}

# run the original configurator
$MYSQLHA_HOME/configuration-menu.sh
