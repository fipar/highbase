#!/bin/bash

# install.sh
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

#
# GLOBAL VARIABLES
# here's what you should try modifying if this installation doesn't work
# for your system. 


RC_DIR=/etc/init.d

[ -n "$MYSQLHA_HOME" ] || export MYSQLHA_HOME="/usr/mysql-ha" #you can either set this here or in the environment

##
## END of global variables, you shouldn't need to modify anything below this
##

. $MYSQLHA_HOME/compat.sh

[ -d $RC_DIR ] || {
	#see if we're in an older version of redhat
	[ -d /etc/rc.d/init.d ] && ln -s /etc/rc.d/init.d $RC_DIR || {
		echo "i can't find $RC_DIR or a similar directory, please set the variable manually on $0">&2
		exit 1
	}
}

#
# installation script
#

[ $UID -eq 0 ] || {
	echo "must run as root">&2
	exit 1
}

#first see if we have everything we need
$MYSQLHA_HOME/pre-install.sh || exit 1

#now build aux packages and create config files
cd $MYSQLHA_HOME/extern/fping-2.2b2/
./configure && make && make check && make install && make clean || {
	echo "couldnt build fping">&2
	exit 1
}
cd ..
tar xzvf fake*gz && rm -f fake*gz
cd fake*
make patch && make && make install || {
	echo "couldnt build fake">&2
	exit 1
}

cd ..
[ -z $PATH ] && echo "PATH not set">&2 && exit 1
BINDIR=$(echo $PATH|awk -F: '{print $1}')
cp mysql.monitor $BINDIR

cd ..
echo 'almost done, now some interactive scripts...'>&2
./configuration-menu.sh 
./setup_fake.sh
[ -d $RC_DIR ] && {
	cp -v rc-script $RC_DIR/mysql-had
	chmod a+x $RC_DIR/mysql-had
	pushd $RC_DIR
	chkconfig --level 345 mysql-had on ##############################33
	popd
} || {
	echo "i couldn't find $RC_DIR, you should manually copy rc-script as mysql-had in your systems rc dir" >&2
}

cat <<EOMSG>&2
if you have ssh properly configured for passwordless login from
master to slave and the other way around, type c to continue, 
otherwise just type enter and i'll try to set it up for you
(you might be asked the root password for the slave/master nodes)
EOMSG
read option
[ "$option" = "c" ] || {
	echo "enter the name/ip for the other node (i.e., if this is the master, enter the slave's name/ip">&2
	read OTHERBOX
	echo "when asked for a file, use the provided default, when asked for a passphrase, type enter">&2
	ssh-keygen -t dsa
	scp .ssh/id_dsa.pub $OTHERBOX:/root/id_peer
	ssh $OTHERBOX "cat /root/id_peer >> /root/.ssh/authorized_keys2"
	ssh $OTHERBOX "ssh-keygen -t dsa"
	scp $OTHERBOX:/root/.ssh/id_dsa.pub /root/id_peer
	cat id_peer >> /root/.ssh/authorized_keys2
	chmod -R 700 /root/.ssh/
	ssh $OTHERBOX "chmod -R 700 /root/.ssh/"
	echo "it should be done now, try logging in from one machine into the other, if you've never done this">&2
	echo "you'll be asked to save your peer's public key, say yes">&2
}


less <<EOMSG>&2
now you will see instructions on setting up replication in mysql. 
we haven't automated this yet. 
type q to exit

PLEASE, check out mysql's official site for more accurate information, 
this section is intended only as a bref summary that might get you
started if everything's fine with your installation. if you can't get
mysql to replicate with the instructions provided here, please
go to the official site. 

the specific url for documentation on replication is: 
http://www.mysql.com/doc/R/e/Replication.html


on the master, you should have a /etc/my.cnf that
looks something like this:  (things important for
replication are marked with hash marks

==== BEGIN EXAMPLE /etc/my.cnf FOR MASTER NODE ========
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-bin ######
server-id=1 ######

[mysql.server]
user=mysql
basedir=/var/lib

[safe_mysqld]
err-log=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
==== END EXAMPLE /etc/my.cnf FOR MASTER NODE ========



==== BEGIN EXAMPLE /etc/my.cnf FOR SLAVE NODE ========
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-bin #### this prepares the slave to become a master in the event of a failover

master-host=eliza ######
master-user=repl ######
master-password=replicate ######
master-port=3306 ######
server-id=2 ######

replicate-do-db=dbname1 ###### put the name of the databases you want to 
replicate-do-db=dbname2 ###### replicate here


[mysql.server]
user=mysql
basedir=/var/lib

[safe_mysqld]
err-log=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
==== END EXAMPLE /etc/my.cnf FOR SLAVE NODE ========

once you have these files, you should stop the
server on both master and slave nodes, and make
a tar.gz (or whatever package you might wanna do)
of the databases you want to replicate. 
unpack this on the slave, so you start from 
the same point of both servers. 
now start both servers and you should be
going. 

to check if everything's fine, in the
slave, log in as root(mysql's root) and 
do a SHOW SLAVE STATUS, the Column Running should
have the value Yes. if you have a No, you have
a problem. 
DON'T WORRY, replication problems are usually small things
that i haven't taken into consideration yet on this
document, but are very well documented on the mysql
manual, please check it if you have any problem. 

EOMSG


cat <<EOMSG>&2
you should reload /etc/bashrc (or the equivalent for your system, such as 
/etc/bash.bashrc for debian) for some changes to take effect. 
(you MUST do this before starting the cluster) 
type 'n' to reload it now

EOMSG
read reply
[ "$reply" = "n" ] && . $BASHRC


cat <<EOMSG>&2
now you can run ./configurator.sh, interactively, to test it, 
or nohup $MYSQLHA_HOME/configurator.sh

please report any bugs to the mysql-ha-devel list (see 
our site at http://sourceforge.net/projects/mysql-ha for
info on this) or otherwise to fipar@users.sourceforge.net

have fun!

EOMSG

