/*
	Name: Mysql-Proxy
	Version: 0.0.5
	Author: Computer_xu
	Email: Computer_xu@sina.com
	HomePage: http://www.netsock.org
	LastModify: 2002-08-05 (yyyy-mm-dd)
*/
#include "proxy.h"

extern SYSINFO sysinfo;
int GetConn(char *host, int port);
void CloseAll(PTHREAD_INFO *pi);
int isAlive(int i);
int readpart(int , char *, int , int *);
int rwpipe(int in, int out, int len);
int rwnull(int in);
int Send(int fd, char *buf, int len);
int Recv(int fd, char *buf, int len);
void int3str(unsigned int n, char *buf);
void str3int(unsigned int *n, char *buf);
int ConnAuth(PTHREAD_INFO *pi, char *authbuf);
int GetFirstInfo(int , char *);
int SendAuth(int , char *, char *);
int RecvAuth(int , char *);
void SetNonBlock(int fd);
void SetBlock(int fd);
int GetMinLoad();
pthread_mutex_t getconn_mutex=PTHREAD_MUTEX_INITIALIZER;

extern void err_msg();

void showHex(char *buf, int len)
{
	int i;

	for( i=0; i<len; i++ )
		err_msg("%x ", (char)buf[i]);
	err_msg("\n");
}

