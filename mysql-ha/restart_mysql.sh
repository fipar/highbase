#!/bin/bash
#
# mysql_restart.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar
# see the file COPYING for more info


. /usr/mysql-ha/common.sh
OF=/tmp/restart_mysql.$$


[ -x /etc/init.d/mysql ] && MYSQL_RC=/etc/init.d/mysql
[ -x /etc/init.d/mysqld ] && MYSQL_RC=/etc/init.d/mysqld

$MYSQL_RC stop >$OF 2>&1
$MYSQL_RC start >>$OF 2>&1 || log "$MYSQL_RC could not restart properly (error) $(cat $OF)"
rm -f $OF

