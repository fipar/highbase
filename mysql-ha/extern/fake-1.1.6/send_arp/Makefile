######################################################################
# Makefile for send_arp                                   October 1998
# horms                                             horms@vergenet.net
#
#
# Freely distributable under the terms of the 
# GNU General Public License
#
# Note: send_arp was written by:
#         yuri volobuev'97
#         volobuev@t1.chem.umn.edu
#
#
# This make file is included to help automation of installation
#
######################################################################

ROOT_DIR=
SRC=send_arp.c
BIN=send_arp
BIN_DIR=$(ROOT_DIR)/usr/bin

.PHONY: all install clean

all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(SRC) -o $(BIN)

clean:
	rm -f $(BIN) core

install:
	mkdir -p $(BIN_DIR)
	cp $(BIN) $(BIN_DIR)
