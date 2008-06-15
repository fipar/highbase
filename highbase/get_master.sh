#!/bin/bash
# this script obtains the replication master from master.info
# this is part of highbase and is released under the GPL
# (C) 2002 - 2008 - Fernando Ipar - fipar@seriema-systems.com
# host is line 4 of master.info, according to  http://mysql.mirrors-r-us.net/doc/refman/5.0/en/slave-logs.html
(head -4 /var/lib/mysql/master.info |tail -1)
