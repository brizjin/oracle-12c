#include <io.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "dir.h"

extern int errno;
struct dirent dentry;
char   dbuf[PATH_MAX];

DIR *opendir(const char *dirname)
{
	DIR	*fdir;
	long	handle;
	struct _finddata_t *entry;

	fdir = NULL;
	entry = (struct _finddata_t*) malloc ( sizeof(struct _finddata_t) );
	strcpy((char *)&dbuf,dirname);
	strcat((char *)&dbuf,"\\*");
	dentry.d_name = "";
	handle = _findfirst((char *)&dbuf,entry);
	if (handle!=-1) {
		fdir = (DIR *) malloc ( sizeof(DIR) );
		fdir->name = strdup((char *)&dbuf);
		fdir->entry = entry;
		fdir->handle= handle;
	} else free(entry);
	return fdir;
}

int closedir(DIR *dirp)
{
	int l = 0;
	if (dirp) {
		l=_findclose( dirp->handle );
		if (l==0) {
			free( dirp->name );
			free( dirp->entry );
			free( dirp );
		}
	}
	dentry.d_name = "";
	return l;
}

struct dirent *readdir(DIR *dirp)
{
	if (dirp) {
		strcpy((char *)&dbuf,dirp->entry->name);
		dentry.d_name = (char *)&dbuf;
		if (strlen(dentry.d_name)==0) return NULL;
		if (_findnext( dirp->handle, dirp->entry )!=0)
			strcpy(dirp->entry->name,"");
		return (struct dirent*) &dentry;
	} else {
		errno = EBADF;
		return NULL;
	}
}

void rewinddir(DIR *dirp)
{
  if (dirp) 
	if ( !_findclose( dirp->handle ) ) 
	  dirp->handle = _findfirst(dirp->name,dirp->entry);
  dentry.d_name= "";
}

