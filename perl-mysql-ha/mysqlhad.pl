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

## Determine masterhost
## can determine masterhost from my.cnf or from show slave status
## or from mysql startup script (/etc/init.d/mysql or mysqld)
$conf{'MASTER_HOST'} = &GetMasterHost;
print "master host is $conf{'MASTER_HOST'}\n";


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
	    $mysqlrepl = 0;
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


sub GetMasterHost(){
    local($master) = "";	  
    if(-e "/etc/my.cnf"){
	if(!(open(MYCNF,"/etc/my.cnf"))){
	    print "/etc/my.cnf exists but can't be opened\n";
	    #non-fatal error
	}else{
	    while(<MYCNF>){
		if( /^\s*master-host\s*=\s*[\'\"]*([\w\-\.]+)/i ){
		    $master = $1;
		    last;
		}
	    }
	    close(MYCNF);
	}
	if($master eq ""){
	    ## look in startup script(s)
	    if((-e "/etc/init.d/mysql") || (-e "/etc/init.d/mysqld")){
		if((!(open(MYSQL,"/etc/init.d/mysql"))) &&
		   (!(open(MYSQL,"/etc/init.d/mysqld")))){
		    print "Failed to open MySQL startup script\n";
		    #non-fatal error
		}else{
		    while(<MYSQL>){
			if( /master-host=[\'\"]*([\w\-\.]+)/i ){
			    $master = $1;
			    last;
			}
		    }
		    close(MYSQL);
		}
	    }
	}
	if($master eq ""){
	    ## try to determine master-host from SHOW SLAVE STATUS
	    my $dbh = DBI->connect( "DBI:$mode:$testdb:localhost:$port", $localuser, $localpass );
	    if(!($dbh)){
		print "failed to connect to local mysql daemon, do something\n";
	    }
	    
	    $query = "SHOW SLAVE STATUS";
	    my $sth = $dbh->prepare($query);
	    $sth->execute();
	    $ref = $sth->fetchrow_arrayref();
	    $master = $$ref[0];
	    $sth->finish();
	    $dbh->disconnect();
	}
    }
    
    if($master eq ""){
	print "Could not determine MASTER_HOST\n";
	exit 0;
    }

    return $master;
}
