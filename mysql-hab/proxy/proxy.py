#!/usr/bin/python
#
# proxy server for mysql
# this file is part of the mysql-ha project
# (C) 2002 Fernando Ipar. 
# this is Free Software covered by the GPL
# see the file COPYING for more info

import os
import sys
import socket
import string
#import shm

# ******************************************************
# ### here's what you can modify to alter the behaviour
# ******************************************************
RECV_BUFF_SIZE = 1024
PROXY_BYE_MSG = "mysql-proxy v0.1.0, admin server closing connection\n"
PROXY_HELLO_MSG = "mysql-proxy v0.1.0, admin server starting\n"

#mysql proxy server config
LISTEN_ADDR = "127.0.0.1"
LISTEN_BACKLOG = 512
LISTEN_PORT = 3306

#admin server config
ADMIN_LISTEN_ADDR = "127.0.0.1"
ADMIN_LISTEN_BACKLOG = 16
ADMIN_LISTEN_PORT = 8888
ADMIN_ALLOWED_ADDR = "127.0.0.1", "192.114.70.12"

# ******************************************************
# ### you shouldn't need to modify anything from now on
# ******************************************************

#global init code
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((LISTEN_ADDR, LISTEN_PORT))
s.listen(LISTEN_BACKLOG)
servers = {}
nextid = 0

servers[0] = "127.0.0.1", 3308



def process_client(sock, addr, nextid, servers):
	if nextid == len(servers):
		nextid = 1
		currid = 0
	else:
		currid = nextid
		nextid = nextid + 1
	ip, port = servers[currid]
	print "using server " + ip
	cont = 1
	asock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	fam, stype, proto, cname, saddr = socket.getaddrinfo(ip,port)
	asock.connect(saddr)
	sock.setblocking(0)
	asock.setblocking(0)
	while cont == 1:
		if os.fork() != 0:
			while cont == 1:
				try:
					msg = sock.recv(RECV_BUFF_SIZE)
					if msg == "":
						cont = 0
					asock.send(msg)
				except:
					cont = 1
		else :
			while cont == 1:
				try:
					msg = asock.recv(RECV_BUFF_SIZE)
					if msg == "":
						cont = 0
					sock.send(msg)
				except:
					cont = 1

while 1:
	#update_servers(servers)
	con = s.accept()
	sock, addr = con
	if os.fork() != 0:
		sock.close()
	else:
		print "processing client ", addr, " with server ", nextid
		process_client(sock, addr, nextid, servers)
		sock.close()
		sys.exit(0)
