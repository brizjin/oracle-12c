/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/fio.c $
 *  $Author: Alexey $
 *  $Revision: 15082 $
 *  $Date:: 2012-03-06 17:34:34 #$
 */

#include "fio.h"

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>

#ifdef VC60
# include <direct.h>
#else
# include <dirent.h>
#endif

#ifdef WIN32COMMON
# include <process.h>
# include <io.h>
# include <sys\types.h>
# include <sys\stat.h>
# ifdef VC60
#   include "dir.h"
#   define get_dir_handle(fdir) fdir->handle
# else
#   include <dir.h>
#   define get_dir_handle(fdir) fdir->_d_hdir
# endif
# define S_IRGRP S_IREAD
# define S_IWGRP S_IWRITE
# define S_IXGRP S_IEXEC
# define S_IROTH S_IREAD
# define S_IWOTH S_IWRITE
# define S_IXOTH S_IEXEC
# define mkdir(name,md) mkdir(name)
# define strcasecmp(s1,s2) _stricmp(s1,s2)
# define NULLDEVICE "nul"
# define SLASH '\\'
# define SLASHSTR  "\\"
# define PARENTDIR "\\.."
# define MASKSTR "\\\\\\"
# define ftruncate(h,sz) _chsize(h,sz)
# define ADD_FILE_ATTRS
  extern int _fmode;
#else
# include <unistd.h>
# include <pwd.h>
# include <grp.h>
# include <sys/types.h>
# include <sys/stat.h>
# define NULLDEVICE "/dev/null"
# define SLASH '/'
# define SLASHSTR  "/"
# define PARENTDIR "/.."
# define MASKSTR "///"
# ifdef VMS
#   define get_dir_handle(fdir) ++dhandle
#   define ADD_FILE_ATTRS /*,"rfm=stm","rat=none","ctx=bin","ctx=stm"*/
# else
#   ifdef linux
#     define get_dir_handle(fdir) dirfd(fdir)
#   else
#     define get_dir_handle(fdir) fdir->d_fd
#   endif
#   define ADD_FILE_ATTRS
# endif
#endif

#ifndef LONG_TO_STR
# define LONG_TO_STR "%ld"
#endif

#ifndef PATH_MAX
# define PATH_MAX 400
#endif

#define SEPARATOR ";"
#define MASKLEN 3

#define SEARCHALL '*'
#define SEARCHONE '?'
#define SEARCHARG '%'
#define DRIVETAG  ':'
#define SELFDIR   '.'

#define ROOT_DIR "FIO_ROOT_DIR"
#define BASE_DIR "FIO_BASE_DIR"
#define EXEC_CMD "FIO_EXEC_CMD"
#define CHECKDIR "<CHECK_ROOT>"

#define FIO_HANDLE_ERR -6501
#define FIO_HANDLE_MSG "Invalid pointer-handle reference"
#define BUF_OVERFLOW_ERR -6502
#define BUF_OVERFLOW_MSG "String buffer is too small"
#define FIO_ACCESS_ERR -6512
#define FIO_ACCESS_MSG "FIO Access denied"

#define OCI_IND_NOTNULL 0
#define OCI_IND_NULL -1

extern int errno;

static char *envs[100];
static long  spid;
static int   debug_level,envcnt,sortflag,chkflag,hlog,uid,gid,caseflag,dhandle;
static char  ouid[100];
static char  sbuf[100];
static char  fbuf[2100];

typedef struct FIO_DIR
{
	int	   handle;
	int	   flag;
	long   counter;
	DIR	  *dir;
	char  *mask,*name;
} FIODIR;

typedef struct FIO_FILE
{
	int	   handle;
	FILE  *f;
	char  *name;
} FIOFILE;

void set_features_default(void);

void open_log( FILE    **foutput )
{
  // *foutput = fopen( "check_err.log", "a" );
  *foutput = NULL;
}
void close_log( FILE    *foutput )
{
  if ( foutput ) fclose( foutput );
}

void write_log( int dlevel, char *typ, char *fname, char *msg, char *cod,
				int code,   char *msg1,char *msg2 , char *msg3 )
{
  if (dlevel<debug_level) {
	time_t tim = time(NULL);
	struct tm *dat = localtime((time_t *)&tim);
    sprintf(fbuf,"FIO %s %02d.%02d.%04d %02d:%02d:%02d %d %s %s, %s %d",typ,
		dat->tm_mday,dat->tm_mon+1,dat->tm_year+1900,
		dat->tm_hour,dat->tm_min,dat->tm_sec,
        spid,fname,msg,cod,code);
    if (msg1) { strcat(fbuf,", "); strcat(fbuf,msg1); }
    if (msg2) { strcat(fbuf,", "); strcat(fbuf,msg2); }
    if (msg3) { strcat(fbuf,", "); strcat(fbuf,msg3); }
    strcat(fbuf,"\n");
    write(hlog,fbuf,strlen(fbuf));
  }
}

void clear_ptr( void )
{ char *str;
  set_features_default();
  freopen(NULLDEVICE,"a",stdout);
  freopen(NULLDEVICE,"a",stderr);
  if (hlog>0) close(hlog);
  spid=0; debug_level=0; chkflag=0; hlog=0; uid=0; gid=0; caseflag=0;
  while ((envcnt-=1)>=0)
	if (envs[envcnt]) {
	  str=strchr(envs[envcnt],'=');
	  if (str) {
        str[1] = 0;
		putenv(envs[envcnt]);
	  }
	  free(envs[envcnt]);
	  envs[envcnt]=NULL;
	}
  envcnt=0;
  dhandle=0;
}

char *l_toa (long l, int offs)
{
  sprintf((char *)&sbuf+offs,LONG_TO_STR,l);
  return (char *)&sbuf+offs;
}

char *errmsg( int err )
{
  switch (err) {
    case FIO_ACCESS_ERR:
      return FIO_ACCESS_MSG;
    case BUF_OVERFLOW_ERR:
  	  return BUF_OVERFLOW_MSG;
    case FIO_HANDLE_ERR:
	  return FIO_HANDLE_MSG;
	default:
	  return strerror(-err);
  }
}

