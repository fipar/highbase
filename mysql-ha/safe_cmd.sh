#!/bin/bash
# safe_cmd.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

######################################
# it runs shell commands with a 'timeout' given
# by the user. 
######################################

. /usr/mysql-ha/common.sh

[ $# -lt 2 ] && {
	echo "usage: safe_cmd.sh <timeout (secs)> <command> [cmd arg1 arg2 arg3 ... ]">&2
	exit 1
}

[ -d /proc ] || {
	echo "fatal error: this script needs the /proc filesystem to work">&2
	log "[ -d /proc ] failed (error)"
	exit 1
}


#checks to see if a given pid belongs to
#the process i spawned
check_pid_name ()
{
    name=$1;
    pid=$2;
    [ -n "$name" ] && [ -n "$pid" ] || {
	echo "usage: check_pid_name <cmdline> <pid>">&2
        return 1
    };
    cnt=$(grep -c $name /proc/$pid/cmdline 2>/dev/null);
    [ -z "$cnt" ] && return 1;
    [ $cnt -gt 0 ] && return 0 || return 1
}

TIMEOUT=$1
COMMAND=$2

shift 2 
$COMMAND $* &
childpid=$!

sleep $TIMEOUT

check_pid_name $COMMAND $childpid && { 
	kill $childpid
	usleep ${RANDOM}00 #give it a chance to exit gracefully
	check_pid_name $COMMAND $childpid && kill -9 $childpid && log "had to kill -9 $COMMAND with $childpid" || log "had to kill $COMMAND with $childpid"
	exit 1
}