void proxy(PTHREAD_INFO *pi)
{
	int i,j;
	char buf[8192];
	int maxfd;
	fd_set rset;
	int nRead;
	unsigned int DataLength;
	char *p, strbuf[128];
	int minload;
	int ok;
	time_t t;

	maxfd = pi->cli_conn;

	SetNonBlock(pi->cli_conn);

	/*��ʼ��Cluster������ */
	for( i=0; i< sysinfo.nRealServer; i++ )
	{
		/* �ж� Node �Ƿ���Ч */
		if( isAlive(i) )
		{
			/* err_msg("Build connection with Node[%d] ...\n", i); */
			/* �������� */
			pi->srv_conn[i] = GetConn(sysinfo.RSInfo[i].ip, sysinfo.RSInfo[i].port);
			if( pi->srv_conn[i] <= 0 )	continue;
			/* ����Ϊ��������ʽ */
			SetNonBlock(pi->srv_conn[i]);
			if( GetFirstInfo(pi->srv_conn[i], pi->ErrBuf) == -1 )
			{
				close(pi->srv_conn[i]);
				pi->srv_conn[i]=-1;
			}
		}
		else	pi->srv_conn[i]=-1;
	}

	/* �����ЧNode�������� */
	j=0;
	for( i=0; i< sysinfo.nRealServer; i++ )
	{
		if( pi->srv_conn[i] > 0 )	j++;
	}
	if( j == 0 )
	{	/* ��ЧNode������Ϊ�� */
		i=0;	p = (char *)&i;
		p[0] = pi->ErrBuf[5];	p[1] = pi->ErrBuf[6];
		err_msg("Warning: All Node was died?!\n");
		buf[3]='\0';
		buf[4]='\xff';			/* Error Flag = 0xFF */
		buf[5]='\xff';	buf[6]='\x07';	/* Errno = 0x07FF */
		sprintf(&buf[7],"All Node was died?! LastDeadNode Errno = %d", i);
		i = strlen(&buf[7])+3;
		int3str(i, buf);
		Send(pi->cli_conn, buf, i+4); /* +4 Head */
		CloseAll(pi);
		return;
	}

	/* ��֤username , passwd */
	if( ConnAuth(pi, buf) == -1 )
	{
		CloseAll(pi);
		return;
	}
	str3int( &nRead, buf );
	memcpy( pi->AuthBuf, buf, nRead+4 );
	strncpy( pi->user, &buf[9], 63 );
	
	err_msg("Auth OK!\n");

	/* ����Node����֤ */
	for( i=0; i< sysinfo.nRealServer; i++ )
	{
		/* �ж� Node �Ƿ���Ч */
		if( pi->srv_conn[i]!=-1 )
		{
			/* ����Node��֤ */
			if( SendAuth(pi->srv_conn[i], pi->AuthBuf, pi->ErrBuf) == -1 )
			{
				err_msg("SendAuth Error on Node[%d]\n", i);
				close(pi->srv_conn[i]);
				pi->srv_conn[i] = -1;
			}
			else if( RecvAuth(pi->srv_conn[i], pi->ErrBuf) == -1 )
			{
				err_msg("RecvAuth Error on Node[%d]\n", i);
				close(pi->srv_conn[i]);
				pi->srv_conn[i] = -1;
			}
			/* ȡ���������� */
			if( maxfd < pi->srv_conn[i] )	maxfd=pi->srv_conn[i];
		}
	}

	/* �����ЧNode�������� */
	j=0;
	for( i=0; i< sysinfo.nRealServer; i++ )
	{
		if( pi->srv_conn[i] > 0 )	j++;
	}
	if( j == 0 )
	{	/* ��ЧNode������Ϊ�� */
		/* bug ���ܷ���Node�Ĵ�����Ϣ��client */
		i=0;	p = (char *)&i;
		p[0] = pi->ErrBuf[5];	p[1] = pi->ErrBuf[6];
		err_msg("Warning: All Node was died?! LastDeadNode Errno = %d\n", i);
		buf[3]='\0';
		buf[4]='\xff';			/* Error Flag = 0xFF */
		buf[5]='\xff';	buf[6]='\x07';	/* Errno = 0x07FF */
		sprintf(&buf[7],"All Node was died?! Connect to RealServer without password mode error! LastDeadNode Errno = %d", i);
		i = strlen(&buf[7])+3;
		int3str(i, buf);
		Send(pi->cli_conn, buf, i+4); /* +4 Head */
		CloseAll(pi);
		return;
	}

	/* ������֤�ɹ�����Ϣ */
	buf[0]=03;	buf[1]=00;	buf[2]=00;	buf[3]=02;
	buf[4]=00;	buf[5]=00;	buf[6]=00;
	Send(pi->cli_conn, buf, 7);

	err_msg("Ready for a Query...\n");

	while(1)
	{
		/* ��ʼ�� */
		FD_ZERO(&rset);
		j=0;
		for( i=0; i< sysinfo.nRealServer; i++ )
		{
			if( pi->srv_conn[i] <= 0 )	continue;
			FD_SET(pi->srv_conn[i],&rset);
			j++;
		}
		if( j == 0 )
		{	/* ��ЧNode������Ϊ�� */
			i=0;	p = (char *)&i;
			p[0] = pi->ErrBuf[5];	p[1] = pi->ErrBuf[6];
			err_msg("Warning: All Node was died?!\n");
			buf[3]='\0';
			buf[4]='\xff';			/* Error Flag = 0xFF */
			buf[5]='\xff';	buf[6]='\x07';	/* Errno = 0x07FF */
			sprintf(&buf[7],"All Node was died?! LastDeadNode Errno = %d", i);
			i = strlen(&buf[7])+3;
			int3str(i, buf);
			Send(pi->cli_conn, buf, i+4); /* +4 Head */
			CloseAll(pi);
			return;
		}

		FD_SET(pi->cli_conn,&rset);

		/* �ȴ���Ϣ */
		ok = select(maxfd+1, &rset, NULL, NULL, NULL);

		/* DEBUG 
		time(&t);
		err_msg("time = %lu\n", t);
		*/

		if( ok > 0 )
		{
			/* ���Ȳ����Ƿ�����Ϣ����RealServer */
			for( i=0; i< sysinfo.nRealServer; i++ )
			{
				if( pi->srv_conn[i] <= 0 )	continue;
				if( FD_ISSET(pi->srv_conn[i],&rset) )
				{	/* ����Ϣ����RealServer */
					if( pi->nSelect == i )
					{	/* ȷ�� �ǽ���SQL����Node���� */
						/* err_msg("<get from RealServer[%d]>",i); */
						nRead = rwpipe( pi->srv_conn[i], pi->cli_conn, -1 );
						/* err_msg("</get from RealServer[%d]>\n",i); */
					}
					else
					{	/* ���ǽ���SQL����Node���� */
						/* �˴�Ϊ�쳣 */
						/* err_msg("<get bad msg from RealServer[%d]>",i); */
						nRead = rwnull( pi->srv_conn[i] );
						/* err_msg("</get bad msg from RealServer[%d]>\n",i); */
						err_msg("Node Id = %d, nRead = %d bytes data write to null\n", i, nRead);
					}

					if( nRead==0 )
					{	/* ��ȡ��0���ȵ���Ϣ���Զ˹ر������� */
						close(pi->srv_conn[i]);
						pi->srv_conn[i] = -1;
					}
				}
			}
			if( FD_ISSET(pi->cli_conn,&rset) )
			{	/* ���Կͻ��˵����� */
				/* err_msg("<get from client>"); */
				nRead = readpart(pi->cli_conn, buf, 1024, &j);	/* j = ʣ��δ���ֽ� */
				/* err_msg("</get from client>\n"); */
				if( nRead < 0 )
				{
					err_msg("Client data error(<5)[%d], close connection!\n", j);
					CloseAll(pi);
					return;
				}
				str3int(&DataLength, buf);
				if( buf[4]=='\x2' )	/* use [database] */
				{
					/* err_msg("... Duplicate it ... [USE]\n"); */
					for( i=0; i< sysinfo.nRealServer; i++ )
					{
						if( pi->srv_conn[i] <= 0 )	continue;
						if( !isAlive(i) )	continue;
						Send(pi->srv_conn[i], buf, nRead);
						pi->nSelect = i;	/* ���MasterServer�������⣬��֤��ѯ���������������У��������д�������Ͷϵ����� */
					}
					while( j )
					{
						if( j > sizeof(buf) )	nRead = Recv(pi->cli_conn, buf, sizeof(buf));
						else			nRead = Recv(pi->cli_conn, buf, j);
						for( i=0; i< sysinfo.nRealServer; i++ )
						{
							if( pi->srv_conn[i] <= 0 )	continue;
							if( !isAlive(i) )	continue;
							Send(pi->srv_conn[i], buf, nRead);
							pi->nSelect = i;	/* ���MasterServer�������⣬��֤��ѯ���������������У��������д�������Ͷϵ����� */
						}
						j -= nRead;
					}

					/* ���MasterServer���Ӷϵ����ᵼ��use�����޷���������������ʹ�� pi->nSelect = i; �������5�У�
					pi->nSelect = sysinfo.MasterServer;
					*/

					continue;
				}
				if( buf[4]=='\x3' )	/* sql query string */
				{
					buf[nRead]='\0';
					p=&buf[5];
					p=strstr(p," ");
					if( p==NULL )	strncpy(strbuf, &buf[5], nRead-5);
					else		strncpy(strbuf, &buf[5], p-&buf[5]);
					
					if( strcasecmp(strbuf, "SELECT")==0 ||
						strcasecmp(strbuf, "SHOW")==0 ||
						strcasecmp(strbuf, "DESC")==0 ||
						strcasecmp(strbuf, "DESCRIBE")==0 )
					{
						/* err_msg("... Cluster it ... [%s%s]\n",strbuf, &buf[5+strlen(strbuf)]); */
						/* may be a bug ����Ҳ��������ѭ�������Ǻ��񲻻ᷢ�� */
						do{	minload=GetMinLoad();	err_msg("GetMinload ");
						}while( pi->srv_conn[minload] < 0 );
						err_msg("\n");
						Send(pi->srv_conn[minload], buf, nRead);
						while( j )
						{
							if( j > sizeof(buf) )	nRead = Recv(pi->cli_conn, buf, sizeof(buf));
							else			nRead = Recv(pi->cli_conn, buf, j);
							Send(pi->srv_conn[minload], buf, nRead);
							j -= nRead;
						}
						pi->nSelect = minload;
						continue;
					}
				}
				/*
				err_msg("nRead=%d Left=%d Op : %d , Msg=%s|", nRead, j, (char)buf[4], &buf[5]);
				showHex(buf,nRead);
				*/
				/* ����д����������RealServer��Ŀǰ�����ã�����mysql֧�ֵ�replicate���Ʊ�֤������������ͬ��
				err_msg("... Duplicate it ... \n");
				for( i=0; i< sysinfo.nRealServer; i++ )
				{
					if( pi->srv_conn[i] <= 0 )	continue;
					if( !isAlive(i) )	continue;
					Send(pi->srv_conn[i], buf, nRead);
				}
				while( j )
				{
					if( j > sizeof(buf) )	nRead = Recv(pi->cli_conn, buf, sizeof(buf));
					else			nRead = Recv(pi->cli_conn, buf, j);
					for( i=0; i< sysinfo.nRealServer; i++ )
					{
						if( pi->srv_conn[i] <= 0 )	continue;
						if( !isAlive(i) )	continue;
						Send(pi->srv_conn[i], buf, nRead);
					}
					j -= nRead;
				}
				*/
				/* д�������͵���RealServer */
				if( pi->srv_conn[sysinfo.MasterServer] < 0 )
				{
					CloseAll(pi);
					return;	/* ��server���Ӷ�ʧ�������˴����� */
				}
				Send(pi->srv_conn[sysinfo.MasterServer], buf, nRead);
				while( j )
				{
					if( j > sizeof(buf) )	nRead = Recv(pi->cli_conn, buf, sizeof(buf));
					else			nRead = Recv(pi->cli_conn, buf, j);
					Send(pi->srv_conn[sysinfo.MasterServer], buf, nRead);
					j -= nRead;
				}
				pi->nSelect = sysinfo.MasterServer;
			}
		}
		else if( ok==0 )
		{
			continue;
		}
		else
		{
			perror("proxy-main:proxy:select");
			err_msg("fds = %d\n", j);
			sleep(5);
		}
	}
}

