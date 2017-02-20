prompt fio body
CREATE OR REPLACE PACKAGE BODY
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/fio2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
fio is
--
sc_logging  boolean;
--
procedure init is
s varchar2(100);
begin
  select value into s from settings where name='SCRIPTS_LOGGING';
  sc_logging:= substr(nvl(s,'NO'),1,1) in ('Y','1');
exception when NO_DATA_FOUND then sc_logging:= false;
end;
--
function  open$(logname varchar2, rootdir varchar2, basedir varchar2,
               execcmd varchar2, uid varchar2, dlevel  pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "fio_init" LIBRARY libfio
    PARAMETERS (uid                STRING,
                uid      INDICATOR SHORT,
                logname            STRING,
                logname  INDICATOR SHORT,
                rootdir            STRING,
                rootdir  INDICATOR SHORT,
                basedir            STRING,
                basedir  INDICATOR SHORT,
                execcmd            STRING,
                execcmd  INDICATOR SHORT,
                dlevel             INT,
                dlevel   INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
--
function  open(logname varchar2, rootdir varchar2, basedir varchar2,
               execcmd varchar2, uid varchar2, dlevel  pls_integer) return pls_integer
  IS
begin
  init;
  return open$(logname, rootdir, basedir,execcmd, uid, dlevel);
end;
--
procedure close
  IS LANGUAGE C
    NAME "fio_close" LIBRARY libfio;
--
procedure err_msg(err pls_integer, msg in out nocopy varchar2)
  IS LANGUAGE C
    NAME "err_msg" LIBRARY libfio
    PARAMETERS (err                INT,
                err      INDICATOR SHORT,
                msg                STRING,
                msg      INDICATOR SHORT,
                msg      LENGTH    SIZE_T,
                msg      MAXLEN    SIZE_T);
--
function flist(dirname varchar2, ldir in out nocopy varchar2,
               chkflag boolean,  dirflag pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "f_list" LIBRARY libfio
    PARAMETERS (dirname            STRING,
                dirname  INDICATOR SHORT,
                ldir               STRING,
                ldir     INDICATOR SHORT,
                ldir     LENGTH    SIZE_T,
                ldir     MAXLEN    SIZE_T,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                dirflag            INT,
                dirflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function frename(oldname varchar2, newname varchar2,
                 chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "f_rename" LIBRARY libfio
    PARAMETERS (oldname            STRING,
                oldname  INDICATOR SHORT,
                newname            STRING,
                newname  INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  fcopy  (oldname varchar2, newname varchar2,
                  wrflag  boolean,  chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "f_copy" LIBRARY libfio
    PARAMETERS (oldname            STRING,
                oldname  INDICATOR SHORT,
                newname            STRING,
                newname  INDICATOR SHORT,
                wrflag             INT,
                wrflag   INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
function  fcopy  (oldname varchar2, newname varchar2,
                  wrflag  boolean,  chkflag boolean,fsize in out nocopy varchar2) return pls_integer
  IS LANGUAGE C
    NAME "f_copys" LIBRARY libfio
    PARAMETERS (oldname            STRING,
                oldname  INDICATOR SHORT,
                newname            STRING,
                newname  INDICATOR SHORT,
                wrflag             INT,
                wrflag   INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                fsize              STRING,
                fsize    INDICATOR SHORT,
                fsize    LENGTH    SIZE_T,
                fsize    MAXLEN    SIZE_T,
                return   indicator short,
                RETURN             LONG);
function  fremove(path varchar2, chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "f_remove" LIBRARY libfio
    PARAMETERS (path               STRING,
                path     INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  mkdir(path varchar2, accs pls_integer, chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "f_mkdir" LIBRARY libfio
    PARAMETERS (path               STRING,
                path     INDICATOR SHORT,
                accs               INT,
                accs     INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  hcreate$(path varchar2, accs pls_integer, chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "h_creat" LIBRARY libfio
    PARAMETERS (path               STRING,
                path     INDICATOR SHORT,
                accs               INT,
                accs     INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  hopen$ (path varchar2,  oflag pls_integer, chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "h_open" LIBRARY libfio
    PARAMETERS (path               STRING,
                path     INDICATOR SHORT,
                oflag              INT,
                oflag    INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  hclose$(handle pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "h_close" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  hseek (handle pls_integer, position pls_integer, seekflag pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "h_seek" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                position           LONG,
                position INDICATOR SHORT,
                seekflag           INT,
                seekflag INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
function  hseek (handle pls_integer, position pls_integer, seekflag pls_integer, newpos in out nocopy varchar2) return pls_integer
  IS LANGUAGE C
    NAME "h_seeks" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                position           LONG,
                position INDICATOR SHORT,
                seekflag           INT,
                seekflag INDICATOR SHORT,
                newpos             STRING,
                newpos   INDICATOR SHORT,
                newpos   LENGTH    SIZE_T,
                newpos   MAXLEN    SIZE_T,
                return   indicator short,
                RETURN             LONG);
function  hread (handle pls_integer, buf in out nocopy raw, nbytes pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "h_read" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                buf                RAW,
                buf      INDICATOR SHORT,
                buf      LENGTH    SIZE_T,
                buf      MAXLEN    SIZE_T,
                nbytes             SIZE_T,
                nbytes   INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
function  hwrite(handle pls_integer, buf raw, nbytes pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "h_write" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                buf                RAW,
                buf      INDICATOR SHORT,
                buf      LENGTH    SIZE_T,
                nbytes             SIZE_T,
                nbytes   INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
function  get_env (name varchar2, buf in out nocopy varchar2) return pls_integer
  IS LANGUAGE C
    NAME "get_env" LIBRARY libfio
    PARAMETERS (name               STRING,
                name     INDICATOR SHORT,
                buf                STRING,
                buf      INDICATOR SHORT,
                buf      LENGTH    SIZE_T,
                buf      MAXLEN    SIZE_T,
                return   indicator short,
                RETURN             INT);
function  put_env (name varchar2, buf varchar2) return pls_integer
  IS LANGUAGE C
    NAME "put_env" LIBRARY libfio
    PARAMETERS (name               STRING,
                name     INDICATOR SHORT,
                buf                STRING,
                buf      INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
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
              a9  varchar2) return pls_integer
  IS LANGUAGE C
    NAME "f_run" LIBRARY libfio
    PARAMETERS (cmd                STRING,
                cmd      INDICATOR SHORT,
                a0                 STRING,
                a0       INDICATOR SHORT,
                a1                 STRING,
                a1       INDICATOR SHORT,
                a2                 STRING,
                a2       INDICATOR SHORT,
                a3                 STRING,
                a3       INDICATOR SHORT,
                a4                 STRING,
                a4       INDICATOR SHORT,
                a5                 STRING,
                a5       INDICATOR SHORT,
                a6                 STRING,
                a6       INDICATOR SHORT,
                a7                 STRING,
                a7       INDICATOR SHORT,
                a8                 STRING,
                a8       INDICATOR SHORT,
                a9                 STRING,
                a9       INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  fopen$ (path varchar2, fmode varchar2, f in out nocopy raw, chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "f_open" LIBRARY libfio
    PARAMETERS (path               STRING,
                path     INDICATOR SHORT,
                fmode              STRING,
                fmode    INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                f        LENGTH    SIZE_T,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  fdopen (handle pls_integer, fmode varchar2, f in out nocopy raw) return pls_integer
  IS LANGUAGE C
    NAME "f_dopen" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                fmode              STRING,
                fmode    INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                f        LENGTH    SIZE_T,
                return   indicator short,
                RETURN             INT);
function  fclose$(handle pls_integer, f raw) return pls_integer
  IS LANGUAGE C
    NAME "f_close" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  fflush(handle pls_integer, f raw) return pls_integer
  IS LANGUAGE C
    NAME "f_flush" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  fseek (handle pls_integer, f raw, position pls_integer, seekflag pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "f_seek" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                position           LONG,
                position INDICATOR SHORT,
                seekflag           INT,
                seekflag INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
function  fseek (handle pls_integer, f raw, position pls_integer, seekflag pls_integer, newpos in out nocopy varchar2) return pls_integer
  IS LANGUAGE C
    NAME "f_seeks" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                position           LONG,
                position INDICATOR SHORT,
                seekflag           INT,
                seekflag INDICATOR SHORT,
                newpos             STRING,
                newpos   INDICATOR SHORT,
                newpos   LENGTH    SIZE_T,
                newpos   MAXLEN    SIZE_T,
                return   indicator short,
                RETURN             LONG);
function  fread (handle pls_integer, f raw, buf in out nocopy raw, nbytes pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "f_read" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                buf                RAW,
                buf      INDICATOR SHORT,
                buf      LENGTH    SIZE_T,
                buf      MAXLEN    SIZE_T,
                nbytes             SIZE_T,
                nbytes   INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
function  fwrite(handle pls_integer, f raw, buf raw, nbytes pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "f_write" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                buf                RAW,
                buf      INDICATOR SHORT,
                buf      LENGTH    SIZE_T,
                nbytes             SIZE_T,
                nbytes   INDICATOR SHORT,
                return   indicator short,
                RETURN             LONG);
procedure qsort (buf in out nocopy varchar2, p_chr pls_integer, p_mode boolean)
  IS LANGUAGE C
    NAME "q_sort" LIBRARY libfio
    PARAMETERS (buf                STRING,
                buf      INDICATOR SHORT,
                p_chr              CHAR,
                p_chr    INDICATOR SHORT,
                p_mode             INT,
                p_mode   INDICATOR SHORT);
function  finfo (name varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy pls_integer,
                 chkflag   boolean
                ) return pls_integer
  IS LANGUAGE C
    NAME "f_info" LIBRARY libfio
    PARAMETERS (name               STRING,
                name     INDICATOR SHORT,
                attrs              STRING,
                attrs    INDICATOR SHORT,
                attrs    LENGTH    SIZE_T,
                attrs    MAXLEN    SIZE_T,
                uowner             STRING,
                uowner   INDICATOR SHORT,
                uowner   LENGTH    SIZE_T,
                uowner   MAXLEN    SIZE_T,
                gowner             STRING,
                gowner   INDICATOR SHORT,
                gowner   LENGTH    SIZE_T,
                gowner   MAXLEN    SIZE_T,
                mdate              STRING,
                mdate    INDICATOR SHORT,
                mdate    LENGTH    SIZE_T,
                mdate    MAXLEN    SIZE_T,
                fsize              LONG,
                fsize    INDICATOR SHORT,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  finfo (name varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy varchar2,
                 chkflag   boolean
                ) return pls_integer
  IS LANGUAGE C
    NAME "f_infos" LIBRARY libfio
    PARAMETERS (name               STRING,
                name     INDICATOR SHORT,
                attrs              STRING,
                attrs    INDICATOR SHORT,
                attrs    LENGTH    SIZE_T,
                attrs    MAXLEN    SIZE_T,
                uowner             STRING,
                uowner   INDICATOR SHORT,
                uowner   LENGTH    SIZE_T,
                uowner   MAXLEN    SIZE_T,
                gowner             STRING,
                gowner   INDICATOR SHORT,
                gowner   LENGTH    SIZE_T,
                gowner   MAXLEN    SIZE_T,
                mdate              STRING,
                mdate    INDICATOR SHORT,
                mdate    LENGTH    SIZE_T,
                mdate    MAXLEN    SIZE_T,
                fsize              STRING,
                fsize    INDICATOR SHORT,
                fsize    LENGTH    SIZE_T,
                fsize    MAXLEN    SIZE_T,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  opendir( dirname varchar2, mask varchar2, dirflag pls_integer, f in out nocopy raw, chkflag boolean) return pls_integer
  IS LANGUAGE C
    NAME "dir_open" LIBRARY libfio
    PARAMETERS (dirname            STRING,
                dirname  INDICATOR SHORT,
                dirflag            INT,
                dirflag  INDICATOR SHORT,
                mask               STRING,
                mask    INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                f        LENGTH    SIZE_T,
                chkflag            INT,
                chkflag  INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  closedir(handle pls_integer, f raw ) return pls_integer
    IS LANGUAGE C
      NAME "dir_close" LIBRARY libfio
      PARAMETERS (handle             INT,
                  handle   INDICATOR SHORT,
                  f                  RAW,
                  f        INDICATOR SHORT,
                  return   indicator short,
                  RETURN             INT);
function  resetdir(handle pls_integer, f raw ) return pls_integer
    IS LANGUAGE C
      NAME "dir_reset" LIBRARY libfio
      PARAMETERS (handle             INT,
                  handle   INDICATOR SHORT,
                  f                  RAW,
                  f        INDICATOR SHORT,
                  return   indicator short,
                  RETURN             INT);
function  readdir( handle pls_integer, f raw,
                   name   in out nocopy varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy pls_integer
                   ) return pls_integer
  IS LANGUAGE C
    NAME "dir_read" LIBRARY libfio
      PARAMETERS (handle             INT,
                  handle   INDICATOR SHORT,
                  f                  RAW,
                  f        INDICATOR SHORT,
                  name               STRING,
                  name     INDICATOR SHORT,
                  name     LENGTH    SIZE_T,
                  name     MAXLEN    SIZE_T,
                  attrs              STRING,
                  attrs    INDICATOR SHORT,
                  attrs    LENGTH    SIZE_T,
                  attrs    MAXLEN    SIZE_T,
                  uowner             STRING,
                  uowner   INDICATOR SHORT,
                  uowner   LENGTH    SIZE_T,
                  uowner   MAXLEN    SIZE_T,
                  gowner             STRING,
                  gowner   INDICATOR SHORT,
                  gowner   LENGTH    SIZE_T,
                  gowner   MAXLEN    SIZE_T,
                  mdate              STRING,
                  mdate    INDICATOR SHORT,
                  mdate    LENGTH    SIZE_T,
                  mdate    MAXLEN    SIZE_T,
                  fsize              LONG,
                  fsize    INDICATOR SHORT,
                  return   indicator short,
                  RETURN             LONG);
function  readdir( handle pls_integer, f raw,
                   name   in out nocopy varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy varchar2
                   ) return pls_integer
  IS LANGUAGE C
    NAME "dir_reads" LIBRARY libfio
      PARAMETERS (handle             INT,
                  handle   INDICATOR SHORT,
                  f                  RAW,
                  f        INDICATOR SHORT,
                  name               STRING,
                  name     INDICATOR SHORT,
                  name     LENGTH    SIZE_T,
                  name     MAXLEN    SIZE_T,
                  attrs              STRING,
                  attrs    INDICATOR SHORT,
                  attrs    LENGTH    SIZE_T,
                  attrs    MAXLEN    SIZE_T,
                  uowner             STRING,
                  uowner   INDICATOR SHORT,
                  uowner   LENGTH    SIZE_T,
                  uowner   MAXLEN    SIZE_T,
                  gowner             STRING,
                  gowner   INDICATOR SHORT,
                  gowner   LENGTH    SIZE_T,
                  gowner   MAXLEN    SIZE_T,
                  mdate              STRING,
                  mdate    INDICATOR SHORT,
                  mdate    LENGTH    SIZE_T,
                  mdate    MAXLEN    SIZE_T,
                  fsize              STRING,
                  fsize    INDICATOR SHORT,
                  fsize    LENGTH    SIZE_T,
                  fsize    MAXLEN    SIZE_T,
                  return   indicator short,
                  RETURN             LONG);
function  ftell(handle pls_integer, f raw) return pls_integer
  IS LANGUAGE C
    NAME "f_tell" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  ftell(handle pls_integer, f raw, pos in out nocopy varchar2) return pls_integer
  IS LANGUAGE C
    NAME "f_tells" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                pos                STRING,
                pos      INDICATOR SHORT,
                pos      LENGTH    SIZE_T,
                pos      MAXLEN    SIZE_T,
                return   indicator short,
                RETURN             INT);
function  ftruncate(handle pls_integer, f raw, p_size pls_integer) return pls_integer
  IS LANGUAGE C
    NAME "f_truncate" LIBRARY libfio
    PARAMETERS (handle             INT,
                handle   INDICATOR SHORT,
                f                  RAW,
                f        INDICATOR SHORT,
                p_size             LONG,
                p_size   INDICATOR SHORT,
                return   indicator short,
                RETURN             INT);
function  hcreate(path varchar2, accs pls_integer, chkflag boolean) return pls_integer is
res pls_integer;
begin
  res:=hcreate$(path, accs, chkflag);
  if res>=0 and sc_logging then
    sc_mgr.log_open_file(res,path,1);
  end if;
  return res;
end;
function  hopen (path varchar2,  oflag pls_integer, chkflag boolean) return pls_integer is
res pls_integer;
begin
  res:=hopen$(path,  oflag, chkflag);
  if res>=0 and sc_logging then
    sc_mgr.log_open_file(res,path,oflag);
  end if;
  return res;
end;
function  hclose(handle pls_integer) return pls_integer is
res pls_integer;
begin
  res:=hclose$(handle);
  if res>=0 and sc_logging then
    sc_mgr.log_close_file(handle);
  end if;
  return res;
end;
function  fopen (path varchar2, fmode varchar2, f in out nocopy raw, chkflag boolean) return pls_integer is
res pls_integer;
begin
  res:=fopen$(path, fmode, f, chkflag);
  if res>=0 and sc_logging then
    sc_mgr.log_open_file(res,path,fmode);
  end if;
  return res;
end;
function  fclose(handle pls_integer, f raw) return pls_integer is
res pls_integer;
begin
  res:=fclose$(handle,f);
  if res>=0 and sc_logging  then
    sc_mgr.log_close_file(handle);
  end if;
  return res;
end;
begin
  init;
END fio;
/
sho err package body fio

