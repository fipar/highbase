#!/bin/bash
#
# setup_fake.sh
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

#
# generates the fake instance_config file
# according to the values provided by the
# user on the mysql-ha.conf file
#

. /usr/mysql-ha/common.sh

FAKEDIR=/etc/fake/
FAKEINSTANCEDIR=/etc/fake/instance_config

[ -d $FAKEDIR ] ||  die "$FAKEDIR does not exist" 1
[ -d $FAKEINSTANCEDIR ] || die "$FAKEINSTANCEDIR does not exist" 1
[ -n "$(type -a fake 2>/dev/null)" ] || die "fake not found" 1
[ -n "$(type -a send_arp 2>/dev/null)" ] || die "send_arp not found" 1

FAKEFILEN=$FAKEINSTANCEDIR/$CLUSTER_IP.cfg

cat <<EOF>$FAKEFILEN
SPOOF_IP=$CLUSTER_IP
SPOOF_NETMASK=$CLUSTER_NETMASK
SPOOF_BROADCAST=$CLUSTER_BROADCAST
TARGET_INTERFACE=$CLUSTER_DEVICE
EOF

