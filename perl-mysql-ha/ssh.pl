#!/usr/bin/perl

use Net::SSH "ssh_cmd";


## replace dop with cfmaster host
ssh_cmd('root@dop', "touch","/tmp/blaafile");


