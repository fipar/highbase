#!/bin/bash
# pre-install.sh - this file is part of the mysql-ha suite
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

# check for things we need to run mysql-ha



#check for mysql's init script
[ -x /etc/init.d/mysqld -o -x /etc/init.d/mysql ] || {
	echo "mysql is not properly installed or i can't execute the init script">&2
	exit 1
}

#check for mysql and mysqladmin
[ -n "$(type -a mysql)" -a -n "$(type -a mysqladmin)" ] || {
	echo "i need mysql's client programs (mysql, mysqladmin)">&2
	exit 1
}

#check for bash 2 or greater
[ $(bash -version |grep version|awk  '{print $4}'|awk -F. '{print $1}') -ge 2 ] || {
	echo "i need bash 2 or greater">&2
	exit 1
}

#check for syslog
[ -n "$(type -a logger)" ] || {
	echo "i need logger to write to syslog">&2
	exit 1
}

#check for perl
[ -n "$(type -a perl)" ] || {
	echo "i need perl">&2
	exit 1
}

#check for gcc and make
[ -n "$(type -a make)" -a -n "$(type -a gcc)" ] || {
	echo "i need make and gcc">&2
	exit 1
}

#check for ssh
[ -n "$(type -a ssh)" ] || {
	echo "i need ssh">&2
	exit 1
}

#check for smbclient, only warn if not found
[ -n "$(type -a smbclient)" ] || {
	echo "i coudn't find smblient in your path, netbios notification will be unavailable">&2
}


exit 0