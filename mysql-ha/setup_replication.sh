#!/bin/bash

# setup_replication.sh
# this file is part of the mysql-ha suite

#Copyright (C) 2002 Fernando Ipar.
#This file is released under the GNU GPL, see the file COPYING for more information

#This program is free software; you can redistribute it
#and/or modify it under the terms of the GNU General Public
#License as published by the Free Software Foundation;
#either version 2 of the License, or (at your option) any
#later version.
#This program is distributed in the hope that it will beuseful, but WITHOUT ANY WARRANTY; without even the implied
#warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#PURPOSE.  See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public
#License along with this program; if not, write to the Free
#Software Foundation, Inc., 59 Temple Place, Suite 330,
#Boston, MA 02111-1307 USA

#this script attempts to set up replication for two mysql servers

CNF="/etc/my.cnf" #change this if the file has a different path on your system. notice that the file might not exist, so you might have to read
#the documentation for mysql to find out the proper pathname

[ -n "$1" ] && [ "$1" == "master" ] && master="y"
[ -n "$1" ] && [ "$1" == "slave" ] && master="n"

echo "I'm going to try to set up mysql to replicate, you'll need to answer a few questions" >&2
[ -f $CNF ] || {
	echo "I can't find $CNF, this is normal if you haven't modified mysql's configuration. However, my.cnf might be located on a different directory in your system. If this is the case, enter it's full pathname below, otherwise, just press enter">&2
	read myloc
	[ -z "$myloc" ] || CNF=$myloc
}
[ -z "$master" ] && {
	echo "Is this the master node? (y/n)">&2
	read master
}

[ $master == "y" ] && {
	[ -f $CNF ] && {
	grep log-bin $CNF > /dev/null || {
		sed 's/\[mysqld\]/\[mysqld\]\n#modified by setup_replication.sh (mysql-ha)\nlog-bin\nserver-id=1\n/g' < $CNF > $$ && mv -f $$ $CNF
	}
	} || {
		cat <<EOF>$CNF
# my.cnf file generated by setup_replication.sh (mysql-ha)
[mysqld]
log-bin
server-id=1

EOF
	}
	echo "I can set up replication on the slave through ssh, would you like to do this now? (y/n)">&2
	read setup_slave
	[ "$setup_slave" == "y" ] && {
		echo "Enter the IP or host name for the slave: ">&2
		read slave
		scp  $0 root@${slave}:/tmp/
		ssh -t root@$slave "export TERM=linux;/tmp/setup_replication.sh slave"
	}
} || {
	[ -f $CNF ] && {
	grep log-bin $CNF > /dev/null || {
		master_info="master-host= ### IP or host name for the master node ###\nmaster-user=$MYSQL_USER\nmaster-password=$MYSQL_PASSWORD\nmaster-port=3302\n"
		db_info="replicate-do-db= ### name of the database to replicate, create as many of these lines as you need ###\n"
		sed "s/\[mysqld\]/\[mysqld\]\n#modified by setup_replication.sh (mysql-ha)\nlog-bin\nserver-id=2\n$master_info$db_info/g" < $CNF > $$ && mv -f $$ $CNF
	}
	} || {
		cat<<EOF>$CNF
# my.cnf file generated y setup_replication.sh (mysql-ha)
[mysqld]
log-bin
master-host= ### IP or host name for the master node ###
master-user= $MYSQL_USER
master-password= $MYSQL_PASSWORD 
master-port=3306
server-id=2

replicate-do-db= ### name of the database to replicate, create as many of these lines as you need ###
EOF
	}
echo "I'm opening $CNF now, and you will have to enter proper values for the fields with comments (enter to continue)">&2
read
vi $CNF
}