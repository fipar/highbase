/*
	Name: Mysql-Proxy
	Version: 0.0.5
	Author: Computer_xu
	Email: Computer_xu@sina.com
	HomePage: http://www.netsock.org
	LastModify: 2002-08-05 (yyyy-mm-dd)
*/
#include "proxy.h"

extern void proxy(PTHREAD_INFO *);
void *thread_main(void *arg);
void *CfgPth(void *p);
void ParseCmd(int connfd);
void *AvgLoadPth(void *p);
void GetLoad(int );
void app_quit();
void InitSystem();
char *GetSocketIP(int );
void *Malloc(unsigned int );
void *Realloc(void * , unsigned int);
void Free(void *);
char *RecvTimeOut(int , int , int *);

SYSINFO sysinfo;

extern void err_msg();

int DoApp(int argc, char *argv[])
{
	int sockfd;
        pthread_t CfgPth_id, AvgLoadPth_id;
        int addrlen=sizeof(struct sockaddr_in);
        struct sockaddr_in srv_addr;
        PTHREAD_INFO *p, *p1, *p2;
        int status;

        int connfd;

        err_msg("Starting...\n");


	/* 系统初始化 */
        InitSystem();

	/* 建立侦听Socket */
        if((sockfd=socket(AF_INET,SOCK_STREAM,0))<0)
        {
                perror("socket");
                exit(1);
        }
        memset(&srv_addr,0,addrlen);
        srv_addr.sin_family=AF_INET;
        srv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
        srv_addr.sin_port=htons(sysinfo.nPort);
	addrlen=sizeof(struct sockaddr_in);
        if(bind(sockfd,(struct sockaddr *)&srv_addr,addrlen)<0)
        {
                perror("bind");
                close(sockfd);
                exit(2);
        }
        listen(sockfd,50);

	/* 不在root权限下运行 */
	/* change run id */
	err_msg("Change Run Id from Root to Normal ... ");
	setuid(getuid());
	setgid(getgid());
	err_msg("Ok\n");

        err_msg("System is running...\n");

	/* 系统管理线程 */

	if(pthread_create(&CfgPth_id,NULL,&CfgPth,(void*)NULL)>0)
        {
                perror("pthread_create");
                exit(3);
        }

	/* 获取AvgLoad数据线程 */

	if(pthread_create(&AvgLoadPth_id,NULL,&AvgLoadPth,(void*)NULL)>0)
        {
                perror("pthread_create");
                exit(3);
        }

        p=sysinfo.PTHREAD_HEAD;

	/* 创建线程 */
        for(;;)
	{
		connfd=accept(sockfd,(struct sockaddr *)&srv_addr,&addrlen);
		if( connfd < 0 )
		{
			perror("main:accept");
		}
		else
		{
			/* alloc new PTHREAD_INFO */
			p1 = (PTHREAD_INFO *)Malloc(sizeof(PTHREAD_INFO));
			p1->next = NULL;
			p1->status = 1;
			p1->linkcount = 0;
			p1->nSelect = sysinfo.nRealServer;
			p1->cli_conn = connfd;

			if( sysinfo.PTHREAD_HEAD == NULL )
			{
                        	sysinfo.PTHREAD_HEAD=p1;
	                }
        	        else
                	{
                        	p2->next=p1;
	                }
			p2=p1;

			/* Create pthread */
			do{
		        	status=pthread_create(&(p1->pid),NULL,&thread_main,(void *) p1);
			}while( status && errno==EINTR && status!=EAGAIN);
			if( status )
		        {
		                perror("thread_make:pthread_create");
				err_msg("Errno: %d/%d, Threads Max: %d\n",status,EAGAIN,PTHREAD_THREADS_MAX);
		                exit(1);
		        }
			/* free thread node */
			while( sysinfo.PTHREAD_HEAD != NULL && sysinfo.PTHREAD_HEAD->next != NULL )
			{
				if( sysinfo.PTHREAD_HEAD->status == 0 )
				{
					p1 = sysinfo.PTHREAD_HEAD;
					sysinfo.PTHREAD_HEAD = sysinfo.PTHREAD_HEAD->next;
					sysinfo.linkcount += p1->linkcount;
					free(p1);
				}
				else	break;
			}
		}
	}
}


