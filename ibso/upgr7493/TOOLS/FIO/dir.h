#include <io.h>
# define PATH_MAX 400
# define S_IRWXU S_IREAD|S_IWRITE|S_IEXEC
# define S_IRUSR S_IREAD
# define S_IWUSR S_IWRITE
# define S_IXUSR S_IEXEC

typedef struct DIR
{
	long   handle;
	char  *name;
	struct _finddata_t *entry;
} DIR;

struct dirent
{
	char *d_name;   
};

DIR *opendir(const char *dirname);

struct dirent *readdir(DIR *dirp);

int closedir(DIR *dirp); 

void rewinddir(DIR *dirp);