int GetConn(char *host, int port)
{
	struct sockaddr_in cli_addr;
	int addrlen=sizeof(struct sockaddr_in);
	int authfd;
	struct hostent *he;

	if( host==NULL )	return(-1);

	pthread_mutex_lock(&getconn_mutex);

	if((he=gethostbyname(host)) == NULL)
	{
		perror( "Proxy::GetConn::gethostbyname" ) ;
		err_msg( "Runtime Error at %s : %d", __FILE__, __LINE__);
		pthread_mutex_unlock(&getconn_mutex);
		return(-1);
	}

	if((authfd=socket(AF_INET,SOCK_STREAM,0))<0)
        {
		perror( "Proxy::GetConn::socket" ) ;
		err_msg( "Runtime Error at %s : %d", __FILE__, __LINE__);
		pthread_mutex_unlock(&getconn_mutex);
		return(-1);
        }
        memset(&cli_addr,0,addrlen);
	cli_addr.sin_family=AF_INET;
        cli_addr.sin_addr = *((struct in_addr *)he->h_addr);
        cli_addr.sin_port=htons(port);

	pthread_mutex_unlock(&getconn_mutex);

	if( connect( authfd, (struct sockaddr *) &cli_addr, addrlen) < 0 )
	{
		perror( "Proxy::GetConn::connect" ) ;
		err_msg( "Runtime Error at %s : %d", __FILE__, __LINE__);
		return(-1);
	}

	return(authfd);
}