void *CfgPth(void *p)
{
	int addrlen=sizeof(struct sockaddr_in);
	int socketfd;
	int connfd;
        struct sockaddr_in srv_addr;

	if((socketfd=socket(AF_INET,SOCK_STREAM,0))<0)
        {
                perror("socket");
                exit(1);
        }
	memset(&srv_addr,0,addrlen);
        srv_addr.sin_family=AF_INET;
        srv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
        srv_addr.sin_port=htons(sysinfo.nCmdPort);
	addrlen=sizeof(struct sockaddr_in);
        if(bind(socketfd,(struct sockaddr *)&srv_addr,addrlen)<0)
        {
                perror("bind");
                close(socketfd);
                exit(2);
        }
        listen(socketfd,5);
	for(;;)
	{
		connfd=accept(socketfd,(struct sockaddr *)&srv_addr,&addrlen);
		if( connfd < 0 )
		{
			perror("CfgPth:accept");
		}
		else
		{
			ParseCmd(connfd);
			close(connfd);
		}
	}
}

void ParseCmd(int connfd)
{
	char buf[4096];
	int nRead;
	REALSERVER_INFO *p;
	int i, j, len;
	char tmp[64];
	char *arg[7];
	int narg;

	for(;;)
	{
		nRead = read(connfd, buf, 4095);
		buf[nRead]='\0';
		len = strlen(buf);
		while( buf[len-1]=='\n' || buf[len-1]=='\r')	len--;
		buf[len]='\0';
		nRead = len;
		/* err_msg("Server read %d byte(s)\n",nRead); */

		/* 处理参数 */
		narg=0;	i=0;	j=0;
		arg[j]=buf;
		for( i=0; i<nRead; i++ )
		{
			if( buf[i] == ' ' )
			{
				while( (buf[i] == ' ') && ( i < nRead ) )
				{
					buf[i]='\0';
					i++;
				}
				if( i < nRead )
				{
					j++;
					arg[j]=&buf[i];
				}
				if( j==6 )	break;
			}
		}
		narg=j+1;

		/* DEBUG
		for( i=0; i<narg; i++ )
		{
			err_msg(" Arg[%d] = %s\n", i, arg[i]);
		}
		*/

		if( buf[0] == 'A' || buf[0]=='a' )	/* add */
		{/* A [ip] [port] [rootpassword]*/
			if( sysinfo.nRealServer >= ClusterN )
			{
				snprintf(buf,4095,"Server Pool is full(%d)!\n", ClusterN);
				write(connfd, buf, strlen(buf));
			}
			else
			{
				if( narg < 4 )
				{
					snprintf(buf,4095,"HELP - Add a Node\n\tA [ip] [port] [rootpassword]\n");
					write(connfd, buf, strlen(buf));
					continue;
				}
				p=&sysinfo.RSInfo[sysinfo.nRealServer];
				strncpy(p->ip, arg[1], 127);
				strncpy(tmp, arg[2], 5);
				p->port=atoi(tmp);
				strncpy(p->rootpasswd, arg[3], 63);

				p->connects=0;
				p->active=1;
				p->disable=1;
				p->load=0;

				sysinfo.nRealServer++;

				snprintf(buf,4095,"Info: Add Successed, please enable it\n");
				write(connfd, buf, strlen(buf));
			}
		}
		else if( buf[0] == 'D' || buf[0]=='d' )	/* disable */
		{/* D [ID] */
			if( narg < 2 )
			{
				snprintf(buf,4095,"HELP - Disable a Node\n\tD [id]\n");
				write(connfd, buf, strlen(buf));
				continue;
			}

			strncpy(tmp, arg[1], 32);
			j = atoi(tmp);

			if( j >= sysinfo.nRealServer )
			{
				snprintf(buf,4095,"Error: Bad ID\n");
				write(connfd, buf, strlen(buf));
			}
			else
			{
				p=&sysinfo.RSInfo[j];
				if( p->disable == 1 )
				{
					snprintf(buf,4095,"Info: Already disabled\n");
					write(connfd, buf, strlen(buf));
				}
				else
				{
					p->disable=1;
					snprintf(buf,4095,"Info: Disabled\n");
					write(connfd, buf, strlen(buf));
				}
			}
		}
		else if( buf[0] == 'E' || buf[0]=='e' )	/* enable */
		{/* E [ID] */
			if( narg < 2 )
			{
				snprintf(buf,4095,"HELP - Enable a Node\n\tE [id]\n");
				write(connfd, buf, strlen(buf));
				continue;
			}

			strncpy(tmp, arg[1], 32);
			j = atoi(tmp);

			if( j >= sysinfo.nRealServer )
			{
				snprintf(buf,4095,"Error: Bad ID\n");
				write(connfd, buf, strlen(buf));
			}
			else
			{
				p=&sysinfo.RSInfo[j];
				if( p->disable == 0 )
				{
					snprintf(buf,4095,"Info: Already enabled\n");
					write(connfd, buf, strlen(buf));
				}
				else
				{
					p->disable=0;
					snprintf(buf,4095,"Info: enabled\n");
					write(connfd, buf, strlen(buf));
				}
			}
		}
		else if( buf[0] == 'L' || buf[0]=='l' )	/* list */
		{/* L <[ID]> */
			int s,e;

			if( sysinfo.nRealServer==0 )
			{
				snprintf(buf,4095,"No one RealServer was added.\nHELP - List All Node or one Node\n\tL <[ID]>\n");
				write(connfd, buf, strlen(buf));
				continue;
			}

			if( narg < 2 )
			{
				s=0;	e=sysinfo.nRealServer-1;
			}
			else
			{
				strncpy(tmp, arg[1], len);
				j = atoi(tmp);
				if( j >= sysinfo.nRealServer )
				{
					snprintf(buf,4095,"Error: Bad ID\nList All Node :\n");
					write(connfd, buf, strlen(buf));
					e=sysinfo.nRealServer-1;
				}
			}
			for( i=s; i<=e; i++ )
			{
				p=&sysinfo.RSInfo[i];
				buf[0]='\0';
				sprintf( &buf[strlen(buf)], "Id: %2d \t Connect: %d \t Actived: %1d Disabled: %1d Load: %4d \t %s:%u\n",
					i, p->connects, p->active, p->disable, p->load, p->ip, p->port );
				write(connfd, buf, strlen(buf));
			}
		}
		else if( buf[0] == 'M' || buf[0]=='m' )	/* modify */
		{/* M [ID] [ip] [port] [rootpassword] */

			if( narg < 5 )
			{
				snprintf(buf,4095,"HELP - Modify a Node\n\tM [ID] [ip] [port] [rootpassword]\n");
				write(connfd, buf, strlen(buf));
				continue;
			}

			strncpy(tmp, arg[1], len);
			j=atoi(tmp);

			p=&sysinfo.RSInfo[j];
			p->connects=0;
			p->active=1;

			strncpy(p->ip, arg[2], 127);

			strncpy(tmp, arg[3], 5);
			p->port=atoi(tmp);

			p->disable=1;

			strncpy(p->rootpasswd, arg[4], 63);

			p->load=0;

			snprintf(buf,4095,"Info: Modify Successed, please enable it\n");
			write(connfd, buf, strlen(buf));
		}
		else if( buf[0] == 'S' || buf[0]=='s' )	/* set auth server */
		{/* S [ip] [port] */

			if( narg < 3 )
			{
				snprintf(buf,4095,"HELP - Set Auth Server\n\tS [ip] [port]\n");
				write(connfd, buf, strlen(buf));
				snprintf(buf,4095,"====== Current Server Setup ======\n");
				write(connfd, buf, strlen(buf));
				snprintf(buf,4095,"   AuthServer = %s:%d\n",sysinfo.AuthServer, sysinfo.AuthPort);
				write(connfd, buf, strlen(buf));
				if( sysinfo.nRealServer > 0 )
					snprintf(buf,4095," MasterServer = %s:%d\n",sysinfo.RSInfo[sysinfo.MasterServer].ip, sysinfo.RSInfo[sysinfo.MasterServer].port);
				else
					snprintf(buf,4095," MasterServer = ?:?\n");
				write(connfd, buf, strlen(buf));
				snprintf(buf,4095,"   Proxy Port = %d\n", sysinfo.nPort);
				write(connfd, buf, strlen(buf));
				snprintf(buf,4095,"  nRealServer = %d\n", sysinfo.nRealServer);
				write(connfd, buf, strlen(buf));
				snprintf(buf,4095,"  Max Cluster = %d\n", ClusterN);
				write(connfd, buf, strlen(buf));
				snprintf(buf,4095,"    LinkCount = %d\n", sysinfo.linkcount);
				write(connfd, buf, strlen(buf));
				continue;
			}
			strncpy(sysinfo.AuthServer, arg[1], 127);

			strncpy(tmp, arg[2], 5);
			sysinfo.AuthPort=atoi(tmp);

			snprintf(buf,4095,"Info: Auth Server Setup Successed!\n");
			write(connfd, buf, strlen(buf));
		}
		else if( buf[0] == 'Q' || buf[0]=='q' )	/* quit */
		{
			snprintf(buf,4095,"Bye-Bye! Thank you!\n");
			write(connfd, buf, strlen(buf));
			break;
		}
		else
		{
			snprintf(buf,4095,"Error: Bad Command\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - Add a Node\n\tA [ip] [port] [rootpassword]\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - Disable a Node\n\tD [id]\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - Enable a Node\n\tE [id]\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - List All Node or one Node\n\tL <[ID]>\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - Modify a Node\n\tM [ID] [ip] [port] [rootpassword]\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - Set Auth Server\n\tS [ip] [port]\n");
			write(connfd, buf, strlen(buf));
			snprintf(buf,4095,"HELP - Quit\n\tQ\n");
			write(connfd, buf, strlen(buf));
		}
		buf[nRead] = '\0';
	}
}

