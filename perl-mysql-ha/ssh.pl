#!/usr/bin/perl

use Net::SSH "ssh_cmd";

sub RemoteCmd($remoteuser,$remotehost,$command){
    local($user,$host,$command) = @_;
    print "user = $user\nhost=$host\ncmd=$command\n";
    $uh = $user."\@".$host;

#    $pid = fork;
#    if($pid == 0){
	ssh_cmd($uh, $command);
#	exit 1;
#    }
#    waitpid($pid,0);

}

1;
