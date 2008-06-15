#!/bin/bash
#
# wrapper_safe_cmd.sh
# this file is part of the highbase suite
# Copyright 2002 Fernando Ipar - fipar@seriema-systems.com / fipar@users.sourceforge.net

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


###############################################
# this is a user wrapper for the safe_cmd script. 
# among other things, it translates the 143 exit code into a 0
# exit code, so we can use the wrapper in && and || expressions
# (generally speaking, use it in as argument for test or eval)
###############################################


[ -z "$1" ] && echo "usage: wrapper_safe_cmd.sh <timeout (secs)> <cmdline> [arg1 arg2 arg3 ...]">&2 && exit 1
[ -z "$2" ] && echo "usage: wrapper_safe_cmd.sh <timeout (secs)> <cmdline> [arg1 arg2 arg3 ...]">&2 && exit 1
[ "$2" == "pwrap" ] && {
	safe_cmd.sh $*
	retcod=$?
} || {
	TIMEOUT=$1
	CMDLINE=$2
	shift 2
	safe_cmd.sh $TIMEOUT pwrap $CMDLINE $*
	retcod=$?
} 
[ $retcod -eq 143 ] && exit 0
[ $retcod -eq 137 ] && exit 1
exit $retcod

