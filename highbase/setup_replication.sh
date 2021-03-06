#!/bin/bash

# setup_replication.sh
# this file is part of the highbase suite

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

############ TESTING ONLY ###################
# Set these variables to proper values IF YOU'RE TESTING setup_replication.sh
# and not the whole highbase package 
[ -z "$REPLICATION_USER" ] && {
	export REPLICATION_USER="repl"
	export REPLICATION_PASSWORD="replpass"
}
############################################

CNF="/etc/my.cnf" #change this if the file has a different path on your system. notice that the file might not exist, so you might have to read
#the documentation for mysql to find out the proper pathname

cat <<EOMSG >&2
This script doesn't check the compatibility of MySQL's version between master and slave. 
Please refer to http://dev.mysql.com/doc/refman/5.0/en/replication-compatibility.html if you're unsure about your
current setup. 

EOMSG

[ -f /tmp/repl.data ] && . /tmp/repl.data || {
echo "please enter MySQL's root password for the master node">&2
read -s masterpw
echo "please enter MySQL's root password for the slave node">&2
read -s slavepw
echo "please enter the host name or ip address of the master node">&2
read masternode
echo "please enter the host name or ip address of the slave node">&2
read slavenode
} 
[ -n "$1" ] && [ "$1" == "master" ] && master="y"
[ -n "$1" ] && [ "$1" == "slave" ] && master="n"
[ -n "$1" ] && [ "$1" == "enable-slave" ] && enable_slave && exit 0

#enables replication, works for MySQL 4.x or greater
enable_slave()
{

# we need the slave's FQHN in order to grant the replication user the proper privilege

fqhn=

type gethostip >/dev/null 2>&1 && {
	fqhn=$(gethostip $slavenode|awk '{print $1}')
} || {
	fqhn=$(ping -c 1 $slavenode |grep PING | awk '{print $2}')
}

cat <<EOSCR |mysql -uroot -p$masterpw -vv
GRANT REPLICATION SLAVE ON *.* to $REPLICATION_USER@'$fqhn' identified by "$REPLICATION_PASSWORD";
FLUSH PRIVILEGES;
RESET MASTER;
EOSCR

echo "Please enter the datadir for the slave node ([/var/lib/mysql])">&2
read slavedatadir
[ -z "$slavedatadir" ] && slavedatadir=/var/lib/mysql
echo "You might be asked for the slave's node root password">&2
ssh root@$slavenode "service mysqld stop; cd $slavedatadir; rm -f master.info; tar xjvf /tmp/mysql-snapshot.tar.bz2; rm -f /tmp/mysql-snapshot.tar.bz2; service mysqld start; echo 'STOP SLAVE;RESET SLAVE;START SLAVE'| mysql -uroot -p$slavepw -vv"
rm -f /tmp/repl.data
echo "replication should now be ready and running">&2
}

## END enable_slave

get_datadir()
{
[ -f $CNF ] && {
	result=$(grep datadir $CNF|awk -F= '{print $2}')
	[ -n "$result" ] && echo $result && return
}
echo "Please enter the path for the master's node datadir (i.e., /var/lib/mysql)">&2
read result
echo $result
}

## end get_datadir

create_snapshot()
{
DATADIR=$(get_datadir)
pushd $DATADIR
cat <<EOSCR | mysql -uroot -p$masterpw -vv
FLUSH TABLES WITH READ LOCK;
\! tar cjvf /tmp/mysql-snapshot.tar.bz2 . --exclude=mysql --exclude=mysql-snapshot.tar.bz2
UNLOCK TABLES;
EOSCR
popd
echo "I now need the root password for the slave node">&2


scp -C /tmp/mysql-snapshot.tar.bz2 root@$1:/tmp
rm -f /tmp/mysql-snapshot.tar.bz2
}

## end create_snapshot

## BEGIN main

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
	# begin configuring a master node
	[ -f $CNF ] && {
	grep log-bin $CNF > /dev/null || {
		sed 's/\[mysqld\]/\[mysqld\]\n#modified by setup_replication.sh (highbase)\nlog-bin\nserver-id=1\n/g' < $CNF > $$ && mv -f $$ $CNF
	}
	} || {
		cat <<EOF >$CNF
# my.cnf file generated by setup_replication.sh (highbase)
[mysqld]
log-bin
server-id=1

EOF
	}
	create_snapshot $slavenode
	echo "I can set up replication on the slave through ssh, would you like to do this now? (y/n)">&2
	read setup_slave
	[ "$setup_slave" == "y" ] && {
		echo "masterpw=$masterpw" > /tmp/repl.data
		echo "masternode=$masternode" >> /tmp/repl.data
		echo "slavepw=$slavepw" >> /tmp/repl.data
		echo "slavenode=$slavenode" >> /tmp/repl.data
		echo "REPLICATION_USER=$REPLICATION_USER" >> /tmp/repl.data
		echo "REPLICATION_PASSWORD=$REPLICATION_PASSWORD" >> /tmp/repl.data
		
		dbs=$(mysql -B -uroot -p$masterpw -e 'show databases'|egrep -v '^Database$|^information_schema$|^mysql$')
		echo > /tmp/replicate.do.db
		for db in $dbs; do
			echo "replicate-do-db=$db ### line auto generated by setup_replication.sh (highbase) " >> /tmp/replicate.do.db
		done
		cat /tmp/replicate.do.db
		scp $0 /tmp/repl.data /tmp/replicate.do.db root@$slavenode:/tmp/
		rm -f /tmp/repl.data /tmp/replicate.do.db
		ssh -t root@$slavenode "export TERM=linux;/tmp/setup_replication.sh slave; rm -f /tmp/setup_replication.sh"
	}
	echo "If replication is already set up on the slave, you can enable it now. Otherwise, rerun this script passing enable-slave as parameter. Enable now? (y/n)">&2
	read enable_slave
	[ "$enable_slave" == "y" ] && enable_slave
} || {
	# begin configuring a slave node
	[ -f $CNF ] && {
	grep log-bin $CNF > /dev/null || {
		master_info="master-host=$masternode ### IP or host name for the master node ###\n"
		user_info="master-user=${REPLICATION_USER}\nmaster-password=${REPLICATION_PASSWORD}\nmaster-port=3306\n"
		cat /tmp/replicate.do.db | tr -t '\n' '|' | sed 's/|/\\n/g' > $$ && mv -f $$ /tmp/replicate.do.db
		db_info=$(cat /tmp/replicate.do.db)
		# db_info="replicate-do-db= ### name of the database to replicate, create as many of these lines as you need ###\n"
		sed "s/\[mysqld\]/\[mysqld\]\n#modified by setup_replication.sh (highbase)\nlog-bin\nserver-id=2\n$user_info$master_info$db_info/g" < $CNF > $$ && mv -f $$ $CNF
	} ## what this means is that if log-bin is not enabled, we're not setting up replication properly. we need another code body here. 
	} || {
		cat<<EOF >$CNF
# my.cnf file generated by setup_replication.sh (highbase)
[mysqld]
log-bin
master-host=$masternode ### IP or host name for the master node ###
master-user=$REPLICATION_USER
master-password=$REPLICATION_PASSWORD 
master-port=3306
server-id=2

EOF
cat /tmp/replicate.do.db >> $CNF
	}
rm -f /tmp/replicate.do.db
echo "I'm opening $CNF now, and you will have to enter proper values for the fields with comments (enter to continue)">&2
read
vi $CNF
}