void *AvgLoadPth(void *p)
{
	int addrlen=sizeof(struct sockaddr_in);
	int socketfd;
	int connfd;
        struct sockaddr_in srv_addr;

	if((socketfd=socket(AF_INET,SOCK_STREAM,0))<0)
        {
                perror("socket");
                exit(1);
        }
	memset(&srv_addr,0,addrlen);
        srv_addr.sin_family=AF_INET;
        srv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
        srv_addr.sin_port=htons(sysinfo.nLoadPort);
	addrlen=sizeof(struct sockaddr_in);
        if(bind(socketfd,(struct sockaddr *)&srv_addr,addrlen)<0)
        {
                perror("bind");
                close(socketfd);
                exit(2);
        }
        listen(socketfd,50);
	for(;;)
	{
		connfd=accept(socketfd,(struct sockaddr *)&srv_addr,&addrlen);
		if( connfd < 0 )
		{
			perror("AvgLoadPth:accept");
		}
		else
		{
			GetLoad(connfd);
			close(connfd);
		}
	}
}

void GetLoad(int connfd)
{
	int rn, datalength;
	char clientip[128];
	char *buf1;
	int *p;
	int i;

	snprintf(clientip,64,"%s",GetSocketIP(connfd));
	
	do {
		rn = 4;
		buf1 = RecvTimeOut( connfd, 5, &rn );
		if( rn == 0 )	free( buf1 );
	}while(rn == 0);
	if( rn != 4 )	return;
	p = (int *)buf1;
	datalength = ntohl(*p); /* 网络字节顺序，转换为本地主机字节方式 */
	free(buf1);
	if( datalength == 0 )	return;
	rn = datalength;
	buf1 = RecvTimeOut( connfd, 5, &rn );
	if( rn < datalength )	return;
	p = (int *)&buf1[1];
	if( (char)buf1[0] != 0x04 )	return;

	for( i=0; i< sysinfo.nRealServer; i++ )
	{
		if( strcmp( sysinfo.RSInfo[i].ip , clientip) == 0 )
		{
			sysinfo.RSInfo[i].load = (int)(atof(&buf1[1])*100.0);
		}
	}
	free(buf1);
}

