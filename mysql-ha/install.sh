#!/bin/bash

# install.sh
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

#
# GLOBAL VARIABLES
# here's what you should try modifying if this installation doesn't work
# for your system. 


RC_DIR=/etc/init.d

# you can either set this here or in the environment
[ -n "$HIGHBASE_HOME" ] || export HIGHBASE_HOME="/usr/local/highbase"

##
## END of global variables, you shouldn't need to modify anything below this
##

. $HIGHBASE_HOME/compat.sh

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
$HIGHBASE_HOME/pre-install.sh || exit 1

SSH_USER=$(cat $HIGHBASE_HOME/ssh_user)
HOME=/root
[ "$SSH_USER" == "highbase" ] && HOME=/home/highbase

#now build aux packages and create config files
cd $HIGHBASE_HOME/extern/
tar xf fping-2.2b2.tar.gz
cd fping-2.2b2/
./configure && make && make check && make install && make clean || 
	echo "couldnt build fping">&2
	exit 1
}
# Install fping into the extern directory
cp fping ../ -v
rm fping-2.2b2 -rf
cd $HIGHBASE_HOME/extern
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
sleep 1
./configuration-wrapper.sh 
./setup_fake.sh
[ -d $RC_DIR ] && {
	cp -v rc-script $RC_DIR/highbased
	chmod a+x $RC_DIR/highbased
	pushd $RC_DIR
	$CHK_CONFIG
	popd
} || {
	echo "i couldn't find $RC_DIR, you should manually copy rc-script as highbased in your systems rc dir" >&2
}

cat <<EOMSG >&2

highbase needs passwordless ssh properly configured for the root
or highbase user from master to slave and the other way around. 
If you want me to try and set it up for you type 'y' (you will
be asked the root password for the slave/master nodes). 

Otherwise just type enter. 

/-----------------------------------------------------------\

  SECURITY WARNING
 
  highbase uses passwordless ssh, by authenticating using
  private/public key, and by storing the private key with
  an empty passphrase. this means that anyone with read
  access to the private key file can then connect to the
  other server (master or slave) with the cluster user. 
  
  SUGGESTIONS
  - set up the private key file with 700 permissions (ssh
  should refuse to run otherwise, but still, I haven't
  tried this on all distributions)
  - create a dedicated account for highbase, and give it
  only the necessary privileges (the ability to run, 
  through sudo, the mysql_kill/mysql_restart/failover
  scripts)
  - grant access to the private key from the specific
  host where it should be used (master or slave). you
  can do this by changing the line in authorized_keys2, 
  including the from="<host>" string before ssh-dsa

\-------------------------------------------------------------/
EOMSG
read option
[ "$option" = "y" -o "$option" == "Y" ] && {

	echo "enter the name/ip for the other node (i.e., if this is the master, enter the slave's name/ip">&2
	read OTHERBOX
	cat <<EOMSG >&2
when asked for a file, used the provided default. 
when asked for a passphrase: 
- type <enter> if you don't want to use the ssh-agent (anyone will be able to ssh between both nodes as root with
no password, PROVIDED THEY'RE ALREADY ROOT ON ONE NODE)
- enter a passphrase if you want to use the ssh-agent (you'll need to enter this passphrase on each node every time the cluster
starts)
EOMSG
	su - $SSH_USER -c "ssh-keygen -t dsa"
	# test or create environment in peer
	cat << EOSCR > prepareEnvironment.tmp.sh
#!/bin/bash
useradd highbase
groupadd highbase 2>/dev/null
usermod -G highbase highbase 2>/dev/null
rm -f /tmp/prepareEnvironment.tmp.sh
EOSCR
	chmod 700 prepareEnvironment.tmp.sh
	scp prepareEnvironment.tmp.sh root@$OTHERBOX:/tmp
	ssh root@$OTHERBOX "/tmp/prepareEnvironment.tmp.sh"
	scp $HOME/.ssh/id_dsa.pub $OTHERBOX:$HOME/id_peer
	ssh root@$OTHERBOX "mkdir $HOME/.ssh/ 2>/dev/null; cat $HOME/id_peer >> $HOME/.ssh/authorized_keys2; chown -R $SSH_USER.$SSH_USER $HOME/.ssh; chmod -R 700 $HOME/.ssh"
	ssh root@$OTHERBOX "su - $SSH_USER -c 'ssh-keygen -t dsa'"
	scp root@$OTHERBOX:$HOME/.ssh/id_dsa.pub $HOME/id_peer
	cat $HOME/id_peer >> $HOME/.ssh/authorized_keys2
	chown -R $SSH_USER.$SSH_USER $HOME/.ssh
	chmod -R 700 $HOME/.ssh/
	ssh root@$OTHERBOX "chmod -R 700 $HOME/.ssh/"
	echo "it should be done now, try logging in from one machine into the other, if you've never done this">&2
	echo "you'll be asked to save your peer's public key, say yes">&2
}

echo "automatic setup of replication in mysql is still under heavy testing, and working only for mysql versions 4.X or greater. do you want to try it? (y/n)">&2
read autosetup
[ "$autosetup" == "y" ] && "./setup_replication.sh" || {

less <<EOMSG >&2
now you will see instructions on setting up replication in mysql. 

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
}

cat <<EOMSG >&2
you should reload /etc/bashrc (or the equivalent for your system, such as 
/etc/bash.bashrc for debian) for some changes to take effect. 
(you MUST do this before starting the cluster) 
type 'n' to reload it now

EOMSG
read reply
[ "$reply" = "n" ] && . $BASHRC


cat <<EOMSG >&2
now you can run ./configurator.sh, interactively, to test it, 
or nohup $HIGHBASE_HOME/configurator.sh 
you can also use the rc script, if it was properly installed for your system

please report any bugs to the highbase-devel list (see 
our site at http://highbase.sf.net for info on this) 
or otherwise to fipar@users.sourceforge.net

have fun!

EOMSG

