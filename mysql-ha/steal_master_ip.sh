#!/bin/bash
#
# steal_master_ip.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar. see the file COPYING for more info

#
# here we should do an endless loop sending ARP packets to
# keep getting the packets for CLUSTER_IP
#

#this value is still under consideration, we need to know
#how often linux updates it's ARP table
ARP_LOOP_TIME=60 
MAC_ADDR=$(ifconfig $CLUSTER_DEVICE|grep HWaddr|awk -F HWaddr '{print $2}')

while :; do
	#this line needs revition
	/usr/mysql-ha/extern/send_arp $CLUSTER_IP $MAC_ADDR $CLUSTER_IP ffffffff
done