/* 处理退出信号 kill -HUP*/
void app_quit()
{
	err_msg("Change Run Id to Root ... ");
	seteuid(geteuid());
	setegid(getegid());
	err_msg("Ok\n");

	err_msg("Totol Requests: %d\n", sysinfo.linkcount);
	err_msg("Quit\n");
}
/* 系统初始化 */
void InitSystem()
{
        err_msg("Enter InitSystem()\n");

        /* 初始化sysinfo */
        sysinfo.nPort=3308;
	sysinfo.nCmdPort=8888;
	sysinfo.nLoadPort=8889;
	sysinfo.nRealServer=0;
	sysinfo.MasterServer=0;
	sysinfo.PTHREAD_HEAD=NULL;
	sysinfo.linkcount=0;
	strcpy(sysinfo.AuthServer, "127.0.0.1");
	sysinfo.AuthPort=3307;

/* 
	strcpy(sysinfo.RSInfo[sysinfo.nRealServer].ip, "127.0.0.1");
	sysinfo.RSInfo[sysinfo.nRealServer].port = 3306;
	sysinfo.RSInfo[sysinfo.nRealServer].connects=0;
	sysinfo.RSInfo[sysinfo.nRealServer].active=1;
	sysinfo.RSInfo[sysinfo.nRealServer].disable=0;
	sysinfo.RSInfo[sysinfo.nRealServer].load=0;
	sysinfo.nRealServer++;

	strcpy(sysinfo.RSInfo[sysinfo.nRealServer].ip, "172.24.113.203");
        sysinfo.RSInfo[sysinfo.nRealServer].port = 3306;
        sysinfo.RSInfo[sysinfo.nRealServer].connects=0;
        sysinfo.RSInfo[sysinfo.nRealServer].active=1;
        sysinfo.RSInfo[sysinfo.nRealServer].disable=0;
        sysinfo.RSInfo[sysinfo.nRealServer].load=0;
	sysinfo.nRealServer++;

	strcpy(sysinfo.RSInfo[sysinfo.nRealServer].ip, "172.24.113.204");
        sysinfo.RSInfo[sysinfo.nRealServer].port = 3306;
        sysinfo.RSInfo[sysinfo.nRealServer].connects=0;
        sysinfo.RSInfo[sysinfo.nRealServer].active=1;
        sysinfo.RSInfo[sysinfo.nRealServer].disable=0;
        sysinfo.RSInfo[sysinfo.nRealServer].load=0;
	sysinfo.nRealServer++;
*/

        err_msg("Return from InitSystem()\n");
}

