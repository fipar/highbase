#
#	$Id$
#	jbuchbinder@ravewireless.com
#

all: clean mysql-monitor

mysql-monitor:
	gcc -I/usr/include/mysql -o monitor.o -c monitor.c
	gcc -L/usr/lib `mysql_config --libs` -o mysql-monitor monitor.c

clean:
	rm -f mysql-monitor monitor.o

install: mysql-monitor
	mkdir -p /usr/local/highbase/
	cp -v mysql-monitor /usr/local/highbase/

