#!/usr/bin/perl

require "mysqlmonitor.pl";

# sanity check
# verify that the local mysql daemon isn't responding.
# if it is, just run /etc/init.d/mysql restart
# if not, run /etc/init.d/mysql stop just for kicks
# make sure Proc::ProcessTable doesn't list any runnin processes
# If it does, kill -9 the processes previously returned
# then run /etc/init.d/mysql start

# don't bother verifying if it worked, the slave will do that.