void *thread_main(void *arg)
{
        PTHREAD_INFO *p;

        pthread_detach(pthread_self());
	p=arg;
	p->pid=pthread_self();
        proxy(p);
	close(p->cli_conn);
	err_msg("Thread exit!\n");
	pthread_exit(NULL);
}
/* 获取socket连接的IP */
char * GetSocketIP(int connfd)
{
        struct sockaddr_in peeraddr;
        int addrlen;
        char *str, *ret;
	static char *error="0.0.0.0";

#ifdef DEBUGMODE
	err_msg("Enter GetSocketIP...\n");
#endif
	addrlen=sizeof(struct sockaddr_in);
        if( getpeername(connfd,(struct sockaddr *)&peeraddr,&addrlen)==0 )
		str=inet_ntoa(peeraddr.sin_addr);
	else	str=error;
	ret = (char *)malloc(128);
	strncpy(ret, str, 127);
	ret[127]='\0';
#ifdef DEBUGMODE
	err_msg("Return From GetSocketIP.\n");
#endif
        return(ret);
}
void *Malloc(unsigned int size)
{
        void *p;
        p=malloc(size);
        if(p==NULL)
        {
                perror("malloc");
                exit(1);
        }
        return(p);
}
void *Realloc(void *p,unsigned int size)
{
        p=realloc(p,size);
        if(p==NULL)
        {
                perror("realloc");
                exit(1);
        }
        return(p);
}
void Free(void *p)
{
	free(p);
}
/* 从套接口读取数据，超时监测，遇到特殊字符串结束
	目前endstr不被支持，必须填写NULL */
char *RecvTimeOut(int connfd, int t, int *len)
{
	int status;
	fd_set rset;
	struct timeval timeout;
	char *msg;
	unsigned int msg_len=1025;
	int n;
	int rlen;

	msg = (char *)Malloc(msg_len);
	msg[0] = '\0';

	rlen = *len;

	status=fcntl(connfd,F_GETFL,0);
	fcntl(connfd,F_SETFL,status|O_NONBLOCK);

	FD_ZERO(&rset);
	timeout.tv_sec=t;
	timeout.tv_usec=0;
			
	FD_SET(connfd,&rset);
	if( select(connfd+1,&rset,NULL,NULL,&timeout) < 0 )
	{
		perror("proxy:RecvTimeOut:select");
		*len=0;
	}
	else if( FD_ISSET(connfd,&rset) )
	{
		if( rlen == -1 || rlen > 1024 )	n=recv(connfd,msg,1024,0);
		else				n=recv(connfd,msg,rlen,0);
		if( n==0 )	*len = -1;
		else		*len = n;
		if( n<0 )	err_msg("Can not receive any thing, Maybe server has down!\n");
		else		msg[n]='\0';
	}
	else	*len=0;
	fcntl(connfd,F_SETFL,status);
	return(msg);
}
