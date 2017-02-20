prompt vfs_io
create or replace
package vfs_io is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_io1.sql $
 *  $Author: Alexey $
 *  $Revision: 15082 $
 *  $Date:: 2012-03-06 17:34:34 #$
 */
--
    DOSTEXT   constant pls_integer := 1;
    UNXTEXT   constant pls_integer := 2;
    WINTEXT   constant pls_integer := 3;
    KOITEXT   constant pls_integer := 4;
--
    INVALID_PATH       exception;
    INVALID_MODE       exception;
    INVALID_FILEHANDLE exception;
    INVALID_OPERATION  exception;
    INVALID_LINESIZE   exception;
    READ_ERROR         exception;
    WRITE_ERROR        exception;
--
    function  transform(txt      in varchar2,
                        in_text  in pls_integer,
                        out_text in pls_integer ) return varchar2 deterministic;
    pragma restrict_references(transform,WNDS,WNPS,TRUST);
    procedure set_def_text( p_txt      varchar2,
                            p_slash    varchar2 default null,
                            p_add_cr   varchar2 default null,
                            p_name_txt varchar2 default null );
--
    procedure set_size(line_size in  pls_integer default null);
    procedure get_size(line_size out nocopy pls_integer);
--
    function  open ( location  IN varchar2,
                     filename  IN varchar2,
                     open_mode IN varchar2,
                     raising   IN boolean default FALSE,
                     line_size IN pls_integer default NULL,
                     name_text IN pls_integer default NULL
                     ) return pls_integer;
    procedure close ( file  IN OUT nocopy pls_integer,
                      raising  IN boolean default FALSE );
    function  is_open ( file   IN pls_integer ) return boolean;
    procedure flush ( file     IN pls_integer,
                      raising  IN boolean default FALSE );
    procedure fput  ( file     IN pls_integer,
                      buffer   IN varchar2,
                      raising  IN boolean default FALSE,
                      p_flash  IN boolean default FALSE );
    procedure putf  ( file     IN pls_integer,
                      format   IN varchar2,
                      raising  IN boolean  default FALSE,
                      in_text  IN pls_integer default NULL,
                      out_text IN pls_integer default NULL,
                      p_text1  IN varchar2 default NULL,
                      p_text2  IN varchar2 default NULL,
                      p_text3  IN varchar2 default NULL,
                      p_text4  IN varchar2 default NULL,
                      p_text5  IN varchar2 default NULL );
    procedure put_line ( file     IN pls_integer,
                         buffer   IN varchar2,
                         raising  IN boolean default FALSE,
                         in_text  IN pls_integer default NULL,
                         out_text IN pls_integer default NULL );
    function get_line ( file     IN  pls_integer,
                        buffer   OUT nocopy varchar2,
                        raising  IN  boolean default FALSE,
                        in_text  IN  pls_integer default NULL,
                        out_text IN  pls_integer default NULL,
                        l_size   IN  pls_integer default NULL ) return boolean;
--
    procedure io_open;
    procedure io_close;
    procedure check_open;
    procedure fio_open;
    procedure fio_close;
    function  get_fio_pid return pls_integer;
--
    function  file_list ( location IN varchar2, dir_flag pls_integer default 0,
                          p_sort boolean default null, p_chk boolean default false,
                          name_text pls_integer default NULL) return varchar2;
    procedure move_file ( old_name IN varchar2,
                          new_name IN varchar2, p_chk boolean default false,
                          name_text   pls_integer default NULL);
    procedure delete_file ( file_name IN varchar2, p_chk boolean default false,
                            name_text IN pls_integer default NULL);
