#!/usr/bin/perl

use Sys::Syslog;
use Mail::Send;

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

1;
