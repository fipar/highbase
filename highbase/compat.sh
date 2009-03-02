#!/bin/bash
#this file is part of the highbase suite and is distributed under the GPL

#this file will include everything that must me changed
#according to the system's distribution. 

REDHAT_CHK_CONFIG='chkconfig --level 345 highbased on'
DEBIAN_CHK_CONFIG='update-rc.d highbased start 20 3 4 5'
# set this one if none of the two above work for your system
CUSTOM_CHK_CONFIG=

[ -f /etc/redhat-release ] && {
	export CHK_CONFIG="$REDHAT_CHK_CONFIG"
	export BASHRC="/etc/bashrc"
}
[ -f /etc/debian_version ] && {
	export CHK_CONFIG="$DEBIAN_CHK_CONFIG"
	export BASHRC="/etc/bash.bashrc"
}

# in case we don't have usleep in our system
NO_USLEEP=0
SLEEP=$(which sleep)
[ -n "$(type usleep 2>/dev/null)" ] && SLEEP=$(which usleep) || NO_USLEEP=1
export SLEEP NO_USLEEP

# we don't set FPING here because you must manually install it and it should always end up in the same place

export FUSER=$(which fuser 2>/dev/null)
export KILL=$(which kill 2>/dev/null)
export IFCONFIG=$(which ifconfig 2>/dev/null) 
export PS=$(which ps 2>/dev/null)
export SHUTDOWN=$(which shutdown 2>/dev/null)
export FAKE=$(which fake 2>/dev/null)
export MAIL=$(which mail 2>/dev/null)
export SMBCLIENT=$(which smbclient 2>/dev/null)
export FPING=$(which fping 2>/dev/null)
[ -x /etc/init.d/mysqld ] && export RC_SCRIPT=/etc/init.d/mysqld || {
	[ -x /etc/init.d/mysql ] && export RC_SCRIPT=/etc/init.d/mysql
}


# the defaults are set here, if you experience any problems (our script not finding your PATH), set this variables to proper values 
# these defaults are based on Fedora Core 5
[ -z "$FUSER" ] && export FUSER=/sbin/fuser && echo fuser ok
[ -z "$KILL" ] && export KILL=/bin/kill
[ -z "$IFCONFIG" ] && export IFCONFIG=/sbin/ifconfig
[ -z "$PS" ] && export PS=/bin/ps
[ -z "$SHUTDOWN" ] && export SHUTDOWN=/sbin/shutdown
[ -z "$FAKE" ] && export FAKE=/usr/bin/fake
[ -z "$MAIL" ] && export MAIL=/bin/mail
[ -z "$SMBCLIENT" ] && export SMBCLIENT=/usr/bin/smbclient
[ -z "$FPING" ] && export FPING=/usr/local/sbin/fping

get_sudoers_line() {
	cat <<EOF>&2
	This is the sudoers line I was able to write after examining your PATH: 

	highbase ALL=NOPASSWD:$FPING, $HIGHBASE_HOME/get_master.sh, $FUSER, $PS, $KILL, $RC_SCRIPT, $SHUTDOWN, $FAKE, $IFCONFIG
	
	If this makes sense to you, append it to your /etc/sudoers file (this messages are sent to stderr, while the line itself
	is sent to stdout for easy pipelining)

	Please note that the get_master.sh script is located at HIGHBASE_HOME, and at this stage, this directory might be guessed as '.'
	If this is the case, please change it accordingly. 

EOF
}