void CloseAll(PTHREAD_INFO *pi)
{
	int i;

	close(pi->cli_conn);
	for( i=0; i< sysinfo.nRealServer; i++ )
		close(pi->srv_conn[i]);
}
int isAlive(int i)
{
	if( sysinfo.RSInfo[i].active == 1 && sysinfo.RSInfo[i].disable==0 )
	{
		return(1);
	}
	else
	{
		return(0);
	}
}
int readpart(int fd, char *buf, int buflen, int *left)
{
	int n;
	int length;
	int nRead;

	n = Recv( fd, buf, 4 );
	if( n!=4 )
	{
		err_msg("readpart::Head Error[%d]!\n", n);
		*left=n;
		return(-1);
	}
	str3int(&length, buf);
	buf+=4;	buflen-=4;
	if( length <= buflen )	nRead=length;
	else			nRead=buflen;
	n = Recv( fd, buf, nRead );
	*left=length-n;
	return(n+4);
}
int rwpipe(int in, int out, int len)
{
	int nRead=0;
	char buf[1025];
	int n;
	int m=0;
	int flag=0;

	while(1)
	{
		/* DEBUG 
		err_msg("flag = %d, m= %d\n", flag,m);
		*/
		if( m )
		{
			if( m > 1024 )	n = Recv( in, buf, 1024 );
			else		n = Recv( in, buf, m );
			m-=n;
		}
		else	if( len == -1 )
		{
			n = readpart(in, buf, 1024, &m);
			if( n == -1 )	return(nRead+m);
			/*	showHex(buf,n);	*/

			if( buf[0]=='\x01' && buf[1]=='\x00' &&
				buf[2]=='\x00' && buf[3]!='\x00' &&
				buf[4]=='\xfe' )	flag=2;
			else	if( flag==0 )		flag=2;
		}
		else	if( len > 1024 )
		{
			n = Recv( in, buf, 1024 );
		}
		else	n = Recv( in, buf, len );
			
		if( n<=0 )
		{
			/* DEBUG 
			err_msg("\n");
			*/
			return( nRead );
		}
		else
		{
			/* DEBUG 
			buf[n]='\0';
			err_msg("proxy::rwpipe::buf = %s", buf);
			*/
			if( out > 0 )	Send( out, buf, n );
			nRead+=n;
			if( len != -1 )	len-=n;
			if( len == 0 )	return( nRead );
			if( len == -1 && flag==2 && m==0 )	return( nRead );
		}
	}
}
int rwnull(int in)
{
	return(rwpipe(in, 0, -1));
}

