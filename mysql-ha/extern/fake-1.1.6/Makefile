######################################################################
# Makefile for fake                                       October 1998
# Horms                                             horms@vergenet.net
#
# Fake
# Script to spoof an ip
# Designed to create redundant servers
# Copyright (C) 1998  Horms <horms@vergenet.net>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330,
######################################################################

ROOT_DIR=
BIN_DIR=$(ROOT_DIR)/usr/bin
BIN=fake
CONFIG_DIR=$(ROOT_DIR)/etc/fake
CONFIG=.fakerc clear_routers
INSTANCE_CONFIG_DIR=$(ROOT_DIR)/etc/fake/instance_config
INSTANCE_CONFIG=instance_config/203.12.97.7.cfg
MAN8=fake.8 send_arp.8
MAN8_DIR=$(ROOT_DIR)/usr/man/man8
DOC_DIR=$(ROOT_DIR)/usr/doc/fake-1.0.0
DOCS=README AUTHORS COPYING ChangeLog

.PHONY: all install clean patch

all: patch
	make -C send_arp

clean:
	make -C send_arp clean
	rm -f core

install: all
	make -C send_arp install
	test -d $(BIN_DIR) || mkdir -p $(BIN_DIR)
	install -c -m 755 $(BIN) $(BIN_DIR)
	test -d $(CONFIG_DIR) || mkdir -p $(CONFIG_DIR)
	install -c -m 644 $(CONFIG) $(CONFIG_DIR)
	test -d $(INSTANCE_CONFIG_DIR) || mkdir -p $(INSTANCE_CONFIG_DIR)
	install -c -m 644 $(INSTANCE_CONFIG) $(INSTANCE_CONFIG_DIR)
	test -d $(DOC_DIR) || mkdir -p $(DOC_DIR)
	install -c -m 644 $(DOCS) $(DOC_DIR)
	test -d $(MAN8_DIR) || mkdir -p $(MAN8_DIR)
	install -c -m 644 $(MAN8) $(MAN8_DIR)

patch:
	cd send_arp ; test -f Makefile ||  patch -p 1  < ../send_arp.patch
