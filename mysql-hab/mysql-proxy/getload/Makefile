CC=gcc
CCFLAG=-g -c
getload	 	: getload.o base.o
		  $(CC) getload.o base.o -o getload
getload.o	: getload.c
		  $(CC) $(CCFLAG) getload.c
base.o		: base.c base.h
		  $(CC) $(CCFLAG) base.c
clean		: *.o
		  rm getload *.o
install		: getload
		  echo "Complete!\n";