int Recv(int fd, char *buf, int len)
{
	struct timeval timeout;
	fd_set rset;
	int nRead=0;
	int maxfdp;
	int n;
	int ok;

	if( fd < 0 )	return(-1);
	if( len==0 )	return(0);
	maxfdp=fd;

	while(1)
	{
		timeout.tv_sec=5;
		timeout.tv_usec=0; /* 500000 = 0.5 second */

		FD_ZERO(&rset);
		FD_SET(fd, &rset);

		if( (ok = select(maxfdp+1, &rset, NULL, NULL, &timeout)) < 0 )
		{
			perror("proxy-main:Recv:select");
			return( nRead );
		}
		else
		{
			if( ok == 0 )
			{
				err_msg("Recv:Timeout[%d]\n", nRead);
				return( nRead );
			}
			if( FD_ISSET(fd, &rset) )
			{
				n = recv( fd, &buf[nRead], len-nRead, 0 );
				if( n<0 )
				{
					perror("recv");
					return( nRead );
				}
				else if( n==0 )
				{
					err_msg("recv:0 byte\n");
					return( nRead );
				}
				else
				{
					nRead+=n;
					/* DEBUG
					err_msg(" len = %d, nRead = %d\n", len, nRead );
					*/
					if( (len-nRead) == 0 )	return( nRead );
				}
			}
		}
	}
}

int Send(int fd, char *buf, int len)
{
	struct timeval timeout;
	fd_set wset;
	int nWrite=0;
	int maxfdp;
	int ok, n;

	if( fd < 0 )	return(-1);

	if( len==0 )	return(0);

	maxfdp=fd;

	while(1)
	{
		timeout.tv_sec=5;
		timeout.tv_usec=0;

		FD_ZERO(&wset);
		FD_SET(fd, &wset);

		if( (ok = select(maxfdp+1, NULL, &wset, NULL, &timeout)) < 0 )
		{
			perror("proxy-main:Send:select");
			return( nWrite );
		}
		else
		{
			if( ok == 0 )
			{
				err_msg("Send:Timeout\n");
				return( nWrite );
			}
			if( FD_ISSET(fd, &wset) )
			{
				n = send( fd, &buf[nWrite], len-nWrite, 0 );
				if( n<0 )
				{
					perror("send");
					return( nWrite );
				}
				else
				{
					nWrite += n;
					if( nWrite == len )	return( nWrite );
				}
			}
		}
	}
}
void int3str(unsigned int n, char *buf)
{
	char *p;

	p=(char *)&n;
	buf[0]=p[0];
	buf[1]=p[1];
	buf[2]=p[2];
}

