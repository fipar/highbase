#!/usr/bin/perl
#
# mysqlhad.pl  (daemon for mysql-ha)
#

# include subroutines
require 'mysqlmonitor.pl';
require 'readconf.pl';
use DBI;
use Net::Ping;
use Sys::Syslog;
use Mail::Send;

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
	
	if(!(MysqlMonitor($clusterip,$mode,$port,$repluser,$replpass,$testdb))){
	    &Log("warning","failed to connect to master mysql daemon");

	    ## master appears to be down, double check
	    sleep($conf{'MONITOR_RECHK'});
	    if(!(MysqlMonitor($clusterip,$mode,$port,$repluser,$replpass,$testdb))){
		## master mysqld definately isn't responding
		if(&PingMaster($conf{'MASTER_HOST'})){
		    print "Master mysqld down, machine up\n";
		    ## connect via SSH::Perl
		    # kill mysql
		    # restart mysql
		    # check again
		    # if back, we're all good
		    # if not, set the master to not restart mysql on reboot
		    #         turn off it's public networking, etc
		    # TakeOver() (which double checks local mysqld first)
		    #    verify that it worked, exit mysql-had

		}else{
		    print "Master mysqld down, machine down\n";
		    # 
		    # TakeOver() (which double checks local mysqld first)
		    #    verify that it worked, exit mysql-had
		}
	    }
	}

	## change this later
	sleep($conf{'MONITOR_CHK_THRESHOLD'});	
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

sub PingMaster($masterhost){
    local($masterhost) = @_;
    local($p,$result);
    $p = Net::Ping->new();
    $result = $p->ping($masterhost);
    $p->close();

    return $result;
}


### later we can expand Log() to send email or other forms of notification
#   based on $level   ($level must be a valid syslog level)

sub Log($level,$message){
    local($level,$message) = @_;
    openlog("mysql-had", 'pid', 'user');
    syslog($level,$message);
    closelog();

    if($conf{'NOTIFY_METHODS'} =~ /email/i){
	if($conf{'NOTIFY_EMAIL'} =~ /([\w\-]+\@[\w\-\.]+)/){
	    $address = $1;
	    print "send email to $address\n";
	    $msg = new Mail::Send;
	    $msg->to($address);
	    $msg->subject("$hostname mysql-ha");
	    $fh = $msg->open('sendmail');
	    print $fh "$hostname mysql-ha\n\n$message";
	    $fh->close;
	}else{
	    ## don't call Log(), would result in a loop
	    $message = "Failed to send email, NOTIFY_EMAIL invalid";
	    $level = "info";
	    openlog("mysql-had", 'pid', 'user');
	    syslog($level,$message);
	    closelog();
	}
    }
}
