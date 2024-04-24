;/*
sc amisearch.c link lib lib:httpget.lib lib:funcs.lib lib:sc.lib lib:amiga.lib INCLUDEDIR=NETINCLUDE: to amisearch 
delete #?.o #?.lnk
quit
*/
/*
    Amisearch v1.0 (29.03.2024)
    Coded by emarti, Murat Ozdemir
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <httpgetlib.h>
#include <proto/dos.h>
#include <funcs.h>

#include <unistd.h>
#include <signal.h>
#include <time.h>

#define SEARCHHTML  "RAM:T/search.html"
#define SEARCHFILE  "RAM:T/search.dat"
#define SEARCHURL   "m68k.aminet.net/search?arch[]=m68k-amigaos&arch[]=generic&query="
#define RECENT      "m68k.aminet.net/search?o_date=newer&date=%s&arch[]=m68k-amigaos&arch[]=generic&sort=date&ord=DESC"

#define MATCHING    "matching"
#define LIGHT       "lightrow"
#define DARK        "darkrow"

#define BUFFER      0x0400
UBYTE *vers = "\0$VER: amisearch 1.0 (29.03.2024) emarti, Murat Ozdemir\r\n\0";

BPTR file, htmlfile;
char **arrline;
char filename[50], htmlfilename[50];
int i, sayfa, si;
char url[BUFFER/4];
char urlWithStart[BUFFER/4];
UBYTE htmlline[BUFFER];
UBYTE c;
int packageCount;
char temp[BUFFER/2];
char desc[BUFFER/2];
int packageNo=1;

void removeRecurringChars(char* str);
void removeTags(char *str);
void trimle(char *line, BOOL endofline);
int getPackageCount(char *str);
int searchPageDownloadCount(int packageCount);
int posInString(char *str, char c);
int countInString(char *str, char c);
void INThandler(int sig); // CTRL-C
void htmllineToData(void);
char* leftTrim(char *str);

int main(int argc, char* argv[]) {
    
    char sure;
    time_t t;
    struct tm *dt;
    char strdate[0xff];
    char opt[3];
    
    
    signal(SIGINT, INThandler);
    
    if(argc<2){ printf("This program is part of amiget\n"); return -9;}
    
    if(strcmp(argv[1], "**recent**")==0)
    {
        time(&t);
        dt=localtime(&t);
        sprintf(strdate, "%6d", (1900+dt->tm_year)*10000+(dt->tm_mon)*100+dt->tm_mday); // last 30 days
        sprintf(url, RECENT, strdate);
    }
    else
    {
        // searching from aminet and download html pages
        strcpy(url, SEARCHURL);
        for(i=2;i<argc;i++)
        {
            strcat(url, argv[i]);
            if (i!=argc-1) strcat(url, "+");
        }
        //strcat(url, "&start=0");
        strcpy(opt, argv[1]);
        switch (opt[0])
        {
            case 'n': strcat(url, "&sort=name");break;
            case 'p': strcat(url, "&sort=path");break;
            case 'd': strcat(url, "&sort=date");break;
            case 's': strcat(url, "&sort=bytes");break;
            default: break;
        }
        
        switch (opt[1])
        {
            case 'a': strcat(url, "&ord=no");break;
            case 'z': strcat(url, "&ord=DESC");break;
            default: break;
        }
    }
    
    printf("\033[1;31;40mSearching\033[0m from m68k.aminet.net...\n");
    
    
    if(isConnected())
    {
        httpget(url, SEARCHHTML);  
    }
    else 
    {
        printf("Please, check your internet connectivity.\n");
        return -1;
    }
    
    strcpy(filename, SEARCHFILE);
    strcpy(htmlfilename, SEARCHHTML);
    
    
    // html->data
    htmlfile = Open(htmlfilename, MODE_OLDFILE);
    if (htmlfile == NULL) {
        printf("HTML file not found\n");
        return -2;
    }
    
    file = Open(filename, MODE_NEWFILE);
    if(file==NULL) {Close(htmlfile); return -3;}
    
    while(FGets(htmlfile, htmlline, BUFFER) != NULL)
    {
        
        if(strstr(htmlline, MATCHING) != NULL) {
            trimle(htmlline, TRUE);
            packageCount = getPackageCount(htmlline);
            break;
        }
    }
    
    printf("\033[1;31;40mFound\033[0m %d package%s\n\n", packageCount, (packageCount>1)?"s":"");
    if (packageCount == 0) {Close(htmlfile); Close(file); return -4;}
    
    if (packageCount>300) // packageCount>300 => download?
    {
        printf("There are many search results (>300). \033[1;31;40mContinue the process?\033[0m [Y/n]");
        sure = getchar();
     
        if (sure == 'n' || sure == 'N')
        {
            Close(htmlfile); Close(file); return -100;
        }
    }
    
    arrline=(char**)malloc(BUFFER/2);
    
    htmllineToData();
    
    Close(htmlfile);
    
    
    
    sayfa=searchPageDownloadCount(packageCount);
    if (sayfa>2) printf("Please wait while processing...\n\n");
    
    for(si=1;si<sayfa;si++)
    {
        
        sprintf(urlWithStart, "%s&start=%d", url, si*50);
        
        httpget(urlWithStart, SEARCHHTML);
        
        htmlfile = Open(htmlfilename, MODE_OLDFILE);
        if (htmlfile == NULL) {
            printf("HTML file not found\n");
            Close(file);
            free(arrline);
            arrline=NULL;
            return -2;
        }
        
        htmllineToData();
        Close(htmlfile);
        printf("\r\b\b\r\033[1;31;40mProcessing\033[0m page %d of %d (%d%)\n",si+1, sayfa, (100*(si+1))/sayfa);
        
    }
    
    free(arrline);
    arrline=NULL;
    Close(file);
    DeleteFile(SEARCHHTML);
    
    return packageCount;
}

void removeRecurringChars(char* str)
{
   char *token;
   char r[BUFFER];
   const char s[2] = "|";
   token = strtok(str, s);
   strcpy(r,"");
   while( token != NULL ) {
      //printf( "%s|", token );
      strcat(r,token);
      strcat(r, s);
      token = strtok(NULL, s);
   }
   strcpy(str,r);
}

void removeTags(char *str)
{
    char *p = str;
    int tag = 0;
    
    while (*str) {
        if (*str == '<') tag = 1;        
        if (!tag) *p++ = *str;      
        if (*str == '>') {
        	tag = 0; 
        	*p++ = '|'; 
        } 
        str++;
    }

    *p = '\0';
}

void trimle(char *line, BOOL endofline)
{
    int lastChars = 14;
    if (!endofline) lastChars=1;
    removeTags(line);
    removeRecurringChars(line);
    line[strlen(line)-lastChars]='\0';
}

// 'Found XXX matching package'
int getPackageCount(char *str)
{
    char *token;
    token = strtok(str, " ");
    token = strtok(NULL, " ");
    return atoi(token);
}

int searchPageDownloadCount(int packageCount)
{
    int kalan, result;
    result = packageCount / 50;
    kalan = packageCount % 50;
    if(kalan>0) result++;
    return result;   
}

int posInString(char *str, char c)
{
    int p=0;
    for(;p<strlen(str);p++)
    {
        if(str[p]==c) break;
    }
    
    return p;
}

int countInString(char *str, char c)
{
    int count=0, ii;
    for(ii=0;ii<strlen(str);ii++)
    {
        if(str[ii]==c) 
            count++;
    }
    return count;
}

char* leftTrim(char *str)
{
    while(isspace(*str)) str++;
    return str;
}

// when hit CTRL-C
void  INThandler(int sig)
{
     char  ch;
     signal(sig, SIG_IGN);
     
     printf("When you want to break the process with CTRL-C,\n");
     printf("this application will not work properly if you try\n");
     printf("to run it again. You may need to reboot the system.\n\n");
     printf("\033[1;31;40mAre you sure you want to exit?\033[0m [Y/n]\n");
     ch = getchar();
     
     if (ch == 'y' || ch == 'Y')
     {
         if (htmlfile) Close(htmlfile);
         if (file) Close(file);
         free(arrline);
         exit(-99);
     }     
     else
         signal(SIGINT, INThandler);
}

void htmllineToData(void)
{
    int np,par;
    while(FGets(htmlfile, htmlline, BUFFER) != NULL)   
    {    
        if((strstr(htmlline, DARK) != NULL)||(strstr(htmlline, LIGHT) != NULL))
        {
            if (htmlline[strlen(htmlline)-1]==0x0a) 
            {
                trimle(htmlline, TRUE);            
            }
            else
            {
                trimle(htmlline, FALSE);
                
                
                i=strlen(htmlline)-1;
                while(isdigit(htmlline[i])==0)
                {
                    htmlline[i]='<';
                    i--;
                }
                htmlline[i+1]='|';
                
                
                while( (c=FGetC(htmlfile)) != 0x0a )
                {
                    strncat(htmlline, &c, 1);
                }
                
                
                
                i=posInString(htmlline,'<');
                if(i > (posInString(htmlline,'>')) ) 
                {
                    while(htmlline[i]!='|')
                    {
                        htmlline[i]=' ';
                        i--;
                    }                    
                }
                
                trimle(htmlline, TRUE);
                c='|';
                strncat(htmlline, &c, 1);
                
                if (countInString(htmlline, '|')!=8)
                {
                    i=strlen(htmlline)-2;
                    strcat(htmlline, "*|");
                    while (htmlline[i]!='|') 
                    {
                        htmlline[i+2]=htmlline[i];
                        i--;
                    }
                    htmlline[i+1]=' ';
                    htmlline[i+2]='|';
                }
                
            }
            
            par=countInString(htmlline, '|');
            arrline = getArray(htmlline, "|", par);
            
            strcpy(desc, "");
            np=0;
            while(np<=par-8)
            {
                strcat(desc, arrline[7+np]);
                np++;
            }
            
            sprintf(temp, "%6d %30s %12s %6s %10s  %s\n",packageNo, arrline[0],arrline[2],arrline[4],arrline[5],leftTrim(desc));
            FPuts(file, temp); 
            packageNo++;

        } 
    }
}
