#!/usr/bin/perl
#
# mysqlhad.pl  (daemon for mysql-ha)
#

# include subroutines
require 'mysqlmonitor.pl';
require 'readconf.pl';
use DBI;

# read configuration info
%conf = &ReadConf;

$hostname = $ENV{'HOSTNAME'};
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

## can determine masterhost from my.cnf or from show slave status

## can match against a list of slaves from the config file
if($conf{'SLAVE'} =~ /$hostname/i){
    print "This a slave, test the master.\n";

    while(1){
	## check to see if the slave thread is running
	$slavestatus = &GetSlaveThreadStatus();
	if($slavestatus eq "Yes"){
	    $mysqlrepl = 1;
	}
	if(($slavestatus ne "Yes") && ($mysqlrepl == 1)){
	    $msyqlrepl = 0;
	    print "Notify that the slave thread stopped\n";
	}
	
	if(MysqlMonitor($clusterip,$mode,$port,$repluser,$replpass,$testdb)){
	    print "master is up\n";
	}else{
	    print "master is down\n";
	}
	
	## change this later
	sleep(5);
	
    }
}


sub GetSlaveThreadStatus(){
    local($ver,$status);
    $status = "No";
    my $dbh = DBI->connect( "DBI:$mode:$testdb:localhost:$port", $localuser, $localpass );
    if(!($dbh)){
	print "failed to connect to local mysql daemon, do something\n";
    }

    $query = "SHOW VARIABLES LIKE 'version'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    $ref = $sth->fetchrow_arrayref();
    $$ref[1] =~ /^(\d+)/;
    $ver = $1;

    $query = "SHOW SLAVE STATUS";
    $sth = $dbh->prepare($query);
    $sth->execute();
    $ref = $sth->fetchrow_arrayref();
    if($ver >= 4){
	if(($$ref[9] eq "Yes") && ($$ref[10] eq "Yes")){
	    $status = "Yes";
	}
    }else{
	if($$ref[6] eq "Yes"){
	    $status = "Yes";
	}
    }
    $sth->finish();
    $dbh->disconnect();

    return $status;
}
