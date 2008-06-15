#!/bin/bash
#
# mysql_restart.sh
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

. $HIGHBASE_HOME/common.sh
SUDO=$(cat $HIGHBASE_HOME/sudo_prefix)

OF=/tmp/restart_mysql.$$

${SUDO}$RC_SCRIPT stop >$OF 2>&1
${SUDO}$RC_SCRIPT start >>$OF 2>&1 || log "$RC_SCRIPT could not restart properly (error) $(cat $OF)"
rm -f $OF