void str3int(unsigned int *n, char *buf)
{
	char buf1[4];
	unsigned int *p;

	buf1[0]=buf[0];
	buf1[1]=buf[1];
	buf1[2]=buf[2];
	buf1[3]=0;

	p=(int *)buf1;
	*n=*p;
}
int ConnAuth(PTHREAD_INFO *pi, char *authbuf)
{
	int fd;
	int nRead, nWrite;
	char buf[1024], buf1[1024];
	unsigned int datalen;
	int off_username, off_password, off_db;

	/* err_msg("Enter ConnAuth [%s:%d]... \n", sysinfo.AuthServer, sysinfo.AuthPort); */

	fd = GetConn(sysinfo.AuthServer, sysinfo.AuthPort);
	if( fd <= 0 )
	{
		err_msg("Please give AuthServer IP & Port!\n");
		err_msg("System halt!\n");
		exit(1);
	}
	SetNonBlock(fd);

	/* ���ݰ汾��Ϣ Server -> Client */
	datalen = Recv(fd, buf, 4);
	if( datalen < 4 )	{	close(fd);	return(-1);	}
	str3int(&datalen, buf);
	Send(pi->cli_conn, buf, 4);
	nRead = rwpipe(fd, pi->cli_conn, datalen);
	/* ���ܵ�½��Ϣ Client -> Proxy */
	datalen = Recv(pi->cli_conn, buf, 4);
	if( datalen < 4 )	{	close(fd);	return(-1);	}
	str3int(&datalen, buf);
	nRead = Recv(pi->cli_conn, &buf[4], datalen);

	if( datalen == nRead )
	{
		/* ������֤ Proxy -> Server */
		nRead+=4;
		nWrite = Send(fd, buf, nRead);
		if( nWrite == nRead )
		{
			/* ��ȡ��֤��� Server -> Proxy */
			datalen = Recv(fd, buf1, 4);
			if( datalen < 4 )	{	close(fd);	return(-1);	}
			str3int(&datalen, buf1);
			nRead = Recv(fd, &buf1[4], datalen);
			if( buf1[0]==03 && buf1[1]==00 && buf1[2]==00 && buf1[3]==02 && 
				buf1[4]==00 && buf1[5]==00 && buf1[6]==00 )
			{	/* ��֤�ɹ���������֤���ݰ� */

				str3int(&datalen, buf);
				/* username'\0'password'\0'dbname */

				/********* Bugs 
				if( buf[datalen+4-1]!='\0' && buf[datalen+4-8-1]=='\0' )
				{
					nWrite -= 8;
					datalen -= 8;
				}
				**********/
				off_username = 9;
				off_password = off_username + strlen( &buf[off_username] ) + 1;
				off_db = off_password + strlen( &buf[off_password] ) + 1;
				if( strlen( &buf[off_password] ) > 0 )
				{	/* clear password data */
					memcpy( &buf[off_password], &buf[off_db - 1], nWrite - off_db + 1 );
					/* if have password then delete 8 bytes password */
					nWrite -= 8;
					datalen -= 8;
				}
				int3str(datalen, buf);

				memcpy(authbuf, buf, nWrite);

				close( fd );
				return( 0 );
			}
			/* ��֤ʧ�ܣ����ش�����Ϣ Proxy -> Client */
			nWrite = Send(pi->cli_conn, buf1, nRead+4);
		}
	}

	close(fd);
	return( -1 );
}
int GetFirstInfo(int in, char *Ebuf)
{
	int datalen;
	char rbuf[4096];
	int j;

	/* �� Node �汾, SessionID �ȣ�Ҳ�п����Ǵ�����Ϣ */
	datalen = Recv(in, rbuf, 4);
	if( datalen < 4 )	return(-1);
	str3int(&datalen, rbuf);
	j = Recv(in, &rbuf[4], datalen);
	j += 4;
	if( j>5 && rbuf[4]=='\xff' )
	{	/* �Ǵ�����Ϣ */
		memcpy(Ebuf, rbuf, (j>511)?511:j);
		return(-1);
	}
	return(0);
}
int SendAuth(int out, char *buf, char *Ebuf)
{
	int len;
	int i;

	str3int(&len, buf);

	len+=4;
	i = Send(out, buf, len);
	if( i == len )	return(0);
	else		return(-1);
}
int RecvAuth(int in, char *retbuf)
{
	int datalen;
	int i;
	char buf[4096];

	datalen = Recv(in, buf, 4);
	if( datalen < 4 )	return(-1);
	str3int(&datalen, buf);
	i = Recv(in, &buf[4], datalen);

	if( i == datalen )
	{
		if( buf[0]==03 && buf[1]==00 && buf[2]==00 && buf[3]==02 && 
				buf[4]==00 && buf[5]==00 && buf[6]==00 )
		{	/* Node ��֤�ɹ� */
			return(0);
		}
	}
	i+=4;
	memcpy(retbuf, buf, (i>511)?511:i);
	return(-1);
}
void SetNonBlock(int fd)
{
	int status;

	status=fcntl(fd,F_GETFL,0);
	fcntl(fd,F_SETFL,status|O_NONBLOCK);
}
void SetBlock(int fd)
{
	int status;

	status=fcntl(fd,F_GETFL,0);
	if( (status & O_NONBLOCK) == O_NONBLOCK )
		fcntl(fd,F_SETFL,status^O_NONBLOCK);
}
int GetMinLoad()
{
	int i;
	int min, mini=-1;
	static int n;

	i=n;
	
	do
	{
		if( isAlive(i) )
		{
			if( (mini == -1) || (min > sysinfo.RSInfo[i].load) || (min == sysinfo.RSInfo[i].load && mini==n) )
			{
				min = sysinfo.RSInfo[i].load;
				mini = i;
			}
		}
		i++;	if( i==sysinfo.nRealServer )	i=0;
	}while(i!=n);
	if( mini != -1 )	n=mini;
	return(mini);
}
