#!/bin/bashrc
#this file is part of the mysql-ha suite and is distributed under the GPL

#this file will include everything that must me changed
#according to the system's distribution. 

CUSTOM_CHK_CONFIG= #set this one if none of the two above work for your system
REDHAT_CHK_CONFIG='chkconfig --level 345 mysql-had on'
DEBIAN_CHK_CONFIG='update-rc.d mysql-had start 20 3 4 5'

[ -f /etc/redhat-release ] && {
	export CHK_CONFIG="$REDHAT_CHK_CONFIG"
	export BASHRC="/etc/bashrc"
}
[ -f /etc/debian_version ] && {
	export CHK_CONFIG="$DEBIAN_CHK_CONFIG"
	export BASHRC="/etc/bash.bashrc"
}