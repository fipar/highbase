#!/bin/bash
#
# stop_slave_thread.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar
# see the file COPYING for more info

. /usr/mysql-ha/common.sh

DB_USER=${1:-root}
DB_PASSWORD=${2:-rootpwd}

echo "slave stop" | mysql -u$DB_USER -p$DB_PASSWORD && log "slave thread stopped (ok)" || log "could not stop slave thread (error)"
