#!/bin/bash
# pre-install.sh - this file is part of the highbase suite
#
# Fernando Ipar - fipar@acm.org / fipar@koaladev.com / fipar@users.sourceforge.net
# Copyright (C) 2002 Fernando Ipar.
# This file is released under the GNU GPL, see the file COPYING for more information
#


# This program is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any
# later version.
# This program is distributed in the hope that it will beuseful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307 USA

# check for things we need to run highbase


#check for mysql's init script
[ -x /etc/init.d/mysqld -o -x /etc/init.d/mysql ] || {
	echo "mysql is not properly installed or i can't execute the init script">&2
	exit 1
}

#check for mysql and mysqladmin
[ -n "$(type -a mysql 2>/dev/null)" -a -n "$(type -a mysqladmin 2>/dev/null)" ] || {
	echo "i need mysql's client programs (mysql, mysqladmin)">&2
	exit 1
}

#check for bash 2 or greater
[ $(bash -version |grep version|awk  '{print $4}'|awk -F. '{print $1}') -ge 2 ] || {
	echo "i need bash 2 or greater">&2
	exit 1
}

#check for syslog
[ -n "$(type -a logger 2>/dev/null)" ] || {
	echo "i need logger to write to syslog">&2
	exit 1
}

#check for perl
[ -n "$(type -a perl 2>/dev/null)" ] || {
	echo "i need perl">&2
	exit 1
}

#check for gcc and make
[ -n "$(type -a make 2>/dev/null)" -a -n "$(type -a gcc)" ] || {
	echo "i need make and gcc">&2
	exit 1
}

#check for ssh
[ -n "$(type -a ssh 2>/dev/null)" ] || {
	echo "i need ssh">&2
	exit 1
}

#check for usleep or bc
[ -n "$(type -a usleep 2>/dev/null)" -o -n "$(type -a bc 2>/dev/null)" ] || {
	echo "i need usleep or bc in order to give you proper sleep times">&2
	exit 1
}

#check for smbclient, only warn if not found
[ -n "$(type -a smbclient 2>/dev/null)" ] || {
	echo "i coudn't find smblient in your path, netbios notification will be unavailable">&2
	sleep 2
}

#check for sudo and configure accordingly
[ -n "$(type -a sudo 2>/dev/null)" ] && {
	echo "creating sudo based installation">&2
	useradd highbase 2>/dev/null #if this is the slave, this might be already created by the ssh setup 
	groupadd highbase 2>/dev/null #on red hat we have the private user group scheme, so this will fail
	usermod -G highbase highbase 2>/dev/null #again, we don't need this on red hat
	# populating path
	[ -x /etc/init.d/mysql ] && RC_SCRIPT=/etc/init.d/mysql || RC_SCRIPT=/etc/init.d/mysqld
	PS=/bin/ps
	# not the builtin, i _don't know_ how to use that with sudo
	KILL=/bin/kill
	SHUTDOWN=/sbin/shutdown
	FAKE=$HIGHBASE_HOME/extern/fake
	IFCONFIG=/sbin/ifconfig
	FUSER=/sbin/fuser
	FPING=$HIGHBASE_HOME/extern/fping
	echo "highbase	ALL=NOPASSWD:$FPING, $FUSER, $PS, $KILL, $RC_SCRIPT, $SHUTDOWN, $FAKE, $IFCONFIG" >> /etc/sudoers
	echo -n '/usr/bin/sudo ' > $HIGHBASE_HOME/sudo_prefix
	echo -n 'highbase' > $HIGHBASE_HOME/ssh_user
} || {
	echo "i couldn't find sudo in your path, creating sudo less installation">&2
	echo -n ''>$HIGHBASE_HOME/sudo_prefix
	echo -n 'root' > $HIGHBASE_HOME/ssh_user
}

exit 0
