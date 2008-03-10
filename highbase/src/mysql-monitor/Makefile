#
#	$Id$
#	jbuchbinder@ravewireless.com
#

CC= gcc
STRIP= strip
PROG= mysql-monitor
OBJ= monitor.o
CFLAGS= `mysql_config --cflags`
LIB= `mysql_config --libs` -lz -lm -lpthread

all: static dynamic
	@echo "Completed build."

dynamic: clean $(OBJ)
	@echo -n "Building dynamic executable ... "
	@$(CC) -o $(PROG) $(OBJ) $(LIB) 2>&1 > /dev/null
	@echo "[done]"
	@echo -n "Stripping executable ... "
	@$(STRIP) --strip-unneeded $(PROG)
	@echo "[done]"

static: clean $(OBJ)
	@echo -n "Building static executable ... "
	@$(CC) -o $(PROG).static $(OBJ) $(LIB) -static 2>&1 > /dev/null
	@echo "[done]"
	@echo -n "Stripping executable ... "
	@$(STRIP) --strip-unneeded $(PROG).static
	@echo "[done]"

.c.o:
	@echo -n "Compiling $@ ... "
	@$(CC) -o $@ -c $< $(CFLAGS)
	@echo "[done]"

clean:
	@echo -n "Cleaning previous compiles ... "
	@rm $(PROG) $(OBJ) -f
	@echo "[done]"

install: static
	mkdir -p /usr/local/highbase/
	cp -v mysql-monitor /usr/local/highbase/
