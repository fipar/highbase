#!/bin/bash
#  
# common.sh
# general-purpose routines
#
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

[ -z "$HIGHBASE_HOME" ] && {
	echo "HIGHBASE_HOME not set, aborting">&2
	exit 1
} 
. $HIGHBASE_HOME/compat.sh

##########################
# NOTIFICATION FUNCTIONS   #
##########################

#what means we have to send messages to the world. 
#i plan to have simple functions for e-mail, smbclient, etc
#this is just a primitive mechanism to report problems, 
#the ideal would be to write a function to send a notification to
#a monitoring system such as nagios, big brother, etc, or even
#snmp traps

#NOTIFICATION_MEANS='send_stdout send_netbios send_email'
NOTIFICATION_MEANS='send_stdout'

#send notifications by e-mail/sms/smbclient/whatever
#right now i've only implemented a notification to stdout for debugging purposes
send_notification() {
	[ -z "$1" ] && echo "usage: send_notification '<message>'">&2 && exit 1
for notification_mean in $NOTIFICATION_MEANS; do
		eval "$notification_mean '$*'"
	done
}

send_email() {
	HOST=`hostname`
	echo $* | $MAIL -s "highbase notice ($HOST)" $NOTIFY_EMAIL
}

send_stdout() {
	echo $*
}

send_netbios() {
	destinations='' #include a space-separated list of netbios names here
	for destination in $destinations; do
		echo $* | $SENDMAIL -M $destination
	done
}

#writes application messages to syslog
#if the string warning, error or notifiy are found on the message, the
#message is also delivered through send_notification
log() {
	[ -z "$1" ] && echo "usage: log '<message>'">&2 && exit 1
	logger -i -s -t highbase $*
	[ $(echo $1|egrep -c 'warning|error|notify') -gt 0 ] && {
		send_notification "$*"
	}
	return 0
}

#writes a message to stderr
writeErr() {
	echo $* >&2
}

############################


#dies with the specified message and exit code
die() {
	[ -z "$1" ] && echo "usage: die '<message>' <exit-code>"
	writeErr "$1"
	[ $(echo $-|grep -c i) -gt 0 ] && return $2
	exit $2
}


#############################


bcrun() {
        echo "scale=6; $*" | bc
}

# extracts a time value suitable for use with usleep
extractTime() {
        [ $NO_USLEEP -eq 0 ] && {
                echo $1 | grep ms >/dev/null && echo $((${1%ms*} * 1000)) && return
                echo $1 | grep us >/dev/null && echo ${1%us*} && return
                echo $(($1 * 1000000))
        } || {
                echo $1 | grep ms >/dev/null && echo $(bcrun "${1%ms*} / 1000") && return
                echo $1 | grep us >/dev/null && echo $(bcrun "${1%us*} / 1000000") && return
                echo $1 
        }
}



SUDO=$(cat $HIGHBASE_HOME/sudo_prefix)

#routine to obtain the name of the master node
set_master_node() {
	MASTER_NODE=$(cat /etc/my.cnf |grep master-host|awk -F= '{print $2}'|awk '{print $1}')
	[ -z "$MASTER_NODE" ] && {
		# MySQL 5 doesn't need master config in my.cnf if there's a master.info file in place, so we also
		# look there. This is very beta, we must verify the format of this file to make sure the master's name
		# is always on the same position ## TODO ##
		MASTER_NODE=$(${SUDO}$HIGHBASE_HOME/get_master.sh)
	} 
	[ -n "$MASTER_NODE" ] && export MASTER_NODE || die "could not get master-host from /etc/my.cnf" 1
	export MASTER_NODE
}


#prepare the environment for execution
#you should set these with proper values
#to facilitate automatic configuration of the 
#suite, in the future i will move all user-customizable
#parameters to a separate file
prepare_environment() {
	export SAFE_CMD_DONE=143 # exit code from SAFE_CMD that means it was killed by it's child
	[ -x /etc/init.d/mysqld ] && RC_SCRIPT=/etc/init.d/mysqld
	[ -x /etc/init.d/mysql ] && RC_SCRIPT=/etc/init.d/mysql
	[ -z "$RC_SCRIPT" ] && echo "($HOSTNAME) i couldn't figure out where your mysql rc script lives" && exit 1
	export RC_SCRIPT
}

prepare_environment

[ -z "$state_defined" ] || unset state_defined

[ -n "$N_SLAVE" ] && {
	state_defined=0
	set_master_node
}

[ -n "$N_MASTER" ] && state_defined=1

[ -z "$state_defined" ] && die 'couldnt figure out if this is the slave or the master node' 1

