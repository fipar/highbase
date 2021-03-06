#!/bin/bash
#
# takeover.sh
# this file is part of the mysql-ha suite
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

DB_USER=root
DB_PASSWORD=rootpwd

. /usr/mysql-ha/common.sh


ATTEMPTS=3
#this line has two reasons: 
#1) it should be impossible but might just happen that we try and go for a takeover while the master has started to
#provide the service again (this SHOULD be IMPOSSIBLE since we forced a failover first, but if we put the words
#High Availability on this project's name, we might aswell expect unexpected things and be prepared
#2) a user with root privileges might accidentaly run this script, so we want to make sure that we really need
#to do a takeover

mysql.monitor --username=$MYSQL_USER --password=$MYSQL_PASSWORD --database=$MYSQL_DATABASE $MASTER_NODE && log "takeover attempt with master node up (error)" && exit 1

#stop replicating
echo "slave stop" | mysql -u${DB_USER} -p${DB_PASSWORD}


fping -c$ATTEMPTS $CLUSTER_IP && {
	log "takeover with master node still holding cluster ip, going to gratuitious ARP mode (error)"
	nohup fake $CLUSTER_IP &
} || {
	log "takeover with master node down, doing simple ifconfig"
	#start listening
	ifconfig $CLUSTER_DEVICE add $CLUSTER_IP
}

#just to be paranoid, this code should never run
[ $(ifconfig $CLUSTER_DEVICE|grep -c $CLUSTER_IP) -eq 0 ] && ifconfig $CLUSTER_DEVICE add $CLUSTER_IP && echo "manually added $CLUSTER_IP to $CLUSTER_DEVICE"

log "takeover complete (notify)"
exit 0
