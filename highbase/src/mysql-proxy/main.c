/*
	Name: Daemon Lib
	Version: 0.0.1
	Author: Computer_xu
	Email: Computer_xu@sina.com
	HomePage: http://www.netsock.org
	LastModify: 2002-08-05 (yyyy-mm-dd)
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "daemon_init.h"

extern void daemon_init(const char *, int );
extern int DoApp(int , char **);

/* The main function from here */
int main(int argc, char *argv[])
{

	if( access(LOCK_FILE,R_OK)==0 )
	{
		printf("Existing copy of this daemon!\n");
		printf("Please remove %s.\n", LOCK_FILE);
		exit(1);
	}

	/* make it to a daemon  AND  write log to /dev/null */
	daemon_init(NULL,-1);

	/* Do your App */
	return( DoApp(argc, argv) );
} 

