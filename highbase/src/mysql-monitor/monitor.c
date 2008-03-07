/*
 * 	$Id$
 * 	jbuchbinder@ravewireless.com
 *
 */

#include <stdio.h>
#include <mysql/mysql.h>

int main ( int argc, char **argv ) {
	static MYSQL db;

	if ( argc < 3 ) {
		printf( "syntax: %s host user password databasename\n", argv[0] );
		return( 1 );
	}

	if( ! mysql_real_connect( &db, argv[1], argv[2], argv[3], argv[4], (unsigned int) 3306, NULL, 0 ) ) {
		printf( "Error in connection with dbi (%s).\n", mysql_error( &db ) );
		return( 1 );
	}

	if ( mysql_select_db( &db, argv[4] ) ) {
		printf( "Unable to select database '%s'.\n", argv[4] );
		return( 1 );
	}

	printf( "OK (mysql://%s/%s)\n", argv[1], argv[4] );
	return( 0 );
}

