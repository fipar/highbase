#!/usr/bin/perl
#
# ========= I M P O R T A N T       N O T I C E  ===================
# this script was taken from the mon package from kernel.org (http://kernel.org/pub/soft/admin/mon/)
# the next comment includes more info, but this script was also released under the GNU GPL
# Fernando Ipar. 
#
# $Id$

# 5-13-2003  Mike Dopheide (dopheide@ncsa.uiuc.edu)
# Converted from stand-alone script to be called as a sub-routine from
# perl-based mysql-ha.  Modified it quite a bit.

# This monitor requires the perl5 DBI, DBD::mSQL and DBD::mysql modules,
# available from CPAN (http://www.cpan.org)
#
#    Copyright (C) 1998, ACC TelEnterprises
#    Written by James FitzGibbon <james@ican.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use DBI;

sub MysqlMonitor($host,$mode,$port,$username,$password,$database){
    local(@options) = @_;
    local($host,$mode,$port,$username,$password,$database,@failures);
    if($#options != 5){
	print "Invalid number of options for MysqlMonitor()\n";
	return 0;
    }
    $host = $options[0];
    $mode = $options[1];
    $port = $options[2];
    $username = $options[3];
    $password = $options[4];
    $database = $options[5];

    if( $mode =~ m/msql/i ) { 
	$mode = "mSQL";
    } elsif( $mode =~ m/mysql/i) {
	$mode = "mysql";
    } else {
	print "invalid mode $mode!\n";
	return 0;
    }
    
    my( $dbh ) = DBI->connect( "DBI:$mode:$database:$host:$port", $username, $password );
    if( ! $dbh ) {
	push( @failures, "Could not connect to $mode server $host: " . $DBI::errstr );
    }else{
	@tables = $dbh->tables();
	if( $#tables < 0 ) {
	    push( @failures, "No tables found for database $database on server $host" );
	}
	$dbh->disconnect();
    }
    
    if (@failures) {
	print join (", ", sort @failures), "\n";
	return 0;
    };

    return 1;
    
}

1;
