#!/bin/bash
#
# setup_fake.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

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

