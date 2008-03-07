#include <time.h>
#include <sys/timeb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <netdb.h>

#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <netinet/in.h>

#include <signal.h>
#include <sys/wait.h>

#include <fcntl.h>

#ifndef __linux__
#include <sys/loadavg.h>
#endif

void HexPrint(char *buf, int len)
{
	int i;
	char m;
	int h,l;

	for( i=0; i<len; i++ )
	{
		m = buf[i];
		h = m&0xf0;	h>>=4;
		l = m&0x0f;
		printf("%1x%1x ",h,l );
	}
	printf("\n");
}

int Connect(char *host, int port)
{
	int connfd;
	struct sockaddr_in cli_addr;
	int addrlen=sizeof(struct sockaddr_in);
	struct hostent *he;

	if( ( he=gethostbyname(host) ) == NULL )
	{
		perror( "gethostbyname" ) ;
		return(-1);
	}

	if((connfd=socket(AF_INET,SOCK_STREAM,0))<0)
	{
		perror("socket");
		return(-1);
	}
	memset(&cli_addr,0,addrlen);
	cli_addr.sin_family=AF_INET;
	cli_addr.sin_addr = *((struct in_addr *)he->h_addr);
	cli_addr.sin_port=htons(port);

	if( connect( connfd, (struct sockaddr *) &cli_addr, addrlen) < 0 )
	{
		perror("connect");
		return(-1);
	}
	return(connfd);
}
char *Recv(int connfd, int t, int *len)
{
	int status;
	fd_set rset;
	struct timeval timeout;
	char *msg;
	unsigned int msg_len=8192;
	int n;
	int rlen;
	int offset=0;

	rlen = *len;

	if( rlen > 0 )	msg_len=rlen;

	msg = (char *)Malloc(msg_len+1);
	msg[0] = '\0';

	status=fcntl(connfd,F_GETFL,0);
	fcntl(connfd,F_SETFL,status|O_NONBLOCK);

	FD_ZERO(&rset);
	timeout.tv_sec=t;
	timeout.tv_usec=0;

	while(1)
	{			
		FD_SET(connfd,&rset);
		if( select(connfd+1,&rset,NULL,NULL,&timeout) < 0 )
		{
			perror("select");
			*len=0;
		}
		else if( FD_ISSET(connfd,&rset) )
		{
			n=recv(connfd,&msg[offset],msg_len,0);
			if( n >= 0 )
			{
				offset += n;
				msg_len -= n;
				if( n==0 || msg_len == 0 )	break;
			}
		}
	}
	msg[offset]='\0';
	*len = offset;
	fcntl(connfd,F_SETFL,status);
	return(msg);
}

double GetLoadAvg()
{
	double loadavg[3];
#ifdef _SYS_LOADAVG_H
	getloadavg(loadavg, 3);
#else
	FILE *fp;
	char buf[255], *buf1;
	int n;

	fp = fopen("/proc/loadavg","r");
	if( fp == NULL )
	{
		perror("fopen");
		exit(1);
	}
	n=fread(buf, 1, 200, fp);
	if( n==-1 )
	{
		perror("fread");
		exit(1);
	}
	fclose(fp);
	buf[n]='\0';
	buf1 = strchr(buf, ' ');
	printf("%s\n",buf);
	if(buf1 != NULL)	*buf1 = '\0';
	loadavg[0] = atof(buf);
#endif
	return(loadavg[0]);
}

int main(int argc, char *argv[])
{
	int connfd, connfd1;
	time_t t3;
	char buf1[4096], buf2[16];
	double v;
	int *p;
	int n, ok;

	if( argc < 3 )
	{
		printf("Usage: client [server ip] [server port]\n");
		exit(0);
	}

	printf("Client running...\n");
	signal(SIGHUP,SIG_IGN);
	signal(SIGPIPE,SIG_IGN);

	buf1[0]='\0';
	buf1[1]='\0';
	buf1[2]='\0';
	buf1[3]='\0';
	/* getloadavg() */
	buf1[4]='\x4';

	p = (int *)buf1;

	while(1)
	{

		connfd = Connect(argv[1], atoi(argv[2]));
		if( connfd == -1 )	exit(1);
		printf("Connect to server ok!\n");
		while(1)
		{
			time(&t3);

			v = GetLoadAvg();
			snprintf(&buf1[4+1],10,"%f", v);

			printf(&buf1[4+1]);
			*p = htonl(1+strlen(&buf1[4+1]));
			HexPrint(buf1, 4+1+strlen(&buf1[4+1]));
			ok = send( connfd, buf1, 4+1+strlen(&buf1[4+1]), 0 );
			if( ok < 0 )
			{
				perror("send");
				break;
			}

			sleep ( 300 - ( t3 % 300 ) );
		}
		close(connfd);
	}
	printf("Client quit!\n");
}


