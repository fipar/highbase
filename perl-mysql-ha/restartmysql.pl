#!/usr/bin/perl

## this needs to be changed during installation to whatever the user wants
push(@INC,"/usr/mysql-ha-perl/");

## if we don't autoflush the buffer, the ssh session will stall
$| = 1;

require 'mysqlmonitor.pl';
require 'readconf.pl';
require 'log.pl';

use Proc::ProcessTable;

# read configuration info
%conf = &ReadConf;

## $ENV{'HOSTNAME'} doesn't work when called remotely with ssh_cmd?
#$hostname = $ENV{'HOSTNAME'};
$hostname = `/bin/hostname`;
$slavestatus = "No";
$mysqlrepl = 0;
$clusterip = $conf{'CLUSTER_IP'};
$mode = "mysql";
$port = "3306";
$repluser = $conf{'MYSQL_USER'};
$replpass = $conf{'MYSQL_PASSWORD'};
$testdb = $conf{'MYSQL_DATABASE'};
$localuser = $conf{'DB_USER'};
$localpass = $conf{'DB_PASSWORD'};


# sanity check
# first verify that the local mysql daemon is, in fact, not responding
if(!(MysqlMonitor($hostname,$mode,$port,$localuser,$localpass,$testdb))){
    print "The local MySQL daemon is definately not responding.\n";

# this works, just commented out for faster testing
    &Log("warning","Local master mysqld not responding");
    system("/etc/init.d/mysql stop");

## problem, it takes awhile for mysql to shut down sometimes
    ## should we have a MYSQL_SHUTDOWN_TIME variable?
    ## if this variable isn't large enough it will result in restartmysql.pl
    ## possibly shutting down a running mysql daemon
    sleep(10);

    ## maybe this process stuff should only happen in killmysql.pl since
    # it could theoretically damage things
    # killmysql may not even kill mysql, maybe only kill the outbound
    # network interface
    $t = new Proc::ProcessTable;
    foreach $p ( @{$t->table} ){
#	print $p->pid."  ".$p->cmndline."\n";
	## is this too dangerous?  killing everything that matches 'mysqld'
        if($p->cmndline =~ /mysqld/){
	    kill(9,$p->pid);
	}
    }

    ## try to restart
    # for some reason we need to double fork here or the session just hangs
    # I've tried a lot of stuff, but a double fork is the only thing that seems
    # to work.  (Thank you, Zach Miller)

    system("/etc/init.d/mysql start > /dev/null 2>\&1");

#    $pid = fork;
#    if($pid == 0){
#	$pid = fork;
#	if($pid == 0){
#	      system("/etc/init.d/mysql start > /dev/null 2>\&1");
#	      exit 1;
#	  }
#	exit 1;
#   }

}else{
    print "local Mysqld responding just fine\n";
    ## do some sort of network test?  restart anyways?


    ## for now, go through same process as if it wasn't running
    &Log("warning","Local master mysqld responding okay, but restarting");
    system("/etc/init.d/mysql stop");

    sleep(10);
    $t = new Proc::ProcessTable;
    foreach $p ( @{$t->table} ){
        if($p->cmndline =~ /mysqld/){
	    kill(9,$p->pid);
	}
    }
    system("/etc/init.d/mysql start");


}



# then try (/etc/init.d/mysql stop)
# verify using Proc::ProcessTable that mysql is not running
# if still running, kill -9 the processes listed previously
# mysqladmin won't work here because mysql is already not responding

# if not, try to kill it (note, restartmysql.pl should always be run before
# killmysql.pl)
    # killmysql may not even kill mysql, maybe only kill the outbound
    # network interface   (same end result)
    # should be a configuration option