long DLLEXPORT fio_init(
    char   *asid,     short   asid_ind,
	char   *logname,  short   logname_ind,
	char   *rootdir,  short   rootdir_ind,
	char   *basedir,  short   basedir_ind,
	char   *execcmd,  short   execcmd_ind,
	int     dlevel,   short   dlevel_ind,
	short  *ret_ind
			 )
{
  FILE   *foutput;
  FILE   *ff;
  int     l,cf;
  int     d = 0;
  long    p;

  clear_ptr();
  open_log( &foutput );
  if ( (dlevel_ind!=(short)OCI_IND_NULL) ) d=dlevel;
  if (d<0){ d=-d-1; cf=1; } else cf=0;
  if ( (asid_ind==(short)OCI_IND_NULL)||(strlen(asid)==0) ) l=-1;
  else
    if ( (logname_ind==(short)OCI_IND_NULL)||(strlen(logname)==0) ) l=-2;
	else {
      l = open(logname,O_CREAT|O_APPEND|O_WRONLY,S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
      if (l<0) l=-2;
      else {
        hlog = l; l = 0;
        ff = freopen(logname,"a",stdout);
        if (ff) ff = freopen(logname,"a",stderr);
        if (ff==NULL) l=-2;
      }
	  if (foutput) fprintf(foutput,"Init Out: %s, error: %d, %s\n",logname,errno,strerror(errno));
	}
  if ( (l==-2)&&(d==0) ) {
    freopen(NULLDEVICE,"a",stdout);
    freopen(NULLDEVICE,"a",stderr);
    if (hlog>0) close(hlog);
    l = 0; hlog = 0;
  }
  if (l==0)
	if ( (rootdir_ind==(short)OCI_IND_NULL)||(strlen(rootdir)<2)) l=-3;
	else {
	  l = chdir(rootdir);
	  if (l!=0) l=-3;
	  if (foutput) fprintf(foutput,"Init Dir: %s, error: %d, %s\n",rootdir,errno,strerror(errno));
	}
  if (l==0)
	if ( (basedir_ind==(short)OCI_IND_NULL)||(strlen(basedir)==0) ) l=-4;
	else if ( (execcmd_ind==(short)OCI_IND_NULL)||(strlen(execcmd)==0) ) l=-5;
	else { char *str,*bdir;
      envcnt = 2;
	  str = (char *) malloc (strlen(rootdir)+15);
      strcpy(str,ROOT_DIR);
      strcat(str,"=");
	  strcat(str,rootdir);
	  if (putenv(str)) l=-6;
      envs[0] = str;
	  chkflag = 0;
	  str = (char *) malloc (strlen(basedir)+15);
	  strcpy(str,BASE_DIR);
      strcat(str,"=");
	  bdir = strstr(basedir,CHECKDIR);
	  if ( bdir ) {
		chkflag = bdir-basedir;
		bdir = bdir+strlen(CHECKDIR);
		if ( chkflag ) {
		  strncat(str,basedir,chkflag);
		  if (strlen(bdir)) bdir += 1;
		}
		if (strlen(bdir)) strcat(str,bdir);
		else if ( !chkflag ) strcat(str,".");
		chkflag = 1;
	  } else
		strcat(str,basedir);
	  if (putenv(str)) l=-6;
      envs[1] = str;
	  str = (char *) malloc (strlen(execcmd)+15);
	  strcpy(str,EXEC_CMD);
	  strcat(str,"=");
	  strcat(str,execcmd);
	  if (putenv(str)) l=-6;
      envs[2] = str;
	  p = getpid();
	}
  if (l==0) {
	spid = p;
	debug_level = d;
	caseflag = cf;
    strcpy((char *)&ouid,asid);
#ifdef WIN32COMMON
	_fmode = O_BINARY;
#else
	uid = getuid();
	gid = getgid();
#endif
    write_log(0,"MSG","Open",ouid,"pid:",spid,NULL,NULL,NULL);
    if (foutput) fprintf(foutput,"Inited: %d:%s\n",spid,ouid);
  } else {
	p = l;
	clear_ptr();
	if (foutput) fprintf(foutput,"Init Failed: %d,%d\n",l,getpid());
  }
  close_log( foutput );
  *ret_ind = (short)OCI_IND_NOTNULL;
  return p;
}

void DLLEXPORT fio_close(void)
{
  FILE   *foutput;
  if (spid==getpid()) write_log(0,"MSG","Close",ouid,"pid:",spid,NULL,NULL,NULL);
  open_log( &foutput );
  if (foutput) fprintf(foutput,"FIO Close: %d:%s\n",getpid(),ouid);
  close_log( foutput );
  clear_ptr();
}

int  check_init( void )
{
  if ((spid==getpid())&&(envcnt>1)) return 0;
  clear_ptr();
  return 1;
}

#ifdef VMS

#ifdef __cplusplus
extern "C" {
#endif

extern int   decc$feature_get_index (char *name);
//extern char *decc$feature_get_name  (int index);
//extern int   decc$feature_get_value (int index, int mode);
extern int   decc$feature_set_value (int index, int mode, int value);

#ifdef __cplusplus
}
#endif

/*
** Set current values for features
*/
void set_features_default(void)
{
    int index;
//    index = decc$feature_get_index("DECC$FILENAME_UNIX_NO_VERSION");
//	decc$feature_set_value(index, 1, 1);
//    index = decc$feature_get_index("DECC$FILENAME_UNIX_ONLY");
//	decc$feature_set_value(index, 1, 1);
//    index = decc$feature_get_index("DECC$FILE_SHARING");
//	decc$feature_set_value(index, 1, 1);
    index = decc$feature_get_index("DECC$UNIX_LEVEL");
	decc$feature_set_value(index, 1, 30);
}
#else
void set_features_default(void) {}
#endif

char *make_name( char *path, short path_ind, char *rdir, int *flag )
{ char *name;
  *flag = 0;
  if ( (path_ind==(short)OCI_IND_NULL)||(strlen(path)==0) )
	name = rdir;
  else
	if ( (path[0]==SLASH)||(path[1]==DRIVETAG) )
	  name = path;
	else {
	  name = (char *)malloc(strlen(rdir)+strlen(path)+2);
	  *flag= 1;
	  strcpy(name,rdir);
	  strcat(name,SLASHSTR);
	  strcat(name,path);
	}
  return name;
}

char  *str_find( char *str1, char *str2 )
{
  if (caseflag) {
	char *s1= str1;
	char *s2= str2;
    char *s = NULL;
    char *ss= s1;
	while ( *s1 && *s2 ) {
	  if ( tolower(*s1) == tolower(*s2) ) {
		if ( !s ) s=ss;
		s1++; s2++;
	  }	else {
		if (s) { s=NULL; s2=str2; }
		ss++; s1=ss;
	  }
	}
	if (*s2) s=NULL;
	return s;
  } else return strstr(str1,str2);
}

int strcheck( char *str1, char *str2 )
{
  if (caseflag)
	return strcasecmp(str1,str2);
  else
	return strcmp(str1,str2);
}

int check_path( char *path, char *rdir, int flag, int scan)
{ char *base, *name;
  int   j, i=-1, ii=-1, l=FIO_ACCESS_ERR;
  if (strstr(path,PARENTDIR)) return FIO_ACCESS_ERR;
  if ( flag||chkflag ) {
	if (str_find(path,rdir)==path)
	  return 0;
    else if (flag) return FIO_ACCESS_ERR;
  }
  if ( scan ) {
	name = strrchr(path,SLASH);
	if (name) {
	  ii = name-path;
	  path[ii] = 0;
	}
  }
  j = strlen(path)-1;
  if (j>0) {
    if ( path[j-1]==SLASH && path[j]==SELFDIR ) i = j-1;
    else if ( path[j]==SLASH && path[j-1]!=DRIVETAG ) i = j;
  }
  if (i>=0) path[i] = 0;
  base = strdup(getenv(BASE_DIR));
  name = strtok(base,SEPARATOR);
  while (name) {
	j = strlen(name)-1;
	if (j>0) {
	  if (name[j]==SLASH) {
	    name[j] = 0;
	    if ((strstr(path,PARENTDIR)==NULL)&&(str_find(path,name)==path)&&
			((path[strlen(name)] == 0)||(path[strlen(name)] == SLASH))) {
		  l = 0; break;
	    }
	  } else if (strcheck(name,path)==0){
	    l = 0; break;
	  }
	}
	name = strtok(NULL,SEPARATOR);
  }
  free(base);
  if (i>=0) path[i] = SLASH;
  if (ii>=0)path[ii]= SLASH;
  return l;
}

int check_cmd( char *cmd )
{
  int   i, l = FIO_ACCESS_ERR;
  char *list = strdup(getenv(EXEC_CMD));
  char *name = strtok(list,SEPARATOR);
  while (name) {
	i =	strlen(name);
	if ((i>0)&&(strcheck(name,cmd)==0)){
	  l = 0; break;
	}
	name = strtok(NULL,SEPARATOR);
  }
  free(list);
  return l;
}

int check_mask( char *name, char *mask )
{
  if ( (mask)&&(strlen(mask)>0) ) {
    int   l, flag=0;
    char  c;
    char *str, *strr;
    char *str1 = name;
    char *str2 = mask;
    do {
	  str = strchr(str2,SEARCHALL);
	  strr= strchr(str2,SEARCHONE);
	  if (str){
		if ( (strr)&&((strr-str2)<(str-str2)) ) {
		  str = strr;
		  c = SEARCHONE;
		} else c = SEARCHALL;
	  }	else
		if (strr) {
		  str = strr;
		  c = SEARCHONE;
		}
      if (str) {
		l = str-str2;
		str[0] = 0;
      } else {
        l = strlen(str2);
        c = 0;
      }
      if (l) str=str_find(str1,str2); else str=NULL;
      if (c) str2[l]=c;
      if (str) {
        if (flag) flag = 0;
        else
		  if ( (str-str1)>0 ) return 0;
        str1 = str+l;
        str2 += l;
      }
      else if (l) return 0;
      if (c) {
        if (c==SEARCHALL) flag = 1;
        else
          if (str1[0]) str1 += 1;
          else return 0;
        str2 += 1;
      } else
        if ( (!flag)&&(str1[0]) ) return 0;
        else return 1;
    } while (1);
  }
  return 1;
}

int DLLEXPORT f_list(
	char   *dirname,  short   dirname_ind,
	char   *ldir,     short  *ldir_ind,
	size_t *ldir_len, size_t *ldir_max,
	int     chkflag,  short   chkflag_ind,
	int     dirflag,  short   dirflag_ind,
	short  *ret_ind
		   )
{ DIR    *fdir;
  int     l = 0;
  memset( ldir, 0, *ldir_max );
  if ( check_init() ) {
	*ldir_len = 0;
	*ldir_ind = (short)OCI_IND_NULL;
	*ret_ind  = (short)OCI_IND_NULL;
  } else {
	char *dname, *rname, *mask;
	int   m,df;
	rname= getenv(ROOT_DIR);
	dname= make_name(dirname,dirname_ind,rname,&m);
	mask = strstr(dname,MASKSTR);
	if (mask) {
	  df = mask-dname;
	  if ( !m ) { dname=strdup(dname); m=1; }
	  dname[df] = 0;
	  mask = dname+df+MASKLEN;
	}
	fdir = opendir(dname);
	if (fdir){
	  if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	  l = -check_path(dname,rname,l,0);
	} else l = errno;
	if ( l ) {
	  if (fdir) closedir(fdir);
      write_log(0,"ERR","Flist",dname,"error:",l,errmsg(-l),mask,NULL);
	  l = -l;
	} else {
	  struct dirent *entry;
	  char 	*path,*name,*ename;
	  struct stat   *buf;
	  int eput = 1;
	  if ( dirflag_ind==(short)OCI_IND_NULL ) df = 3;
	  else df = dirflag & 7;
	  if ( !(df & 3) ) df = df | 3;
	  if ( df != 3 ) {
		buf = (struct stat *) malloc (sizeof(struct stat));
		path= (char *) malloc (PATH_MAX+1);
		strcpy(path,dname);
		strcat(path,SLASHSTR);
		name = path+strlen(path);
	  }
	  while ( entry=readdir(fdir) ) {
		ename = entry->d_name;
		if ( (strcmp(ename,".")!=0)&&(strcmp(ename,"..")!=0) )
		  if ( check_mask(ename,mask) ) {
			if ( df != 3 ) {
			  eput = 0;
			  strcpy(name,ename);
			  if (stat(path,buf)==0) {
				if ( buf->st_mode & S_IFDIR )
					eput = df & 2;
				else
					eput = df & 1;
#ifndef WIN32COMMON
				if ( eput && (df & 4) ) {
				  if ( buf->st_uid==uid ) eput=S_IRWXU;
				  else if ( buf->st_gid==gid ) eput=S_IRWXG;
				  else eput=S_IRWXO;
				  eput = buf->st_mode & eput;
				}
#endif
			  }
			}
			if (eput)
			if ((strlen(ename)+strlen(ldir)+1)>=*ldir_max) {
			  l = BUF_OVERFLOW_ERR;
			  break;
			} else {
			  strcat(ldir,ename);
			  strcat(ldir,"\n");
			  l++;
			}
		  }
	  }
	  if ( df != 3 ) {
		free(path);
		free(buf);
	  }
	  closedir(fdir);
      if (l<0) write_log(0,"ERR","Flist",dname,"error:",l,BUF_OVERFLOW_MSG,mask,NULL);
		  else write_log(2,"MSG","Flist",dname,"entries:",l,mask,NULL,NULL);
	}
	if (m) free(dname);
	*ldir_len = strlen(ldir);
	if ( *ldir_len )
		 *ldir_ind = (short)OCI_IND_NOTNULL;
	else *ldir_ind = (short)OCI_IND_NULL;
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_infos(
	char   *fname,  short    fname_ind,
	char   *mode,   short   *mode_ind,
	size_t *mode_len,size_t *mode_max,
	char   *unam,   short   *unam_ind,
	size_t *unam_len,size_t *unam_max,
	char   *gnam,   short   *gnam_ind,
	size_t *gnam_len,size_t *gnam_max,
	char   *dat,    short   *dat_ind,
	size_t *dat_len,size_t  *dat_max,
	char   *siz,    short   *siz_ind,
	size_t *siz_len,size_t  *siz_max,
	int     chkflag,short    chkflag_ind,
	short  *ret_ind
		   )
{ int     l = 0;
	memset( mode, 0, *mode_max );
	memset( unam, 0, *unam_max );
	memset( gnam, 0, *gnam_max );
	memset( dat,  0, *dat_max );
	memset( siz,  0, *siz_max );
	*mode_len = 0;
	*mode_ind = (short)OCI_IND_NULL;
	*unam_len = 0;
	*unam_ind = (short)OCI_IND_NULL;
	*gnam_len = 0;
	*gnam_ind = (short)OCI_IND_NULL;
	*dat_len  = 0;
	*dat_ind  = (short)OCI_IND_NULL;
	*siz_len  = 0;
	*siz_ind  = (short)OCI_IND_NULL;
  if ( check_init() ) {
		*ret_ind  = (short)OCI_IND_NULL;
  } else {
    struct stat   *buf;
		char *name, *rname;
		int   m;
		rname= getenv(ROOT_DIR);
		name = make_name(fname,fname_ind,rname,&m);
		buf = (struct stat *) malloc (sizeof(struct stat));
		if ( stat(name,buf) == 0 ) {
			if ( (*mode_max > 10) && (*dat_max > 19) ) {
#ifndef WIN32COMMON
				char *ugnam;
				struct passwd *uinfo = getpwuid(buf->st_uid);
				if (uinfo) {
					if (strlen(uinfo->pw_name)) ugnam=uinfo->pw_name;
					else ugnam=l_toa(buf->st_uid,0);
					if (strlen(ugnam)<*unam_max) {
						strcpy(unam,ugnam);
						*unam_len = strlen(unam);
						*unam_ind = (short)OCI_IND_NOTNULL;
					}	else l = BUF_OVERFLOW_ERR;
				}
				if (l==0) {
					struct group *ginfo = getgrgid(buf->st_gid);
					if (ginfo) {
						if (strlen(ginfo->gr_name)) ugnam=ginfo->gr_name;
						else ugnam=l_toa(buf->st_gid,0);
						if (strlen(ugnam)<*gnam_max) {
							strcpy(gnam,ugnam);
							*gnam_len = strlen(gnam);
							*gnam_ind = (short)OCI_IND_NOTNULL;
						} else l = BUF_OVERFLOW_ERR;
					}
				}
#endif
				if (l==0) {
					l_toa(buf->st_size,0);
					if (strlen(sbuf)<*siz_max) {
						strcpy(siz,sbuf);
						*siz_len = strlen(sbuf);
						*siz_ind = (short)OCI_IND_NOTNULL;
					} else l = BUF_OVERFLOW_ERR;
				}
			} else l = BUF_OVERFLOW_ERR;
			if (l==0) {
				struct tm *dt = localtime((time_t *)&(buf->st_mtime));
				sprintf(sbuf,"%04d-%02d-%02d %02d:%02d:%02d",
				dt->tm_year+1900,dt->tm_mon+1,dt->tm_mday,dt->tm_hour,dt->tm_min,dt->tm_sec);
				strcpy(dat,sbuf);
				strcpy(mode,"----------");
				if ( buf->st_mode&S_IFDIR ) mode[0]='d';
				if ( buf->st_mode&S_IRUSR ) mode[1]='r';
				if ( buf->st_mode&S_IWUSR ) mode[2]='w';
				if ( buf->st_mode&S_IXUSR ) mode[3]='x';
				if ( buf->st_mode&S_IRGRP ) mode[4]='r';
				if ( buf->st_mode&S_IWGRP ) mode[5]='w';
				if ( buf->st_mode&S_IXGRP ) mode[6]='x';
				if ( buf->st_mode&S_IROTH ) mode[7]='r';
				if ( buf->st_mode&S_IWOTH ) mode[8]='w';
				if ( buf->st_mode&S_IXOTH ) mode[9]='x';
				*dat_len = strlen(dat);
				*dat_ind = (short)OCI_IND_NOTNULL;
				*mode_len= strlen(mode);
				*mode_ind= (short)OCI_IND_NOTNULL;
				if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
				l = check_path(name,rname,l,mode[0]!='d');
			}
	  } else l = -errno;
	  free(buf);
		if (l<0)
			write_log(1,"ERR","FInfo",name,"error:",-l,errmsg(l),NULL,NULL);
		else
			write_log(3,"MSG","FInfo",name,mode,l,siz,dat,unam);
		if (m) free(name);
		*ret_ind = (short)OCI_IND_NOTNULL;
	}
	return l;
}

int DLLEXPORT f_info(
	char   *fname,  short    fname_ind,
	char   *mode,   short   *mode_ind,
	size_t *mode_len,size_t *mode_max,
	char   *unam,   short   *unam_ind,
	size_t *unam_len,size_t *unam_max,
	char   *gnam,   short   *gnam_ind,
	size_t *gnam_len,size_t *gnam_max,
	char   *dat,    short   *dat_ind,
	size_t *dat_len,size_t  *dat_max,
	long   *siz,    short   *siz_ind,
	int     chkflag,short    chkflag_ind,
	short  *ret_ind
		   )
{ int   l;
	char	s[100];
	short	sind;
	size_t	slen,smax=100;

	*siz = 0;
	*siz_ind = (short)OCI_IND_NULL;
	l = f_infos(fname,fname_ind,mode,mode_ind,mode_len,mode_max,
						unam,unam_ind,unam_len,unam_max,gnam,gnam_ind,gnam_len,gnam_max,
						dat,dat_ind,dat_len,dat_max,s,&sind,&slen,&smax,chkflag,chkflag_ind,ret_ind);
	if ( slen > 0 ) {
		*siz = atol(s);
		*siz_ind = (short)OCI_IND_NOTNULL;
	}
  return l;
}

int DLLEXPORT dir_open(
	char   *dirname,  short   dirname_ind,
	int     dirflag,  short   dirflag_ind,
	char   *mask,  short mask_ind,
	unsigned char *f, short *f_ind, size_t *f_len,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
		  )
{ int l = 0;
  if (check_init()) {
	*f_len = 0;
	*f_ind = (short)OCI_IND_NULL;
	*ret_ind = (short)OCI_IND_NULL;
  } else {
	DIR  *fdir;
	char *dname, *rname;
	int   m,df;
	rname= getenv(ROOT_DIR);
	dname= make_name(dirname,dirname_ind,rname,&m);
	fdir = opendir(dname);
	if ( dirflag_ind==(short)OCI_IND_NULL ) df = 3;
	else df = dirflag & 7;
	if ( !(df & 3) ) df = df | 3;
	if (fdir){
	  if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	  l = check_path(dname,rname,l,0);
	} else l = -errno;
	if ( l<0 ) {
	  if (fdir) closedir(fdir);
      write_log(0,"ERR","DirOpen",dname,"error:",-l,errmsg(l),mask,l_toa(df,0));
	  *f_len = 0;
	  *f_ind = (short)OCI_IND_NULL;
	} else {
	  FIODIR  *ff = (FIODIR *) malloc ( sizeof(FIODIR) );
	  l = get_dir_handle(fdir);
	  ff->counter= 0;
	  ff->handle = l;
	  ff->flag = df;
	  ff->dir = fdir;
	  if (m) { ff->name = dname; m = 0;
	  } else   ff->name = strdup(dname);
	  if ( (mask_ind==(short)OCI_IND_NOTNULL)&&(strlen(mask)) )
		ff->mask = strdup(mask);
	  else ff->mask = NULL;
      write_log(2,"MSG","DirOpen",dname,"handle",l,"mode",l_toa(df,0),mask);
	  memcpy( f,&ff,sizeof(ff) );
	  *f_len = sizeof(ff);
	  *f_ind = (short)OCI_IND_NOTNULL;
	}
	if (m) free(dname);
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT dir_close(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   )
{ int l = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)
     ||(check_init()) ) *ret_ind = (short)OCI_IND_NULL;
  else {
	FIODIR   *ff;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) l=FIO_HANDLE_ERR;
	else if (closedir(ff->dir)) l=-errno;
	if ( l==0 ) {
	  write_log(2,"MSG","DirClose",ff->name,"handle",h,NULL,NULL,NULL);
	  if (ff->mask) free(ff->mask);
	  free(ff->name);
	  free(ff);
	} else
      write_log(0,"ERR","DirClose","","error:",-l,errmsg(l),"handle",l_toa(h,0));

	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT dir_reset(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   )
{ int l = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)
     ||(check_init()) ) *ret_ind = (short)OCI_IND_NULL;
  else {
	FIODIR   *ff;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) {
	  l = FIO_HANDLE_ERR;
      write_log(0,"ERR","DirReset","","error:",-l,errmsg(l),"handle",l_toa(h,0));
	} else {
	  rewinddir(ff->dir);
	  ff->counter = 0;
	  write_log(2,"MSG","DirReset",ff->name,"handle",h,NULL,NULL,NULL);
	}
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT dir_reads(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	char   *name,   short   *name_ind,
	size_t *name_len,size_t *name_max,
	char   *mode,   short   *mode_ind,
	size_t *mode_len,size_t *mode_max,
	char   *unam,   short   *unam_ind,
	size_t *unam_len,size_t *unam_max,
	char   *gnam,   short   *gnam_ind,
	size_t *gnam_len,size_t *gnam_max,
	char   *dat,    short   *dat_ind,
	size_t *dat_len,size_t  *dat_max,
	char   *siz,    short   *siz_ind,
	size_t *siz_len,size_t  *siz_max,
	short *ret_ind
		   )
{	long l = 0;
	memset( name, 0, *name_max );
	memset( mode, 0, *mode_max );
	memset( unam, 0, *unam_max );
	memset( gnam, 0, *gnam_max );
	memset( dat,  0, *dat_max );
	memset( siz,  0, *siz_max );
	*name_len = 0;
	*name_ind = (short)OCI_IND_NULL;
	*mode_len = 0;
	*mode_ind = (short)OCI_IND_NULL;
	*unam_len = 0;
	*unam_ind = (short)OCI_IND_NULL;
	*gnam_len = 0;
	*gnam_ind = (short)OCI_IND_NULL;
	*dat_len  = 0;
	*dat_ind  = (short)OCI_IND_NULL;
	*siz_len  = 0;
	*siz_ind  = (short)OCI_IND_NULL;
	if ( (f_ind==(short)OCI_IND_NULL) || (h_ind==(short)OCI_IND_NULL) || (check_init()) ) {
		*ret_ind = (short)OCI_IND_NULL;
	} else {
		FIODIR   *ff;
		memcpy( &ff,f,sizeof(ff) );
		if ( h != ff->handle ) l=FIO_HANDLE_ERR;
		else if ( (*mode_max<11) || (*dat_max<20) ) l = BUF_OVERFLOW_ERR;
		else {
			struct dirent *entry;
			struct stat   *buf = (struct stat *) malloc (sizeof(struct stat));
			char  *dname, *path= (char *) malloc (PATH_MAX+1);
			int    eput,   df = ff->flag;
			strcpy(path,ff->name);
			strcat(path,SLASHSTR);
			dname = path+strlen(path);
			while ( entry=readdir(ff->dir) ) {
				if ( (strcmp(entry->d_name,".")!=0) && (strcmp(entry->d_name,"..")!=0) && (check_mask(entry->d_name,ff->mask)) ) {
	  			strcpy(dname,entry->d_name);
	  			if ( stat(path,buf) ) l = -errno;
					else {
						if ( df==3 ) eput = 1;
						else {
							eput = 0;
							if ( buf->st_mode & S_IFDIR ) eput = df & 2;
							else eput = df & 1;
#ifndef WIN32COMMON
							if ( eput && (df & 4) ) {
								if ( buf->st_uid==uid ) eput=S_IRWXU;
								else if ( buf->st_gid==gid ) eput=S_IRWXG;
								else eput=S_IRWXO;
								eput = buf->st_mode & eput;
							}
#endif
		  			}
						if (eput) {
							if ( strlen(dname)<*name_max ) {
								struct tm *dt = localtime((time_t *)&(buf->st_mtime));
								l = ff->counter+1;
								ff->counter = l;
								strcpy(name,dname);
								*name_len = strlen(name);
								*name_ind = (short)OCI_IND_NOTNULL;
								sprintf(sbuf,"%04d-%02d-%02d %02d:%02d:%02d",
									dt->tm_year+1900,dt->tm_mon+1,dt->tm_mday,dt->tm_hour,dt->tm_min,dt->tm_sec);
								strcpy(dat,sbuf);
								*dat_len = strlen(dat);
								*dat_ind = (short)OCI_IND_NOTNULL;
								strcpy(mode,"----------");
								if ( buf->st_mode&S_IFDIR ) mode[0]='d';
								if ( buf->st_mode&S_IRUSR ) mode[1]='r';
								if ( buf->st_mode&S_IWUSR ) mode[2]='w';
								if ( buf->st_mode&S_IXUSR ) mode[3]='x';
								if ( buf->st_mode&S_IRGRP ) mode[4]='r';
								if ( buf->st_mode&S_IWGRP ) mode[5]='w';
								if ( buf->st_mode&S_IXGRP ) mode[6]='x';
								if ( buf->st_mode&S_IROTH ) mode[7]='r';
								if ( buf->st_mode&S_IWOTH ) mode[8]='w';
								if ( buf->st_mode&S_IXOTH ) mode[9]='x';
								*mode_len= strlen(mode);
								*mode_ind= (short)OCI_IND_NOTNULL;
								l_toa(buf->st_size,0);
								if (strlen(sbuf)<*siz_max) {
									strcpy(siz,sbuf);
									*siz_len = strlen(sbuf);
									*siz_ind = (short)OCI_IND_NOTNULL;
								}
#ifndef WIN32COMMON
								if (*unam_max>1) {
									char *ugnam;
									struct passwd *uinfo = getpwuid(buf->st_uid);
									if (uinfo) {
										if (strlen(uinfo->pw_name)) ugnam=uinfo->pw_name;
										else ugnam=l_toa(buf->st_uid,0);
										strncpy(unam,ugnam,*unam_max-1);
										*unam_len = strlen(unam);
										*unam_ind = (short)OCI_IND_NOTNULL;
									}
								}
								if (*gnam_max>1) {
									char *ugnam;
									struct group  *ginfo = getgrgid(buf->st_gid);
									if (ginfo) {
									if (strlen(ginfo->gr_name)) ugnam=ginfo->gr_name;
									else ugnam=l_toa(buf->st_gid,0);
										strncpy(gnam,ugnam,*gnam_max-1);
										*gnam_len = strlen(gnam);
										*gnam_ind = (short)OCI_IND_NOTNULL;
									}
								}
#endif
							} else  l = BUF_OVERFLOW_ERR;
						}
	  			}
					if (l) break;
				}
			}
			free(path); free(buf);
		}
		if ( l<0 )
			write_log(0,"ERR","DirRead","","error:",-l,errmsg(l),"handle",l_toa(h,0));
		else
			write_log(3,"MSG","DirRead",ff->name,"handle",h,"entry",l_toa(l,0),name);
		*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT dir_read(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	char   *name,   short   *name_ind,
	size_t *name_len,size_t *name_max,
	char   *mode,   short   *mode_ind,
	size_t *mode_len,size_t *mode_max,
	char   *unam,   short   *unam_ind,
	size_t *unam_len,size_t *unam_max,
	char   *gnam,   short   *gnam_ind,
	size_t *gnam_len,size_t *gnam_max,
	char   *dat,    short   *dat_ind,
	size_t *dat_len,size_t  *dat_max,
	long   *siz,    short   *siz_ind,
	short *ret_ind
		   )
{ long   l;
	char	s[100];
	short	sind;
	size_t	slen,smax=100;

	*siz = 0;
	*siz_ind = (short)OCI_IND_NULL;
	l = dir_reads(h,h_ind,f,f_ind,name,name_ind,name_len,name_max,mode,mode_ind,mode_len,mode_max,
						unam,unam_ind,unam_len,unam_max,gnam,gnam_ind,gnam_len,gnam_max,
						dat,dat_ind,dat_len,dat_max,s,&sind,&slen,&smax,ret_ind);
	if ( l > 0 ) {
		*siz = atol(s);
		*siz_ind = (short)OCI_IND_NOTNULL;
	}
  return l;
}

void DLLEXPORT err_msg(
	int     err,  short   err_ind,
	char   *mes,  short  *mes_ind,
	size_t *mes_len, size_t *mes_max
			 )
{
  memset( mes, 0, *mes_max );
  if ( (err_ind==(short)OCI_IND_NULL)||(err>=0) ) {
	*mes_len = 0;
	*mes_ind = (short)OCI_IND_NULL;
  } else {
	switch (err) {
      case FIO_ACCESS_ERR:
	    strncpy(mes,FIO_ACCESS_MSG,*mes_max-1); break;
	  case BUF_OVERFLOW_ERR:
		strncpy(mes,BUF_OVERFLOW_MSG,*mes_max-1); break;
 	  case FIO_HANDLE_ERR:
	    strncpy(mes,FIO_HANDLE_MSG,*mes_max-1); break;
	  default:
		strncpy(mes,strerror(-err),*mes_max-1);
	}
	*mes_len = strlen(mes);
	*mes_ind = (short)OCI_IND_NOTNULL;
  }
}

int DLLEXPORT f_rename(
	char   *oldname,  short   oldname_ind,
	char   *newname,  short   newname_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			 )
{ int     l = 0;
  if ( (oldname_ind==(short)OCI_IND_NULL)||(strlen(oldname)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	char *name, *oname, *rname;
	int om,nm,ft;
	int f = 0;
	struct stat   *st = (struct stat *) malloc (sizeof(struct stat));
    rname= getenv(ROOT_DIR);
	oname= make_name(oldname,oldname_ind,rname,&om);
	name = make_name(newname,newname_ind,rname,&nm);
	if ( chkflag_ind==(short)OCI_IND_NOTNULL ) f = chkflag;
	if (stat(oname,st)==0) {
	  ft = (st->st_mode&S_IFDIR);
	  l = check_path(oname,rname,f,1);
	  if ((l==0)&&ft) l = check_path(oname,rname,f,0);
	} else l = -errno;
	if (l==0) if (stat(name,st)==0)
	  if (ft) l = -EEXIST;
	  else if ( st->st_mode&S_IFDIR ) {
		l = check_path(name,rname,f,0);
		if (l==0) {
  		  rname = strrchr(oname,SLASH);
		  if (rname==NULL) rname=oname; else rname++;
		  f = strlen(name)+strlen(rname)+2;
		  if (nm) name=(char*)realloc(name,f);
		  else {
			char *tmp = name;
			name = (char*)malloc(f);
			name = strcpy(name,tmp);
			nm = 1;
		  }
		  f = -1;
		  strcat(name,SLASHSTR);
		  strcat(name,rname);
		  if (stat(name,st)==0)
			if ( st->st_mode&S_IFDIR ) l = -EISDIR;
			else if (strcheck(name,oname)==0) l = -EEXIST;
		}
	  }
	if ( (l==0) && (f>=0) ) l = check_path(name,rname,f,1);
	if ( l==0 ) {
      l = rename(oname,name);
	  if ( (l<0) && (errno==EEXIST)) {
		l = remove(name);
		if (l==0) l = rename(oname,name);
	  }
	  if (l<0) l = -errno;
	}
	if (l==0)
      write_log(1,"MSG","Rename",oname,name,l,NULL,NULL,NULL);
	else
	  write_log(0,"ERR","Rename",oname,name,l,errmsg(l),NULL,NULL);
	if (nm) free(name);
	if (om) free(oname);
	free(st);
	*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_remove(
	char   *path,    short   path_ind,
	int     chkflag, short   chkflag_ind,
	short  *ret_ind
			 )
{ int     l = 0;
  if ( (path_ind==(short)OCI_IND_NULL)||(strlen(path)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	char *name, *rname;
	int m;
	rname= getenv(ROOT_DIR);
	name = make_name(path,path_ind,rname,&m);
	if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	l = check_path(name,rname,l,1);
	if ( l==0 ) {
#ifdef WIN32COMMON
	  struct stat   *buf = (struct stat *) malloc (sizeof(struct stat));
	  if (stat(name,buf)==0) {
		  if ( buf->st_mode&S_IFDIR ) l=_rmdir(name); else l=remove(name);
	  } else l = -1;
	  free(buf);
#else
	  l = remove(name);
#endif
	  if (l<0) l = -errno;
	}
	if ( l==0 )
      write_log(1,"MSG","Remove",name,"",l,NULL,NULL,NULL);
	else
	  write_log(0,"ERR","Remove",name,"error:",-l,errmsg(l),NULL,NULL);
	if (m) free(name);
	*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_mkdir(
	char   *path, short   path_ind,
	int     mode, short   mode_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			)
{ int     l = 0;
  if ( (path_ind==(short)OCI_IND_NULL)||(strlen(path)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	char *name, *rname;
	int   m,md;
	rname= getenv(ROOT_DIR);
	name = make_name(path,path_ind,rname,&m);
	if ( (mode_ind==(short)OCI_IND_NULL)||(mode==0) )
		 md = S_IRWXU;
	else md = mode|S_IRUSR|S_IXUSR;
	if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	l = -check_path(name,rname,l,1);
	if ( l==0 ) {
	  l = mkdir(name,md);
	  if (l<0) l = errno;
	}
	if ( l==0 )
      write_log(1,"MSG","MkDir",name,"mode",md,NULL,NULL,NULL);
	else {
      write_log(0,"ERR","MkDir",name,"error:",l,errmsg(-l),"mode",l_toa(md,0));
	  l = -l;
	}
	if (m) free(name);
	*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT h_creat(
	char   *path, short   path_ind,
	int     mode, short   mode_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			)
{ int     l = 0;
  if ( (path_ind==(short)OCI_IND_NULL)||(strlen(path)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	char *name, *rname;
	int   m,md;
	rname= getenv(ROOT_DIR);
	name = make_name(path,path_ind,rname,&m);
	if ( (mode_ind==(short)OCI_IND_NULL)||(mode==0) )
		 md = S_IRWXU;
	else md = mode;
	if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	l = check_path(name,rname,l,1);
	if ( l==0 ) {
	  l = creat(name,md);
	  if (l<0) l = -errno;
	}
	if ( l<0 )
      write_log(0,"ERR","HCreate",name,"error:",-l,errmsg(l),"accessmode",l_toa(md,0));
	else
      write_log(2,"MSG","HCreate",name,"handle",l,"accessmode",l_toa(md,0),NULL);
	if (m) free(name);
	*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT h_open(
	char   *path, short   path_ind,
	int     mode, short   mode_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
		   )
{ int     l = 0;
  if ( (path_ind==(short)OCI_IND_NULL)||(strlen(path)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	char *name, *rname;
	int   m,md;
	rname= getenv(ROOT_DIR);
	name = make_name(path,path_ind,rname,&m);
	if ( (mode_ind==(short)OCI_IND_NULL)||(mode==0) )
		 md = O_RDONLY;
	else md = mode;
	if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	l = check_path(name,rname,l,1);
	if ( l==0 ) {
	  l = open(name,md ADD_FILE_ATTRS);
	  if (l<0) l = -errno;
	}
	if ( l<0 )
      write_log(0,"ERR","HOpen",name,"error:",-l,errmsg(l),"mode",l_toa(md,0));
	else
      write_log(2,"MSG","HOpen",name,"handle",l,"mode",l_toa(md,0),NULL);
	if (m) free(name);
	*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT h_close(
	int     handle, short   handle_ind,
	short  *ret_ind
			)
{ int     l = 0;
  if ( (handle_ind==(short)OCI_IND_NULL)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	l = close(handle);
	if (l<0) l = -errno;
	if ( l==0 )
      write_log(2,"MSG","HClose","","handle",handle,NULL,NULL,NULL);
	else
      write_log(0,"ERR","HClose",l_toa(handle,0),"error:",-l,errmsg(l),NULL,NULL);
	*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT h_read(
	int	    f, short  f_ind,
	unsigned char *buf, short *buf_ind,
	size_t *buf_len,  size_t  *buf_max,
	size_t  n, short  n_ind,
	short *return_ind
		   )
{ long l = 0;
  memset( buf,0, *buf_max );
  if ( (f_ind==(short)OCI_IND_NULL)||(check_init()) ) {
	*return_ind = (short)OCI_IND_NULL;
	*buf_ind = (short)OCI_IND_NULL;
	*buf_len = 0;
  } else { size_t m;
	if ((n_ind==(short)OCI_IND_NULL)||(n==0)
	   ||(n>*buf_max)) m=*buf_max; else m=n;
	l = read(f,buf,m);
	if (l<0){
	  l = -errno;
      write_log(0,"ERR","HRead",l_toa(f,0),"error:",-l,errmsg(l),NULL,NULL);
	} else
      write_log(3,"MSG","HRead",l_toa(f,0),"bytes:",l,NULL,NULL,NULL);
	if (l>0)
	{
	  *buf_ind = (short)OCI_IND_NOTNULL;
	  *buf_len = l;
	} else {
	  *buf_ind = (short)OCI_IND_NULL;
	  *buf_len = 0;
	}
	*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT h_write(
	int	    f, short  f_ind,
	unsigned char *buf, short buf_ind,	size_t buf_len,
	size_t  n, short  n_ind,
	short *return_ind
			)
{ long l = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(check_init()) )
	*return_ind = (short)OCI_IND_NULL;
  else { size_t m=0;
	if ( (buf_ind==(short)OCI_IND_NOTNULL)&&(buf_len>0)) m=buf_len;
	if ( (n_ind==(short)OCI_IND_NOTNULL)&&(n>0)&&(n<m) ) m=n;
	l = write(f,buf,m);
	if (l<0){
	  l = -errno;
      write_log(0,"ERR","HWrite",l_toa(f,0),"error:",-l,errmsg(l),NULL,NULL);
	} else
      write_log(3,"MSG","HWrite",l_toa(f,0),"bytes:",l,NULL,NULL,NULL);
	*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT h_seeks(
	int	    f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	char   *pos, short *pos_ind, size_t *pos_len, size_t  *pos_max,
	short  *return_ind
			)
{ long l = 0;
  memset( pos,  0, *pos_max );
  *pos_len  = 0;
  *pos_ind  = (short)OCI_IND_NULL;
  if ( (f_ind==(short)OCI_IND_NULL)||(check_init()) )
		*return_ind = (short)OCI_IND_NULL;
  else {
		long p, m = 0;
		int  s = SEEK_SET;
		if ( (w_ind==(short)OCI_IND_NOTNULL) ) s = w;
		if ( (n_ind==(short)OCI_IND_NOTNULL) ) m = n;
		p = lseek(f,m,s);
		if ( p >= 0 ) {
			l_toa(p,0);
			if ( strlen(sbuf) < *pos_max ) {
				strcpy(pos,sbuf);
				*pos_len = strlen(sbuf);
				*pos_ind = (short)OCI_IND_NOTNULL;
			} else l = BUF_OVERFLOW_ERR;
		} else l = -errno;
		if ( l < 0 )
			write_log(0,"ERR","HSeek",l_toa(f,0),"error:",-l,errmsg(l),l_toa(s,20),l_toa(m,50));
		else
			write_log(3,"MSG","HSeek",l_toa(f,0),"offset:",m,"position",pos,NULL);
		*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT h_seek(
	int	    f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	short *return_ind
			)
{ long l;
	char	p[100];
	short	pind;
	size_t	plen,pmax=100;
	l = h_seeks(f,f_ind,n,n_ind,w,w_ind,p,&pind,&plen,&pmax,return_ind);
	if ( plen > 0 )	l = atol(p);
  return l;
}

int DLLEXPORT get_env(
	char *name, short  name_ind,
	char *buf,  short *buf_ind,
	size_t *buf_len,  size_t  *buf_max,
	short *ret_ind
		   )
{ int     l = 0;
  memset( buf,0, *buf_max );
  *buf_len = 0;
  *buf_ind = (short)OCI_IND_NULL;
  if ( (name_ind==(short)OCI_IND_NULL)||(strlen(name)==0)
	 ||(check_init()) ) {
    *ret_ind = (short)OCI_IND_NULL;
  } else {
	char *env = getenv(name);
	if (env) {
	l = strlen(env);
	if ((size_t)l>*buf_max) {
	  l = BUF_OVERFLOW_ERR;
	  write_log(1,"ERR","GetEnv",name,"error:",l,BUF_OVERFLOW_MSG,NULL,NULL);
	} else {
	  strcpy(buf,env);
	  write_log(3,"MSG","GetEnv",name,"bytes:",l,env,NULL,NULL);
	}
	*buf_len = strlen(buf);
	*buf_ind = (short)OCI_IND_NOTNULL;
	}
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT put_env(
	char *name, short  name_ind,
	char *buf,  short  buf_ind,
	short *ret_ind
		   )
{ int     l = 0;
  if ( (name_ind==(short)OCI_IND_NULL)||(strlen(name)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
    char *env, *tmp;
	int   n,lb;
	int   ln = strlen(name)+1;
	if ( (buf_ind==(short)OCI_IND_NULL)||(strlen(buf)==0) )
		  lb = 0;
	else  lb = strlen(buf);
	env = (char *) malloc (ln+lb+1);
	strcpy(env,name);
	strcat(env,"=");
    for (n=0; n<=envcnt; n++) {
      tmp = envs[n];
      if ((tmp)&&(str_find(tmp,env)==tmp)) break;
    }
	strcat(env,buf);
    if (n<3) {
	  l = FIO_ACCESS_ERR;
	  n = 0;
	} else
      if (n>99) l = -ENOMEM;
	  else {
		if (n>envcnt) envcnt = n;
		if (envs[n]) {
		  free(envs[n]);
		  envs[n] = NULL;
		}
		if (putenv(env)) l = -ENOMEM;
	  }
	if ( (l<0)||(lb==0) ) {
	  if (n==envcnt) envcnt--;
	  free(env);
	} else {
	  l = lb;
	  envs[n] = env;
	}
	if (l<0)
	  write_log(1,"ERR","PutEnv",env,"error:",-l,errmsg(l),NULL,NULL);
	else
	  write_log(3,"MSG","PutEnv",env,"bytes:",l,NULL,NULL,NULL);
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_run(
	char *cmd, short  cmd_ind,
	char *a0,  short  a0_ind,
	char *a1,  short  a1_ind,
	char *a2,  short  a2_ind,
	char *a3,  short  a3_ind,
	char *a4,  short  a4_ind,
	char *a5,  short  a5_ind,
	char *a6,  short  a6_ind,
	char *a7,  short  a7_ind,
	char *a8,  short  a8_ind,
	char *a9,  short  a9_ind,
	short *ret_ind
		  )
{ int    l = 0;
  if ( (cmd_ind==(short)OCI_IND_NULL)||(strlen(cmd)==0)
	 ||(check_init()) ) *ret_ind  = (short)OCI_IND_NULL;
  else {
	char *ecmd = strdup(cmd);
	l = check_cmd(ecmd);
	if (l==0) {
	  char *args,*rcmd,*tmp;
      int la; int n = 0;
	  while ( tmp=strchr(ecmd,SEARCHARG) ) {
		la = 0;
		switch (n) {
		  case 0:
			if (a0_ind==(short)(OCI_IND_NOTNULL)) {args=a0; la=strlen(a0);}
			break;
		  case 1:
			if (a1_ind==(short)(OCI_IND_NOTNULL)) {args=a1; la=strlen(a1);}
			break;
		  case 2:
			if (a2_ind==(short)(OCI_IND_NOTNULL)) {args=a2; la=strlen(a2);}
			break;
		  case 3:
			if (a3_ind==(short)(OCI_IND_NOTNULL)) {args=a3; la=strlen(a3);}
			break;
		  case 4:
			if (a4_ind==(short)(OCI_IND_NOTNULL)) {args=a4; la=strlen(a4);}
			break;
		  case 5:
			if (a5_ind==(short)(OCI_IND_NOTNULL)) {args=a5; la=strlen(a5);}
			break;
		  case 6:
			if (a6_ind==(short)(OCI_IND_NOTNULL)) {args=a6; la=strlen(a6);}
			break;
		  case 7:
			if (a7_ind==(short)(OCI_IND_NOTNULL)) {args=a7; la=strlen(a7);}
			break;
		  case 8:
			if (a8_ind==(short)(OCI_IND_NOTNULL)) {args=a8; la=strlen(a8);}
			break;
		  case 9:
			if (a9_ind==(short)(OCI_IND_NOTNULL)) {args=a9; la=strlen(a9);}
			break;
		  default:
			l = -EINVAL;
		}
		if (l<0) break;
		rcmd = (char *) malloc (strlen(ecmd)+la);
		tmp[0] = 0;
		strcpy(rcmd,ecmd);
		if (la) strcat(rcmd,args);
		strcat(rcmd,tmp+1);
		free(ecmd);
		ecmd = rcmd;
		n++;
	  }
	  if (l==0) {
		fflush(stderr);
		fflush(stdout);
		l = system(ecmd);
		if (l<0) l= -errno;
	  }
	}
	if (l<0)
	  write_log(0,"ERR","FRun",ecmd,"error:",-l,errmsg(l),NULL,NULL);
	else
      write_log(1,"MSG","FRun",ecmd,"status:",l,NULL,NULL,NULL);
	free(ecmd);
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT f_copys(
	char   *oldname,  short   oldname_ind,
	char   *newname,  short   newname_ind,
	int     wrflag,   short   wrflag_ind,
	int     chkflag,  short   chkflag_ind,
	char   *siz, short *siz_ind, size_t *siz_len, size_t  *siz_max,
	short  *ret_ind
			 )
{ long	l = 0;
  memset( siz,  0, *siz_max );
  *siz_len  = 0;
  *siz_ind  = (short)OCI_IND_NULL;
  if ( (oldname_ind==(short)OCI_IND_NULL) || (strlen(oldname)==0) || (check_init()) )
		*ret_ind  = (short)OCI_IND_NULL;
  else {
		char *name, *oname, *rname;
		int om,nm;
		int	w = 0;
		int f = 0;
		struct stat   *st = (struct stat *) malloc (sizeof(struct stat));
		rname= getenv(ROOT_DIR);
		oname= make_name(oldname,oldname_ind,rname,&om);
		name = make_name(newname,newname_ind,rname,&nm);
		if ( chkflag_ind==(short)OCI_IND_NOTNULL ) f = chkflag;
		if ( wrflag_ind ==(short)OCI_IND_NOTNULL ) w = wrflag;
		if (stat(oname,st)==0)
			if ( st->st_mode & S_IFDIR ) l = -EISDIR;
			else l = check_path(oname,rname,f,1);
		else l = -errno;
		if ( l==0 ) if (stat(name,st)==0)	if ( st->st_mode & S_IFDIR ) {
			l = check_path(name,rname,f,0);
			if ( l==0 ) {
 				rname = strrchr(oname,SLASH);
				if ( rname ) rname++;
				else rname = oname;	
				f = strlen(name)+strlen(rname)+2;
				if ( nm )
					name = (char*)realloc(name,f);
				else {
					char *tmp = name;
					name = (char*)malloc(f);
					name = strcpy(name,tmp);
					nm = 1;
				}
				f = -1;
				strcat(name,SLASHSTR);
				strcat(name,rname);
			}
		}
		if ( (l==0) && (f>=0) ) l = check_path(name,rname,f,1);
		if ( l==0 ) {
			FILE   *fold = fopen(oname,"r" ADD_FILE_ATTRS);
			if ( fold ) {
				FILE   *fnew;
				size_t	sr,sw;
				int		err;
				if (w) fnew = fopen(name,"w" ADD_FILE_ATTRS);
				else fnew = fopen(name,"a" ADD_FILE_ATTRS);
				if ( fnew ) {
					long sz = 0;
  				void *buf = malloc (64000);
					if (buf) {
						while (!feof(fold)) {
							sr = fread(buf,1,64000,fold);
							err= ferror(fold);
							if (err) {
								l = -err; break;
							}
							sw = fwrite(buf,1,sr,fnew);
							err= ferror(fnew);
							if (err) {
								l=-err; break;
							}
							sz += (long)sw;
						}
						free(buf);
                        l_toa(sz,0);
						if ( strlen(sbuf) < *siz_max ) {
							strcpy(siz,sbuf);
							*siz_len = strlen(sbuf);
							*siz_ind = (short)OCI_IND_NOTNULL;
						}
					}	else l = -ENOMEM;
					fclose(fnew);
				} else l = -errno;
				fclose(fold);
			} else l = -errno;
		}
		if ( l>=0 )
			write_log(1,"MSG","Copy",oname,name,l,"bytes",siz,NULL);
		else
			write_log(0,"ERR","Copy",oname,name,l,"error",errmsg(l),NULL);
		if (nm) free(name);
		if (om) free(oname);
		free(st);
		*ret_ind  = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT f_copy(
	char   *oldname,  short   oldname_ind,
	char   *newname,  short   newname_ind,
	int     wrflag,   short   wrflag_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			 )
{ long l;
	char	s[100];
	short	sind;
	size_t	slen,smax=100;
	l = f_copys(oldname,oldname_ind,newname,newname_ind,wrflag,wrflag_ind,
			chkflag,chkflag_ind,s,&sind,&slen,&smax,ret_ind);
	if ( slen > 0 )	l = atol(s);
  return l;
}

int DLLEXPORT f_open(
	char   *path,  short path_ind,
	char   *mode,  short mode_ind,
	unsigned char *f, short *f_ind, size_t *f_len,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
		  )
{ int l = 0;
  if ((path_ind==(short)OCI_IND_NULL)||(strlen(path)==0)||(check_init())) {
	*f_len = 0;
	*f_ind = (short)OCI_IND_NULL;
	*ret_ind = (short)OCI_IND_NULL;
  } else {
	FILE *ff; int   m;
	char *name, *rname;
	char *md = "r";
	rname= getenv(ROOT_DIR);
	name = make_name(path,path_ind,rname,&m);
	if ((mode_ind==(short)OCI_IND_NOTNULL)&&(strlen(mode)>0)) md=mode;
	if ( chkflag_ind==(short)OCI_IND_NOTNULL ) l = chkflag;
	l = check_path(name,rname,l,1);
	if ( l==0 ) {
	  ff = fopen(path,md ADD_FILE_ATTRS);
	  if (ff) l=fileno(ff); else l=-errno;
	}
	if (l<0) {
	  write_log(0,"ERR","FOpen",name,"error:",-l,errmsg(l),"mode",md);
	  *f_len = 0;
	  *f_ind = (short)OCI_IND_NULL;
	} else {
	  FIOFILE *fi = (FIOFILE *) malloc ( sizeof(FIOFILE) );
	  fi->handle = l;
	  fi->f = ff;
	  if (m) {
	    fi->name = name; m = 0;
	  } else fi->name = strdup(name);
	  memcpy( f,&fi,sizeof(fi) );
      write_log(2,"MSG","FOpen",name,"handle",l,"mode",md,NULL);
	  *f_len = sizeof(fi);
	  *f_ind = (short)OCI_IND_NOTNULL;
	}
	if (m) free(name);
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_close(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   )
{ int l = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)
     ||(check_init()) ) *ret_ind = (short)OCI_IND_NULL;
  else {
	FIOFILE *ff;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) l=FIO_HANDLE_ERR;
	else if (fclose(ff->f)) l=-errno;
	if ( l==0 ) {
	  write_log(2,"MSG","FClose",ff->name,"handle",h,NULL,NULL,NULL);
	  free(ff->name);
	  free(ff);
	} else
      write_log(0,"ERR","FClose",l_toa(h,0),"error:",-l,errmsg(l),NULL,NULL);
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT f_read(
	int	    h, short  h_ind,
	unsigned char *f,   short  f_ind,
	unsigned char *buf, short *buf_ind,
	size_t *buf_len,  size_t  *buf_max,
	size_t  n, short  n_ind,
	short *return_ind
		   )
{ long l = 0;
  memset( buf,0, *buf_max );
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)||(check_init()) ) {
	*return_ind = (short)OCI_IND_NULL;
	*buf_ind = (short)OCI_IND_NULL;
	*buf_len = 0;
  } else { size_t m;
	FIOFILE *ff; unsigned char *bf;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) l=FIO_HANDLE_ERR;
	else {
	  clearerr(ff->f);
	  if ((n_ind==(short)OCI_IND_NULL)||(n==0)) {
		if (fgets((char*)buf,*buf_max,ff->f))
		  if ( bf=(unsigned char*)memchr(buf,0,*buf_max) )
			   l = bf - buf;
		  else l = 0;
	  } else {
		if (n>*buf_max) m=*buf_max; else m=n;
		l = fread(buf,1,m,ff->f);
	  }
	  if ( m=ferror(ff->f) ) l=-(int)m;
	}
	if (l<0)
      write_log(0,"ERR","FRead",l_toa(h,0),"error:",-l,errmsg(l),NULL,NULL);
	else
      write_log(3,"MSG","FRead",ff->name,"bytes:",l,"handle",l_toa(h,0),NULL);
	if (l>0)
	{
	  *buf_ind = (short)OCI_IND_NOTNULL;
	  *buf_len = l;
	} else {
	  *buf_ind = (short)OCI_IND_NULL;
	  *buf_len = 0;
	}
	*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT f_write(
	int	    h, short  h_ind,
	unsigned char *f,   short  f_ind,
	unsigned char *buf, short buf_ind,	size_t buf_len,
	size_t  n, short  n_ind,
	short *return_ind
			)
{ long l = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)
	 ||(check_init()) )	*return_ind = (short)OCI_IND_NULL;
  else { size_t m=0;
	FIOFILE *ff;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) l=FIO_HANDLE_ERR;
	else {
	  clearerr(ff->f);
	  if ( (buf_ind==(short)OCI_IND_NOTNULL)&&(buf_len>0)) m=buf_len;
	  if ( (n_ind==(short)OCI_IND_NOTNULL)&&(n>0)&&(n<m) ) m=n;
	  l = fwrite(buf,1,m,ff->f);
	  if ( m=ferror(ff->f) ) l=-(int)m;
	}
	if (l<0)
      write_log(0,"ERR","FWrite",l_toa(h,0),"error:",-l,errmsg(l),NULL,NULL);
	else
	  write_log(3,"MSG","FWrite",ff->name,"bytes:",l,"handle",l_toa(h,0),NULL);
	*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT f_seeks(
	int	    h, short  h_ind,
	unsigned char *f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	char   *pos, short *pos_ind, size_t *pos_len, size_t  *pos_max,
	short  *return_ind
			)
{ long l = 0;
  memset( pos,  0, *pos_max );
  *pos_len  = 0;
  *pos_ind  = (short)OCI_IND_NULL;
  if ( (f_ind==(short)OCI_IND_NULL) || (h_ind==(short)OCI_IND_NULL) || (check_init()) )	
		*return_ind = (short)OCI_IND_NULL;
  else {
		long p, m = 0;
		int  s = SEEK_SET;
		FIOFILE *ff;
		memcpy( &ff,f,sizeof(ff) );
		if (h!=ff->handle) l = FIO_HANDLE_ERR;
		else {
			if ( (w_ind==(short)OCI_IND_NOTNULL) ) s = w;
			if ( (n_ind==(short)OCI_IND_NOTNULL) ) m = n;
			if ( fseek(ff->f,m,s)==0 ) {
				p = ftell(ff->f);
				if ( p>=0 ) {
					l_toa(p,0);
					if ( strlen(sbuf) < *pos_max ) {
						strcpy(pos,sbuf);
						*pos_len = strlen(sbuf);
						*pos_ind = (short)OCI_IND_NOTNULL;
					} else l = BUF_OVERFLOW_ERR;
				} else l = -errno;
			} else l = -errno;
		}
		if ( l<0 )
			write_log(0,"ERR","FSeek",l_toa(h,0),"error:",-l,errmsg(l),l_toa(s,20),l_toa(m,50));
		else
			write_log(3,"MSG","FSeek",ff->name,"handle:",h,"position",pos,NULL);
		*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

long DLLEXPORT f_seek(
	int	    h, short  h_ind,
	unsigned char *f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	short *return_ind
			)
{ long l;
	char	p[100];
	short	pind;
	size_t	plen,pmax=100;
	l = f_seeks(h,h_ind,f,f_ind,n,n_ind,w,w_ind,p,&pind,&plen,&pmax,return_ind);
	if ( plen > 0 )	l = atol(p);
  return l;
}

int DLLEXPORT f_flush(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   )
{ int l = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)
     ||(check_init()) ) *ret_ind = (short)OCI_IND_NULL;
  else {
	FIOFILE *ff;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) l=FIO_HANDLE_ERR;
	else if (fflush(ff->f)) l=-errno;
	if ( l==0 )
      write_log(3,"MSG","FFlush",ff->name,"handle",h,NULL,NULL,NULL);
	else
      write_log(0,"ERR","FFlush",l_toa(h,0),"error:",-l,errmsg(l),NULL,NULL);
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_dopen(
	int      h,   short h_ind,
	char   *mode, short mode_ind,
	unsigned char *f, short *f_ind, size_t *f_len,
	short  *ret_ind
		   )
{ int l = 0;
  if ((h_ind==(short)OCI_IND_NULL)||(h<=0)||(check_init())) {
	*f_len = 0;
	*f_ind = (short)OCI_IND_NULL;
	*ret_ind = (short)OCI_IND_NULL;
  } else {
	FILE *ff;
	char *md = "r";
	if ((mode_ind==(short)OCI_IND_NOTNULL)&&(strlen(mode)>0)) md=mode;
	ff = fdopen(h,md);
	if (ff) l=fileno(ff); else l=-errno;
	if (l<0) {
	  write_log(0,"ERR","FDOpen","","error:",-l,errmsg(l),"mode",md);
	  *f_len = 0;
	  *f_ind = (short)OCI_IND_NULL;
	} else {
	  FIOFILE *fi = (FIOFILE *) malloc ( sizeof(FIOFILE) );
	  fi->handle = l;
	  fi->f = ff;
	  sprintf(sbuf,"Handle %d",l);
	  fi->name = strdup(sbuf);
	  memcpy( f,&fi,sizeof(fi) );
	  write_log(2,"MSG","FDOpen","","handle",l,"mode",md,NULL);
	  *f_len = sizeof(ff);
	  *f_ind = (short)OCI_IND_NOTNULL;
	}
	*ret_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int sort_func( char **a, char **b )
{
  if (sortflag)
	return( strcheck( *a, *b) );
  else
	return( strcheck( *b, *a) );
}

void DLLEXPORT q_sort(
	char   *buf, short  *buf_ind,
	char    chr, short   chr_ind,
	int     mod, short   mod_ind
		   )
{
  if ((*buf_ind==(short)OCI_IND_NULL)||(strlen(buf)<2) ) return;
  else {
	char **list;
	char  *str;
	char  *bf= strdup(buf);
	char   ch[2] = "\n";
    int    i;
	int    l = 0;
	int    n = 0;
	size_t sz= 1000*sizeof(char *);

	if (chr_ind==(short)OCI_IND_NOTNULL) ch[0] = chr;
	if (mod_ind==(short)OCI_IND_NOTNULL) sortflag = mod; else sortflag = 1;
	str = bf;
	list= (char **) malloc (sz);
	*list = str;
	while ( str=strchr(str,ch[0]) ) {
	  str[0] = 0;
	  str += 1;
	  if (str[0]) {
		n++;
		if ( (n%1000)==0 ) {
		  sz += 1000*sizeof(char *);
		  list = (char **) realloc(list,sz);
		}
		*(list + n) = str;
	  } else {
		l = 1;
		break;
	  }
	}
	if (n) {
	  qsort(list, n+1, sizeof(char *),
		 (int(*)(const void *,const void *))sort_func);
	  buf[0] = 0;
	  for ( i=0; i<=n; i++) {
		strcat(buf,*(list+i));
		if ( (i<n)||(l) ) strcat(buf,(char *)&ch);
	  }
	}
	free(list);
	free(bf);
  }
}

int DLLEXPORT f_truncate(int  h,short h_ind,
	unsigned char *f, short  f_ind,
	long    length, short  length_ind,
	short *return_ind
    )
{ int l = 0;
  long sz = 0;
  if ( (f_ind==(short)OCI_IND_NULL)||(h_ind==(short)OCI_IND_NULL)
     ||(check_init()) ) *return_ind = (short)OCI_IND_NULL;
  else {
	FIOFILE *ff;
	memcpy( &ff,f,sizeof(ff) );
	if (h!=ff->handle) l=FIO_HANDLE_ERR;
	else {
		if ( (length_ind==(short)OCI_IND_NOTNULL) && (length>0) ) sz = length;
		l = ftruncate(ff->handle,sz);
		if(l == -1) l=-errno;
	}
	if ( l==0 )
      write_log(3,"MSG","FTruncate",ff->name,"size:",length,"handle",l_toa(h,0),NULL);
	else
      write_log(0,"ERR","FTruncate",l_toa(h,0),"error:",-l,errmsg(l),NULL,NULL);
	*return_ind = (short)OCI_IND_NOTNULL;
  }
  return l;
}

int DLLEXPORT f_tells(
	int				h,	short	h_ind,
	unsigned char	*f,	short	f_ind,
	char   *pos, short *pos_ind, size_t *pos_len, size_t  *pos_max,
	short			*ret_ind
	)
{	int l = 0;
  memset( pos,  0, *pos_max );
  *pos_len  = 0;
  *pos_ind  = (short)OCI_IND_NULL;
	if ( (f_ind==(short)OCI_IND_NULL) || (h_ind==(short)OCI_IND_NULL) || (check_init()) )
		*ret_ind = (short)OCI_IND_NULL;
	else {
		long p;
		FIOFILE *ff;
		memcpy( &ff,f,sizeof(ff) );
		if (h!=ff->handle) l = FIO_HANDLE_ERR;
		else if ( (p = ftell(ff->f)) >= 0) {
			l_toa(p,0);;
			if ( strlen(sbuf) < *pos_max ) {
				strcpy(pos,sbuf);
				*pos_len = strlen(sbuf);
				*pos_ind = (short)OCI_IND_NOTNULL;
			} else l = BUF_OVERFLOW_ERR;
		} else l = -errno;
		if (l < 0)
			write_log(0,"ERR","FTell",l_toa(h,0),"error:",-l,errmsg(l),NULL,NULL);
		else
			write_log(3,"MSG","FTell",ff->name,"handle:",h,"position",pos,NULL);
		*ret_ind = (short)OCI_IND_NOTNULL;
	}
	return l;
}

int DLLEXPORT f_tell(
	int				h,	short	h_ind,
	unsigned char	*f,	short	f_ind,
	short			*ret_ind
	)
{ int l = 0;
	char	p[100];
	short	pind;
	size_t	plen,pmax=100;
	l = f_tells(h,h_ind,f,f_ind,p,&pind,&plen,&pmax,ret_ind);
	if ( plen > 0 )	l = atol(p);
  return l;
}
/*
int main(int argc, char **argv)
{ long pid;
  short res;
	pid = fio_init(
    "123", OCI_IND_NOTNULL, //char   *asid,     short   asid_ind,
	"/dka0/oracle/tools/fio/AAA.LOG", OCI_IND_NOTNULL, //char   *logname,  short   logname_ind,
	"/dka0/oracle/tools/utlfile", OCI_IND_NOTNULL, //char   *rootdir,  short   rootdir_ind,
	"<CHECK_ROOT>;/dka0/oracle/tools/temp", OCI_IND_NOTNULL, //char   *basedir,  short   basedir_ind,
	"XXX", OCI_IND_NOTNULL, //char   *execcmd,  short   execcmd_ind,
	-5, OCI_IND_NOTNULL, //int     dlevel,   short   dlevel_ind,
	&res //short  *ret_ind
			 );
    sprintf(fbuf,"%d - %d\n%s\n%s\n",pid,res,getenv(ROOT_DIR),getenv(BASE_DIR));
    write(hlog,&fbuf,strlen(fbuf));
	f_copy("/dka0/oracle/tools/utlfile/fio.h",OCI_IND_NOTNULL,
		"/dka0/oracle/tools/utlfile/fio1.h",OCI_IND_NOTNULL,
		1,OCI_IND_NOTNULL,1,OCI_IND_NOTNULL,&res);
    sprintf(fbuf,"%d - %d\n",pid,res);
    write(hlog,&fbuf,strlen(fbuf));
	fio_close();
}
*/

