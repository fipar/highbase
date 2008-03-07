#!/bin/bash
# safe_cmd.sh
# this file is part of the highbase suite
# Copyright 2002 Fernando Ipar - fipar@acm.org / fipar@users.sourceforge.net

# This program is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307 USA

######################################
# it runs shell commands with a 'timeout' given
# by the user. 
######################################


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

. $HIGHBASE_HOME/common.sh

$SLEEP $(extractTime $TIMEOUT)

check_pid_name $COMMAND $childpid && { 
	kill $childpid
	$SLEEP $(extractTime ${RANDOM}00) #give it a chance to exit gracefully
	check_pid_name $COMMAND $childpid && kill -9 $childpid && log "had to kill -9 $COMMAND with $childpid" || log "had to kill $COMMAND with $childpid"
	exit 1
}
