#ifdef __BASE__

#include <stdio.h>
#include <string.h>

/* Split 结构: 用于实现Perl split功能 */
typedef struct splitlink
{
	char *msg;
	struct splitlink *next;
} SPLIT;

void *Malloc(unsigned int);
void *Realloc(void *, unsigned int);
void Free(void *);
FILE *Fopen(char *, char *);
SPLIT * split(char *, char *);
SPLIT * free_split(SPLIT *);
char * ExChange(char *, char *, char *);
void del_ch(char *, char);
int StrCmp(const char *, const char *);
int StrnCmp(const char *, const char *, unsigned int );
unsigned int Strlen(const char *s);

#endif