#!/bin/bash
#  
# common.sh
# general-purpose routines
#
# this file is part of the mysql-ha suite
# and is release under the GNU GPL (see the file COPYING for more info)
# Copyright 2002 Fernando Ipar - fipar@acm.org / fipar@users.sourceforge.net


##########################
# NOTIFICATION FUNCTIONS   #
##########################

#what means we have to send messages to the world. 
#i plan to have simple functions for e-mail, smbclient, etc
#this is just a primitive mechanism to report problems, 
#the ideal would be to write a function to send a notification to
#a monitoring system such as nagios, big brother, etc, or even
#snmp traps
NOTIFICATION_MEANS='send_stdout send_netbios'

#send notifications by e-mail/sms/smbclient/whatever
#right now i've only implemented a notification to stdout for debugging purposes
send_notification()
{
[ -z "$1" ] && echo "usage: send_notification '<message>'">&2 && exit 1
for notification_mean in $NOTIFICATION_MEANS; do
	eval "$notification_mean $*"
done
}

send_stdout()
{
echo $*
}

send_netbios()
{
destinations=''#include a space-separated list of netbios names here
for destination in $destinations; do
	echo $* | smbclient -M $destination
done
}

#writes application messages to syslog
#if the string warning, error or notifiy are found on the message, the
#message is also delivered through send_notification
log()
{
[ -z "$1" ] && echo "usage: log '<message>'">&2 && exit 1
logger -i -s $*
[ $(echo $1|egrep -c 'warning|error|notify') -gt 0 ] && {
	send_notification "$*"
}
return 0
}

#writes a message to stderr
writeErr()
{
echo $* >&2
}

############################


#dies with the specified message and exit code
die()
{
[ -z "$1" ] && echo "usage: die '<message>' <exit-code>"
writeErr "$1"
[ $(echo $-|grep -c i) -gt 0 ] && return $2
exit $2
}


#routine to obtain the name of the master node
set_master_node()
{
MASTER_NODE=$(cat /etc/my.cnf |grep master-host|awk -F= '{print $2}')
[ -n "$MASTER_NODE" ] && export MASTER_NODE || die "could not get master-host from /etc/my.cnf" 1
}

#prepare the environment for execution
#you should set these with proper values
#to facilitate automatic configuration of the 
#suite, in the future i will move all user-customizable
#parameters to a separate file
prepare_environment()
{
export CLUSTER_IP=10.0.0.100
export MYSQL_USER=replicator
export MYSQL_PASSWORD=replicatorpwd
export MYSQL_DATABASE=testdb
}

prepare_environment

[ -z "$state_defined" ] || unset state_defined

[ -n "$N_SLAVE" ] && {
	state_defined=0
	set_master_node
}

[ -n "$N_MASTER" ] && state_defined=1

[ -z "$state_defined" ] && die 'couldn't figure out if this is the slave or the master node' 1