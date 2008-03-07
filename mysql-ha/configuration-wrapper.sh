#!/bin/bash
#
# configuration-wrapper.sh
# this file is part of the highbase suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info. 

#
# provides a configuration tool according to the available resources
#

clear

# you can either set this here or in the environment
[ -n "$HIGHBASE_HOME" ] || export HIGHBASE_HOME="/usr/local/highbase"

# set your lang here on in the environment
# note that this is not LANG because we don't use real locales
[ -n "$lang" ] || export lang=en

# check for python and run the corresponding configurator (wxpython is verified from in there)
[ -n "$(type -a python)" -a -z "$($HIGHBASE_HOME/check-wxpython.py)" ] && {
	$HIGHBASE_HOME/configuration-wxpython.py
	$HIGHBASE_HOME/configuration-post.sh
	exit
}

# check for dialog backend and run the corresponding configurator
[ -n "$(type -a dialog)" ] && {
	$HIGHBASE_HOME/configuration-dialog.sh
	$HIGHBASE_HOME/configuration-post.sh
	exit
}

# run the original configurator
$HIGHBASE_HOME/configuration-menu.sh
$HIGHBASE_HOME/configuration-post.sh

