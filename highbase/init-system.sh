#!/bin/bash
# init-system.sh
# prepares a test system for highbase after an installation has already been done
# 
# ******************************************
# THIS SCRIPT IS USEFUL ONLY ON TEST SYSTEMS
# ******************************************

userdel highbase
groupdel highbase
rm -rf /home/highbase
grep -v highbase /etc/bashrc > tmpf && mv -f tmpf /etc/bashrc
grep -v highbase /etc/sudoers > tmpf && mv -f tmpf /etc/sudoers
chmod 440 /etc/sudoers

