#!/bin/bash
#
# mysql_kill.sh
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

HIGHBASE_HOME="$(dirname "$0")"
export HIGHBASE_HOME
. $HIGHBASE_HOME/common.sh

# kill (MySQL internal KILL SQL command, hence the name of this script) every mysql process
#except for the replication thread (PID=1)

for pid in $(mysqladmin -u"${DB_USER}" -p"${DB_PASSWORD}" processlist|grep -v '^| Id'|awk -F\| '{print $2}'|awk '{print $1}'|grep -v ^$); do
	[ $pid -ne 1 ] && mysqladmin -u"${DB_USER}" -p"${DB_PASSWORD}" kill $pid
done

