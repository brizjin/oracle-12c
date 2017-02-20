prompt fio
CREATE OR REPLACE PACKAGE fio IS
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/fio1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
    function  open(logname varchar2, rootdir varchar2, basedir varchar2,
                   execcmd varchar2, uid varchar2, dlevel  pls_integer) return pls_integer;
    procedure close;
    procedure err_msg(err pls_integer, msg in out nocopy varchar2);
    function  flist(dirname varchar2, ldir in out nocopy varchar2,
                    chkflag boolean,  dirflag pls_integer) return pls_integer;
    function  frename(oldname varchar2, newname varchar2,
                      chkflag boolean) return pls_integer;
    function  fcopy  (oldname varchar2, newname varchar2,
                      wrflag  boolean,  chkflag boolean) return pls_integer;
    function  fcopy  (oldname varchar2, newname varchar2,
                      wrflag  boolean,  chkflag boolean,fsize in out nocopy varchar2) return pls_integer;
    function  fremove(path varchar2,chkflag boolean) return pls_integer;
    function  mkdir(path varchar2, accs pls_integer, chkflag boolean) return pls_integer;
    function  hcreate(path varchar2, accs pls_integer, chkflag boolean) return pls_integer;
    function  hopen (path varchar2,  oflag pls_integer, chkflag boolean) return pls_integer;
    function  hclose(handle pls_integer) return pls_integer;
    function  hseek (handle pls_integer, position pls_integer, seekflag pls_integer) return pls_integer;
    function  hseek (handle pls_integer, position pls_integer, seekflag pls_integer, newpos in out nocopy varchar2) return pls_integer;
    function  hread (handle pls_integer, buf in out nocopy raw, nbytes pls_integer) return pls_integer;
    function  hwrite(handle pls_integer, buf raw, nbytes pls_integer) return pls_integer;
    function  get_env (name varchar2, buf in out nocopy varchar2) return pls_integer;
    function  put_env (name varchar2, buf varchar2) return pls_integer;
    function  run(cmd varchar2,
                  a0  varchar2,
                  a1  varchar2,
                  a2  varchar2,
                  a3  varchar2,
                  a4  varchar2,
                  a5  varchar2,
                  a6  varchar2,
                  a7  varchar2,
                  a8  varchar2,
                  a9  varchar2) return pls_integer;
    function  fopen (path varchar2, fmode varchar2, f in out nocopy raw, chkflag boolean) return pls_integer;
    function  fdopen(handle pls_integer, fmode varchar2, f in out nocopy raw) return pls_integer;
    function  fclose(handle pls_integer, f raw) return pls_integer;
    function  fflush(handle pls_integer, f raw) return pls_integer;
    function  fseek (handle pls_integer, f raw, position pls_integer, seekflag pls_integer) return pls_integer;
    function  fseek (handle pls_integer, f raw, position pls_integer, seekflag pls_integer, newpos in out nocopy varchar2) return pls_integer;
    function  fread (handle pls_integer, f raw, buf in out nocopy raw, nbytes pls_integer) return pls_integer;
    function  fwrite(handle pls_integer, f raw, buf raw, nbytes pls_integer) return pls_integer;
    procedure qsort (buf in out nocopy varchar2, p_chr pls_integer, p_mode boolean);
    function  finfo (name varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy pls_integer,
                     chkflag   boolean
                    ) return pls_integer;
    function  finfo (name varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy varchar2,
                     chkflag   boolean
                    ) return pls_integer;
    function  opendir( dirname varchar2, mask varchar2, dirflag pls_integer, f in out nocopy raw, chkflag boolean) return pls_integer;
    function  closedir(handle pls_integer, f raw ) return pls_integer;
    function  resetdir(handle pls_integer, f raw ) return pls_integer;
    function  readdir( handle pls_integer, f raw,
                       name   in out nocopy varchar2,
                       attrs  in out nocopy varchar2,
                       uowner in out nocopy varchar2,
                       gowner in out nocopy varchar2,
                       mdate  in out nocopy varchar2,
                       fsize  in out nocopy pls_integer
                     ) return pls_integer;
    function  readdir( handle pls_integer, f raw,
                       name   in out nocopy varchar2,
                       attrs  in out nocopy varchar2,
                       uowner in out nocopy varchar2,
                       gowner in out nocopy varchar2,
                       mdate  in out nocopy varchar2,
                       fsize  in out nocopy varchar2
                     ) return pls_integer;
    function  ftell(handle pls_integer, f raw) return pls_integer;
    function  ftell(handle pls_integer, f raw, pos in out nocopy varchar2) return pls_integer;
    function  ftruncate(handle pls_integer, f raw, p_size pls_integer) return pls_integer;
end fio;
/
show errors

