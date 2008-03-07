INC=-I./
LIB=-L./
CC=gcc
CCFLAG=-Wall -g -c $(INC)
LDFLAG=-D_REENTRANT $(LIB) -pthread -lpthread -lcrypt
OBJ=main.o error.o daemon_init.o doapp.o proxy-main.o
proxy	 	: $(OBJ)
		  $(CC) $(LDFLAG) $(OBJ) -o proxy
main.o		: daemon_init.h main.c
		  $(CC) $(CCFLAG) main.c
error.o		: error.c
		  $(CC) $(CCFLAG) error.c
daemon_init.o	: daemon_init.h daemon_init.c
		  $(CC) $(CCFLAG) daemon_init.c
doapp.o		: doapp.c
		  $(CC) $(CCFLAG) doapp.c
proxy-main.o	: proxy-main.c
		  $(CC) $(CCFLAG) proxy-main.c
clean		:
		  rm proxy *.o