--
    function fopen (name_i in varchar2, flag_i in pls_integer, p_chk boolean default true,
                    name_text pls_integer default NULL) return pls_integer;
    function fcreate (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                      name_text pls_integer default NULL) return pls_integer;
    function fclose (fh_i in pls_integer) return pls_integer;
    function fseek (fh_i in pls_integer, pos in out nocopy varchar2, off_i in pls_integer, how_i in pls_integer) return pls_integer;
    function fread (fh_i in pls_integer, sz_i in pls_integer, bf_o in out nocopy raw) return pls_integer;
    function fwrite (fh_i in pls_integer, bf_i in raw, sz_i in pls_integer default 0) return pls_integer;
    function lha (clinum  in varchar2) return pls_integer;
    function zip (arcname in varchar2, dirname in varchar2) return pls_integer;
    function error_message (error_number_i in pls_integer) return varchar2;
    function fmove (oldname_i in varchar2, newname_i in varchar2, p_chk boolean default true,
                    name_text pls_integer default NULL) return pls_integer;
    function fdelete (filename_i in varchar2, p_chk boolean default true,
                      name_text  pls_integer default NULL) return pls_integer;
    function mkdir (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                    name_text pls_integer default NULL) return pls_integer;
    function flist (dirname_i in varchar2, dirflag_i in pls_integer, p_sort boolean default null,
                    name_text in pls_integer default NULL) return varchar2;
    function flist (dirname_i in varchar2, dirflag_i in pls_integer, filelist_o in out nocopy varchar2, p_sort boolean default null, p_chk boolean default true,
                    name_text pls_integer default NULL ) return pls_integer;
    function run(ev_i in varchar2, a0_i in varchar2 := NULL,
                 a1_i in varchar2 := NULL,
                 a2_i in varchar2 := NULL,
                 a3_i in varchar2 := NULL,
                 a4_i in varchar2 := NULL,
                 a5_i in varchar2 := NULL,
                 a6_i in varchar2 := NULL,
                 a7_i in varchar2 := NULL,
                 a8_i in varchar2 := NULL,
                 a9_i in varchar2 := NULL,
                 p_env  boolean default true) return pls_integer;
--
    function  get_env (name in varchar2) return varchar2;
    function  put_env (name in varchar2, value in varchar2) return pls_integer;
--
    function  f_open(filename  in varchar2,
                     open_mode in varchar2,
                     p_chk     boolean default false,
                     name_text pls_integer default NULL ) return pls_integer;
    function  f_dopen( handle in pls_integer, open_mode in varchar2 ) return pls_integer;
    function  f_close( file IN OUT nocopy pls_integer  ) return pls_integer;
    procedure f_closeall( p_files boolean default null );
    function  f_flush(file pls_integer) return pls_integer;
    function  f_seek (file pls_integer, pos in out nocopy varchar2, off_i pls_integer, how_i pls_integer default 0) return pls_integer;
    function  f_tell (file pls_integer) return number;
    function  f_truncate( file pls_integer, p_size pls_integer default null ) return pls_integer;
    function  f_read (file pls_integer, bf_o in out nocopy raw, sz_i pls_integer) return pls_integer;
    function  f_write(file pls_integer, bf_i in raw, sz_i pls_integer default 0) return pls_integer;
    function  read_str(file pls_integer, str in out nocopy varchar2,
                       in_text  pls_integer  default NULL,
                       out_text pls_integer  default NULL,
                       sz_i pls_integer default 0) return pls_integer;
    function  write_str(file pls_integer, str varchar2,
                        in_text  pls_integer  default NULL,
                        out_text pls_integer  default NULL,
                        p_nl boolean default true) return pls_integer;
    function get_file_name ( file pls_integer, p_files boolean default true ) return varchar2;
    function f_copy ( oldname varchar2,
                      newname varchar2,
                      fsize   in out nocopy varchar2,
                      p_chk   boolean default false,
                      p_write boolean default true,
                      name_text pls_integer default NULL) return pls_integer;
    function f_info( name   varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy varchar2,
                     p_chk  boolean default false,
                     name_text pls_integer default NULL
                    ) return pls_integer;
    function  opendir( dirname varchar2, mask varchar2 default null,
                       dir_flag  pls_integer default 0, p_chk boolean default false,
                       name_text pls_integer default NULL) return pls_integer;
    function  closedir(dir  in out nocopy pls_integer ) return pls_integer;
    function  resetdir(dir  pls_integer ) return pls_integer;
    function  readdir( dir    pls_integer,
                       name   in out nocopy varchar2,
                       attrs  in out nocopy varchar2,
                       uowner in out nocopy varchar2,
                       gowner in out nocopy varchar2,
                       mdate  in out nocopy varchar2,
                       fsize  in out nocopy varchar2
                     ) return pls_integer;
--
    procedure Init;
--
end vfs_io;
/
show errors

