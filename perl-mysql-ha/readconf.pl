#!/usr/bin/perl

sub ReadConf(){

# set defaults:
%conf = ("CLUSTER_IP","192.168.0.1",
	 "CLUSTER_NETMASK","255.255.255.0",
	 "CLUSTER_BROADCAST","192.168.0.255",
	 "CLUSTER_DEVICE","eth0:0",
	 "MYSQL_USER","repl",
	 "MYSQL_PASSWORD","testpass",
	 "MYSQL_DATABASE","test",
	 "ARP_DELAY","5",
	 "MASTER_SLEEP_TIME","60",
	 "SLAVE_SLEEP_TIME","60",
	 "SSH_PATIENCE","20",
	 "MONITOR_PATIENCE","10",
	 "MONITOR_CHK_THRESHOLD","20",
	 "MONITOR_RECHK","5",
	 "MYSQL_KILL_WAIT","5",
	 "MYSQL_RESTART_WAIT","5",
	 "FPING_ATTEMPTS","3",
	 "SLAVE","slave.localhost",
	 "SIG_KILL_WAIT","5",
	 "DB_USER","dbuser",
	 "DB_PASSWORD","dbpassword",
	 "NOTIFY_METHODS","email",
	 "NOTIFY_EMAIL","root@localhost");

#$configfile = "/etc/mysql-ha.conf";
    $configfile = "/usr/mysql-ha-perl/mysql-ha.conf";
    
    if(!(open(CONF,"$configfile"))){
	print "Error opening $configfile\n";
	exit 0;
    }else{
	while(<CONF>){
	    if((!(/^\s*\#/)) && (/\s*([\w\-]+)\s*=\s*(.*)/)){
		$key = $1;
		$val = $2;
		$val =~ s/[\'\"]//g;
		$val =~ s/\s*$//g;
		$conf{$key} = $val;
	    }
	}
	close(CONF);
    }
    return %conf;
}

1;
