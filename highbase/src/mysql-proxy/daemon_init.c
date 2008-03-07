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
#include <syslog.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#include "daemon_init.h"

void sig_quit(int signo);
void sig_chid(int signo);

extern void app_quit(int signo);
extern int daemon_proc;

/* ��׼Daemon��ʼ�����򣬲ο�Unix�����̵ڶ��� Vol1 P288�����ڴ˻����ϣ�������һЩ���� */
/* ����˵����
	pname == NULL and facility == -1	������Ϣ��ָ�� /dev/null
	pname == NULL and facility != -1	������Ϣ��ָ�� LOG_FILE
	pname != NULL				������Ϣͨ�� syslog ���м�¼
*/
void daemon_init(const char *pname, int facility)
{ 
	int i, maxfd;
	pid_t pid;
	FILE *fp;

	if((pid=fork()) != 0 )
		exit(0);	/* �����̽��� */
				/* ������һ���ӽ��� */
	if(setsid() < 0)
	{
		perror("setsid");
		exit(0);
	}

	signal(SIGHUP, SIG_IGN);

	if((pid=fork()) != 0)
	{
		if( pid > 0 )
		{
			fp = fopen(LOCK_FILE,"wt");
			fprintf(fp,"%d",pid);
			fclose(fp);
		}
		else
		{
			perror("fork");
		}
		exit(0);
	}

	signal(SIGPIPE, SIG_IGN);
	signal(SIGTERM, sig_quit);
	signal(SIGCHLD, sig_chid);

	chdir("/");	umask(0);

	maxfd = sysconf(_SC_OPEN_MAX);
	for(i=0; i<maxfd; i++)	close(i);

	if( pname == NULL )
	{
		if( facility == -1 )	open("/dev/null", O_RDWR);
		else			open(LOG_FILE, O_RDWR|O_CREAT|O_TRUNC);
		dup(0); dup(1); dup(2);
		daemon_proc = 0;
	}
	else
	{
		openlog(pname, LOG_PID, facility);
		daemon_proc = 1;
	}
}

/* quit and remove LOCK_FILE */
void sig_quit(int signo)
{
	app_quit(signo);
	printf("Received signal %d\n",signo);
	unlink(LOCK_FILE);
	exit(1);
}

/* wait the child die */
void sig_chid(int signo)
{
	pid_t pid;
	int stat;

	while((pid = waitpid(-1, &stat, WNOHANG))>0);
	printf("children %d died\n", pid);
}
