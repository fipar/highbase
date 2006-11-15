#!/bin/bash
# init-system.sh
# prepares a test system for mysql-ha after an installation has already been done
# 
# ******************************************
# THIS SCRIPT IS USEFUL ONLY ON TEST SYSTEMS
# ******************************************

userdel mysqlha
groupdel mysqlha
grep -v mysql-ha /etc/bashrc > tmpf && mv -f tmpf /etc/bashrc
grep -v mysqlha /etc/sudoers > tmpf && mv -f tmpf /etc/sudoers

