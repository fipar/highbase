#!/bin/bash
#
# start_slave_thread.sh
# this file is part of the mysql-ha suite
# Copyright (C) 2002 Fernando Ipar
# see the file COPYING for more info

. /usr/mysql-ha/common.sh


echo "slave start" | mysql -u$DB_USER -p$DB_PASSWORD && log "slave thread started (ok)" || log "could not start slave thread (error)"
