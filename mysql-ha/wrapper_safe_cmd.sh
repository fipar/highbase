#!/bin/bash
#
# wrapper_safe_cmd.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

###############################################
# this is a user wrapper for the safe_cmd script. 
# among other things, i translates the 143 exit code into a 0
# exit code, so we can use the wrapper in && and || expressions
###############################################


[ -z "$1" ] && echo "usage: wrapper_safe_cmd.sh <timeout (secs)> <cmdline> [arg1 arg2 arg3 ...]">&2 && exit 1
[ -z "$2" ] && echo "usage: wrapper_safe_cmd.sh <timeout (secs)> <cmdline> [arg1 arg2 arg3 ...]">&2 && exit 1
TIMEOUT=$1
CMDLINE=$2
shift 2
safe_cmd.sh $TIMEOUT $CMDLINE $*
retcod=$?
[ $retcod -eq 143 ] && exit 0 || exit $retcod