#!/usr/bin/perl
#
# mysqlhad.pl  (daemon for mysql-ha)
#

# include subroutines
require 'mysqlmonitor.pl';
require 'readconf.pl';
require 'ssh.pl';
use DBI;
use Net::Ping;
use Sys::Syslog;
use Mail::Send;
use Net::Ifconfig::Wrapper;
use Net::SSH "ssh_cmd";

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

## determine if this host is the currently running master by searching
#  for the clusterip in the currently configured network devices
$master = 0;
my $Info = Net::Ifconfig::Wrapper::Ifconfig('list', '', '', '')
    or die $@;
scalar(keys(%{$Info}))
    or die "No one interface found. Something wrong?\n";
foreach (sort(keys(%{$Info}))){
    ($addr,$mask) = each(%{$Info->{$_}{'inet'}});
    if($addr =~ $clusterip){
	print "This host is the current master.\n";
	$master = 1;
	last;
    }
};

## match against a list of slaves from the config file
if(($master != 1) && ($conf{'SLAVE'} =~ /$hostname/i)){
    print "This a slave, test the master.\n";
    ## Determine masterhost
    ## can determine masterhost from my.cnf or from show slave status
    ## or from mysql startup script (/etc/init.d/mysql or mysqld)
    $conf{'MASTER_HOST'} = &GetMasterHost;
    print "master host is $conf{'MASTER_HOST'}\n";
    
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
		    ## connect via Net::SSH
		    &RemoteCmd("root",$conf{'MASTER_HOST'},"/usr/mysql-ha-perl/restartmysql.pl");
		    print "done with remote restart\n";
		    # kill mysql
		    # restart mysql
		    # check again
		    # if back, we're all good
		    # if not, set the master to not restart mysql on reboot
		    #         turn off it's public networking, etc
		    # TakeOver() (which double checks local mysqld first)
		    #    verify that it worked, exit mysql-had

		    if(&TakeOver){
			&Log("info","mysql takeover successful, mysql-had shutting down");
			print "Takeover successful, shifting to monitoring as master now\n";

			# This should work because the master loop check is
			# after the slave loop check
			$master = 1;
			last;

			## is it possible to switch into master monitoring mode
			#  instead of just stopping mysql-had?
#			exit 1;
		    }

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
if($master == 1){

    print "Entering master loop...\n";
## loop master here
 # it should monitor all slaves unless they match the local hostname
 #  (in the case of mysql-had converting to master mode after a takeover)

}



sub TakeOver(){

    # Make sure the local MySQL daemon is working, but don't do it over
    #  the loopback device
    if(!(MysqlMonitor($hostname,$mode,$port,$repluser,$replpass,$testdb))){
	print "local MySQL daemon not responding\n";
	&Log("warning","failed to connect to local mysql daemon, cannot takeover service");
	return 0;
    }

    ## do the actual takeover stuff here

    return 1;
}


sub GetSlaveThreadStatus(){
    local($ver,$status);
    $status = "No";
    my $dbh = DBI->connect( "DBI:$mode:$testdb:localhost:$port", $localuser, $localpass );
    if(!($dbh)){
	print "failed to connect to local mysql daemon, do something\n";
	&Log("warning","Failed to connect to local mysql daemon");
	return "No";
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
