/*
	Name: Mysql-Proxy
	Version: 0.0.5
	Author: Computer_xu
	Email: Computer_xu@sina.com
	HomePage: http://www.netsock.org
	LastModify: 2002-08-05 (yyyy-mm-dd)
*/
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

#include <crypt.h>
#include <netdb.h>

/*
#include <mysql.h>
#include <errmsg.h>
*/

#include <arpa/inet.h>

#ifndef SIGCLD
#define SIGCLD SIGCHLD
#endif
#define MAXSOCKADDR  128

/* Ŀǰ֧��32����Ⱥ */
#define ClusterN  32

#ifndef PTHREAD_THREADS_MAX
/*ע�⣺����2.4.0��linux�汾�벻Ҫ�޸�������壬
	��������ڵ���2.4.0��linux�汾����Ч */
#define PTHREAD_THREADS_MAX 1024
#endif

/*
typedef struct mydb
{
	MYSQL *mysql;
	char *host;
	char *user;
	char *passwd;
	char *db;
	unsigned int port;
	char *unix_socket;
	unsigned int client_flag;
} MyDB;
*/

/* MySQL Server �أ�������������״̬ */
typedef struct realserver_info
{
	int connects;		/* �������� */
	int active;		/* �Ƿ��ڼ���״̬ */

	char ip[128];		/* ip address */
	unsigned int port;	/* port */

	int disable;		/* is true, proxy �����ٷ����κ��µ����ӵ���̨������ */

	char rootpasswd[64];	/* root �û������� */

	int load;		/* ���� */

} REALSERVER_INFO;

/* �߳�״̬�ṹ */
typedef struct pthread_info
{
	pthread_t pid;
	int status;

	int cli_conn, srv_conn[ClusterN];	/* Socket Connection handle */

	char user[64], passwd[64], db[129];	/* connect user passwd db */

	unsigned int linkcount;			/* ��Ӧ������� */

	unsigned int nSelect;			/* ���һ�ε�Cluster��䷢�͵�����һ������ */

	char AuthBuf[512];			/* Node��֤��Ϣ */
	char ErrBuf[512];			/* Node������Ϣ */

	struct pthread_info * next;

} PTHREAD_INFO;

typedef struct sysinformation
{
	unsigned int		nRealServer;		/* RealServer Number */
	unsigned int		nPort;			/* �����˿� 3306 */
	unsigned int		nCmdPort;		/* �����˿� 8888 Command Port */
	unsigned int		nLoadPort;		/* �����˿� 8889 AvgLoad Port */
	unsigned int		MasterServer;		/* ��������ID , Default = 0*/
	char 			AuthServer[128];	/* ��֤Server (127.0.0.1)*/
	unsigned int		AuthPort;		/* ��֤Server's Port (3307) */

	PTHREAD_INFO		*PTHREAD_HEAD;		/* ָ���߳�״̬���ݵĵ�һ����¼ */

	REALSERVER_INFO		RSInfo[ClusterN];	/* Server Pool */

	unsigned int		linkcount;		/* ��Ӧ������� */
} SYSINFO;

