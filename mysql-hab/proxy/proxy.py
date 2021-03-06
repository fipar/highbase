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
import syslog
import signal

# ******************************************************
# ### here's what you can modify to alter the behaviour
# ******************************************************
RECV_BUFF_SIZE = 1024
PROXY_BYE_MSG = "mysql-proxy v0.1.0, admin server closing connection\n"
PROXY_HELLO_MSG = "mysql-proxy v0.1.0, admin server starting\n"

PIPE_PREFIX="/tmp/proxy_pipe"
#mysql proxy server config
LISTEN_ADDR = "0.0.0.0"
LISTEN_BACKLOG = 512
LISTEN_PORT = 3308

#admin server config
ADMIN_LISTEN_ADDR = "0.0.0.0"
ADMIN_LISTEN_BACKLOG = 16
ADMIN_LISTEN_PORT = 8888
ADMIN_ALLOWED_ADDR = "127.0.0.1", "192.168.0.1"

# ******************************************************
# ### you shouldn't need to modify anything from now on
# ******************************************************

#global init code
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((LISTEN_ADDR, LISTEN_PORT))
s.listen(LISTEN_BACKLOG)
servers = {}
nextid = 0
masterid = 0

servers[0] = "192.168.0.10", 3306
#servers[1] = "192.168.0.2", 3308
#servers[2] = "192.168.0.3", 3308

def schandler(signum, frame):
	syslog.syslog("child exited")

def process_client(sock, addr, ip, port):
	cont = 1
	asock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	asock.connect((ip,port))
	totalmsg = ""
	while cont == 1:
		if os.fork() != 0:
			while cont == 1:
				try:
					msg = sock.recv(RECV_BUFF_SIZE)
					totalmsg = totalmsg + msg
					if msg == "":
						cont = 0
					#the next if needs all updating queries, even DDL ones
					if string.find(msg,"INSERT") >-1 or string.find(msg,"insert")>-1 or string.find(msg,"UPDATE")>-1 or string.find(msg,"update")>-1 or string.find(sub,"DELETE")>-1 or string.find(sub,"delete")>-1:
						print "processing updating query"
						mip, mport = servers[masterid]
						msock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
						msock.connect((mip,mport))
						msock.send(totalmsg)
						idx = string.find(totalmsg,msg)
						totalmsg = totalmsg[0:idx-1]
						msg = msock.recv(RECV_BUFF_SIZE)
						sock.send(msg)
						msock.close()							
					else:
						asock.send(msg)
				except:
					cont = 1
		else:
			while cont == 1:
				try:
					msg = asock.recv(RECV_BUFF_SIZE)
					if msg == "":
						cont = 0
					sock.send(msg)
				except:
					cont = 1

signal.signal(signal.SIGCHLD,schandler)
while 1:
	try:
		con = s.accept()
	except:
		con = s.accept()
	sock, addr = con
	peer, ignore =  addr
	if nextid == (len(servers) - 1):
		currid = nextid
		nextid = 0
	else:
		currid = nextid
		nextid = nextid + 1
	if os.fork() != 0:
		sock.close()
	else:
		ip, port = servers[currid]
		syslog.syslog("mysql-proxy: processing client "+peer+":"+str(ignore)+" with server "+str(currid)+" ("+ip+":"+str(port)+")")
		process_client(sock, addr, ip, port)
		sock.close()
		sys.exit(0)
		
