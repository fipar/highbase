#!/usr/bin/perl
#
# mysqlhad.pl  (daemon for mysql-ha)
#

# include subroutines
require 'mysqlmonitor.pl';

$host = "hostname.network.net";
$mode = "mysql";
$port = "3306";
$username = "repl";
$password = "password";
$database = "test";

if(MysqlMonitor($host,$mode,$port,$username,$password,$database)){
    print "successful\n";
}else{
    print "unsuccessful\n";
}

