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

/* 目前支持32个集群 */
#define ClusterN  32

#ifndef PTHREAD_THREADS_MAX
/*注意：低于2.4.0的linux版本请不要修改这个定义，
	这个定义在低于2.4.0的linux版本上有效 */
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

/* MySQL Server 池，各个服务器的状态 */
typedef struct realserver_info
{
	int connects;		/* 连接数量 */
	int active;		/* 是否处于激活状态 */

	char ip[128];		/* ip address */
	unsigned int port;	/* port */

	int disable;		/* is true, proxy 将不再发起任何新的连接到此台服务器 */

	char rootpasswd[64];	/* root 用户的密码 */

	int load;		/* 负载 */

} REALSERVER_INFO;

/* 线程状态结构 */
typedef struct pthread_info
{
	pthread_t pid;
	int status;

	int cli_conn, srv_conn[ClusterN];	/* Socket Connection handle */

	char user[64], passwd[64], db[129];	/* connect user passwd db */

	unsigned int linkcount;			/* 响应请求计数 */

	unsigned int nSelect;			/* 最后一次的Cluster语句发送到了哪一个连接 */

	char AuthBuf[512];			/* Node认证信息 */
	char ErrBuf[512];			/* Node返回信息 */

	struct pthread_info * next;

} PTHREAD_INFO;

typedef struct sysinformation
{
	unsigned int		nRealServer;		/* RealServer Number */
	unsigned int		nPort;			/* 侦听端口 3306 */
	unsigned int		nCmdPort;		/* 侦听端口 8888 Command Port */
	unsigned int		nLoadPort;		/* 侦听端口 8889 AvgLoad Port */
	unsigned int		MasterServer;		/* 主服务器ID , Default = 0*/
	char 			AuthServer[128];	/* 认证Server (127.0.0.1)*/
	unsigned int		AuthPort;		/* 认证Server's Port (3307) */

	PTHREAD_INFO		*PTHREAD_HEAD;		/* 指向线程状态数据的第一条记录 */

	REALSERVER_INFO		RSInfo[ClusterN];	/* Server Pool */

	unsigned int		linkcount;		/* 响应请求计数 */
} SYSINFO;

