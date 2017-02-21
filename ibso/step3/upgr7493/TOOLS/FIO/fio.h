/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/fio.h $
 *  $Author: Alexey $
 *  $Revision: 15082 $
 *  $Date:: 2012-03-06 17:34:34 #$
 */
#ifdef WIN32COMMON
# define DLLEXPORT __declspec(dllexport)
#else
# define DLLEXPORT
#endif
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

long DLLEXPORT fio_init(
    char   *asid,     short   asid_ind,
	char   *logname,  short   logname_ind,
	char   *rootdir,  short   rootdir_ind,
	char   *basedir,  short   basedir_ind,
	char   *execcmd,  short   execcmd_ind,
	int     dlevel,   short   dlevel_ind,
	short  *ret_ind
			 );

void DLLEXPORT fio_close(void);

int DLLEXPORT f_list(
	char   *dirname,  short   dirname_ind,
	char   *ldir,     short  *ldir_ind,
	size_t *ldir_len, size_t *ldir_max,
	int     chkflag,  short   chkflag_ind,
	int     dirflag,  short   dirflag_ind,
	short  *ret_ind
		   );

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
		   );

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
		   );

int DLLEXPORT dir_open(
	char   *dirname,  short   dirname_ind,
	int     dirflag,  short   dirflag_ind,
	char   *mask,  short mask_ind,
	unsigned char *f, short *f_ind, size_t *f_len,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
		  );

int DLLEXPORT dir_close(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   );

int DLLEXPORT dir_reset(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   );

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
		   );

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
		   );

void DLLEXPORT err_msg(
	int     err,  short   err_ind,
	char   *mes,  short  *mes_ind,
	size_t *mes_len, size_t *mes_max
			 );

int DLLEXPORT f_rename(
	char   *oldname,  short   oldname_ind,
	char   *newname,  short   newname_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			 );

int DLLEXPORT f_remove(
	char   *path,    short   path_ind,
	int     chkflag, short   chkflag_ind,
	short  *ret_ind
			 );

int DLLEXPORT f_mkdir(
	char   *path, short   path_ind,
	int     mode, short   mode_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			);

int DLLEXPORT h_creat(
	char   *path, short   path_ind,
	int     mode, short   mode_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			);

int DLLEXPORT h_open(
	char   *path, short   path_ind,
	int     mode, short   mode_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
		   );

int DLLEXPORT h_close(
	int     handle, short   handle_ind,
	short  *ret_ind
			);

long DLLEXPORT h_read(
	int	    f, short  f_ind,
	unsigned char *buf, short *buf_ind,
	size_t *buf_len,  size_t  *buf_max,
	size_t  n, short  n_ind,
	short *return_ind
		   );

long DLLEXPORT h_write(
	int	    f, short  f_ind,
	unsigned char *buf, short buf_ind,	size_t buf_len,
	size_t  n, short  n_ind,
	short *return_ind
			);

long DLLEXPORT h_seeks(
	int	    f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	char   *pos, short *pos_ind, size_t *pos_len, size_t  *pos_max,
	short  *return_ind
			);

long DLLEXPORT h_seek(
	int	    f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	short *return_ind
			);

int DLLEXPORT get_env(
	char *name, short  name_ind,
	char *buf,  short *buf_ind,
	size_t *buf_len,  size_t  *buf_max,
	short *ret_ind
		   );

int DLLEXPORT put_env(
	char *name, short  name_ind,
	char *buf,  short  buf_ind,
	short *ret_ind
		   );

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
		  );

long DLLEXPORT f_copys(
	char   *oldname,  short   oldname_ind,
	char   *newname,  short   newname_ind,
	int     wrflag,   short   wrflag_ind,
	int     chkflag,  short   chkflag_ind,
	char   *siz, short *siz_ind, size_t *siz_len, size_t  *siz_max,
	short  *ret_ind
			 );

long DLLEXPORT f_copy(
	char   *oldname,  short   oldname_ind,
	char   *newname,  short   newname_ind,
	int		wrflag,   short   wrflag_ind,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
			 );

int DLLEXPORT f_open(
	char   *path,  short path_ind,
	char   *mode,  short mode_ind,
	unsigned char *f, short *f_ind, size_t *f_len,
	int     chkflag,  short   chkflag_ind,
	short  *ret_ind
		  );

int DLLEXPORT f_close(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   );

long DLLEXPORT f_read(
	int	    h, short  h_ind,
	unsigned char *f,   short  f_ind,
	unsigned char *buf, short *buf_ind,
	size_t *buf_len,  size_t  *buf_max,
	size_t  n, short  n_ind,
	short *return_ind
		   );

long DLLEXPORT f_write(
	int	    h, short  h_ind,
	unsigned char *f,   short  f_ind,
	unsigned char *buf, short buf_ind,	size_t buf_len,
	size_t  n, short  n_ind,
	short *return_ind
			);

long DLLEXPORT f_seeks(
	int	    h, short  h_ind,
	unsigned char *f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	char   *pos, short *pos_ind, size_t *pos_len, size_t  *pos_max,
	short  *return_ind
			);

long DLLEXPORT f_seek(
	int	    h, short  h_ind,
	unsigned char *f, short  f_ind,
	long    n, short  n_ind,
	int	    w, short  w_ind,
	short *return_ind
			);

int DLLEXPORT f_flush(
	int      h,  short h_ind,
	unsigned char *f, short f_ind,
	short *ret_ind
		   );

int DLLEXPORT f_dopen(
	int      h,   short h_ind,
	char   *mode, short mode_ind,
	unsigned char *f, short *f_ind, size_t *f_len,
	short  *ret_ind
		   );

void DLLEXPORT q_sort(
	char   *buf, short  *buf_ind,
	char    chr, short   chr_ind,
	int     mod, short   mod_ind
		   );

int DLLEXPORT f_truncate(
    int				h,		short	h_ind,
    unsigned char	*f,		short	f_ind,
	long			length,	short	length_ind,
	short			*return_ind
	);

int DLLEXPORT f_tells(
	int				h,	short	h_ind,
	unsigned char	*f,	short	f_ind,
	char   *pos, short *pos_ind, size_t *pos_len, size_t  *pos_max,
	short			*ret_ind
	);

int DLLEXPORT f_tell(
	int				h,	short	h_ind,
	unsigned char	*f,	short	f_ind,
	short			*ret_ind
	);

#ifdef __cplusplus
}
#endif

