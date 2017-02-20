prompt stdio
create or replace
package stdio is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/STDIO1.SQL $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
    DOSTEXT   constant pls_integer := 1;
    UNXTEXT   constant pls_integer := 2;
    WINTEXT   constant pls_integer := 3;
    KOITEXT   constant pls_integer := 4;
    STDIOPIPESIZE  constant pls_integer := 1024*32;
    STDIOTIMEOUT   constant pls_integer := 0;
    STDIOPIPENAME  constant varchar2(6) := 'stdio$';
    STDIOLINESIZE  constant pls_integer := 1024*32;
    STDIOBUFFERSIZE constant pls_integer:= 300000;
--
    INVALID_PATH       exception;
    INVALID_MODE       exception;
    INVALID_FILEHANDLE exception;
    INVALID_OPERATION  exception;
    INVALID_LINESIZE   exception;
    READ_ERROR         exception;
    WRITE_ERROR        exception;
--
    BUFFER_OVERFLOW exception;
    PRAGMA EXCEPTION_INIT ( BUFFER_OVERFLOW,-20000);  -- ORA-20000: ORU-10027: buffer overflow, limit of 2000 bytes
    PIPE_OVERFLOW   exception;
    PRAGMA EXCEPTION_INIT( PIPE_OVERFLOW,   -6558 );
    PIPE_EMPTY      exception;
    PRAGMA EXCEPTION_INIT( PIPE_EMPTY,      -6556 );
    PIPE_TYPE       exception;
    PRAGMA EXCEPTION_INIT( PIPE_TYPE,       -6559 );
    NULL_PIPE       exception;
    PRAGMA EXCEPTION_INIT( NULL_PIPE,       -23321);
    ACCESS_PIPE     exception;
    PRAGMA EXCEPTION_INIT( ACCESS_PIPE,     -23322);
-- FILES I/O
    function  transform(txt      in varchar2,
                        in_text  in pls_integer,
                        out_text in pls_integer ) return varchar2 deterministic;
    pragma restrict_references(transform,WNDS,WNPS,TRUST);
    procedure set_def_text( p_txt      varchar2,
                            p_slash    varchar2 default null,
                            p_add_cr   varchar2 default null,
                            p_name_txt varchar2 default null );
--
    procedure set_sizes( line_size   IN  pls_integer default null,
                         buffer_size IN  pls_integer default null );
    procedure get_sizes( line_size   OUT nocopy pls_integer,
                         buffer_size OUT nocopy pls_integer );
    procedure get_buf_sizes( cur_size OUT nocopy pls_integer,
                             max_size OUT nocopy pls_integer );
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
    procedure close_all;
    function  is_open ( file   IN pls_integer ) return boolean;
    procedure flush ( file     IN pls_integer,
                      raising  IN boolean default FALSE );
    procedure fput  ( file     IN pls_integer,
                      buffer   IN varchar2,
                      raising  IN boolean default FALSE,
                      p_flash  IN boolean default FALSE,
                      in_text  IN pls_integer default NULL,
                      out_text IN pls_integer default NULL );
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
    procedure get_line ( file     IN  pls_integer,
                         buffer   OUT nocopy varchar2,
                         raising  IN  boolean default FALSE,
                         in_text  IN  pls_integer default NULL,
                         out_text IN  pls_integer default NULL,
                         l_size   IN  pls_integer default NULL );
    function get_line ( file     IN  pls_integer,
                        buffer   OUT nocopy varchar2,
                        raising  IN  boolean default FALSE,
                        in_text  IN  pls_integer default NULL,
                        out_text IN  pls_integer default NULL,
                        l_size   IN  pls_integer default NULL ) return boolean;
-- SESSION BUFFER I/O
    function  put_buf ( p_text varchar2, p_nl boolean default true, p_expand boolean default false) return pls_integer;
    procedure write_buf ( p_text varchar2, p_nl boolean default true );
    procedure put_line_buf ( p_text  IN varchar2,
                             p_nl    IN boolean default true );
    function  get_buf ( p_text OUT nocopy varchar2 ) return pls_integer;
    function  get_line_buf ( p_text OUT nocopy varchar2 ) return pls_integer;
    function  get_buf_text return varchar2;
    procedure enable_buf ( p_size  IN pls_integer default null,
                           p_clear IN boolean default TRUE );
    procedure disable_buf;
-- FORMON - FIO
    procedure formon_open;
    procedure formon_close;
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
    function fseek (fh_i in pls_integer, off_i in pls_integer, how_i in pls_integer) return pls_integer;
    function fseek (fh_i in pls_integer, pos in out nocopy varchar2, off_i in pls_integer, how_i in pls_integer) return pls_integer;
    function fseekn(fh_i in pls_integer, off_i in pls_integer, how_i in pls_integer) return number;
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
    procedure qsort (buf in out nocopy varchar2, p_char varchar2 default null, p_mode boolean default true);
    function  get_env (name in varchar2) return varchar2;
    function  put_env (name in varchar2, value in varchar2) return pls_integer;
--  FIO I/O
    function  f_open(filename  in varchar2,
                     open_mode in varchar2,
                     p_chk     boolean default false,
                     name_text pls_integer default NULL ) return pls_integer;
    function  f_dopen( handle in pls_integer, open_mode in varchar2 ) return pls_integer;
    function  f_close( file IN OUT nocopy pls_integer  ) return pls_integer;
    procedure f_closeall( p_files boolean default null );
    function  f_flush(file pls_integer) return pls_integer;
    function  f_seek (file pls_integer, off_i pls_integer, how_i pls_integer default 0) return pls_integer;
    function  f_seek (file pls_integer, pos in out nocopy varchar2, off_i pls_integer, how_i pls_integer default 0) return pls_integer;
    function  f_seekn(file pls_integer, off_i pls_integer, how_i pls_integer default 0) return number;
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
                      p_chk   boolean default false,
                      p_write boolean default true,
                      name_text pls_integer default NULL) return pls_integer;
    function f_copy ( oldname varchar2,
                      newname varchar2,
                      fsize   in out nocopy varchar2,
                      p_chk   boolean default false,
                      p_write boolean default true,
                      name_text pls_integer default NULL) return pls_integer;
    function f_copyn( oldname varchar2,
                      newname varchar2,
                      p_chk   boolean default false,
                      p_write boolean default true,
                      name_text pls_integer default NULL) return number;
    function f_info( name   varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy pls_integer,
                     p_chk  boolean default false,
                     name_text pls_integer default NULL
                    ) return pls_integer;
    function f_info( name   varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy varchar2,
                     p_chk  boolean default false,
                     name_text pls_integer default NULL
                    ) return pls_integer;
    function finfo ( name   varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy number,
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
                       fsize  in out nocopy pls_integer
                     ) return pls_integer;
    function  readdir( dir    pls_integer,
                       name   in out nocopy varchar2,
                       attrs  in out nocopy varchar2,
                       uowner in out nocopy varchar2,
                       gowner in out nocopy varchar2,
                       mdate  in out nocopy varchar2,
                       fsize  in out nocopy varchar2
                     ) return pls_integer;
    function  read_dir(dir    pls_integer,
                       name   in out nocopy varchar2,
                       attrs  in out nocopy varchar2,
                       uowner in out nocopy varchar2,
                       gowner in out nocopy varchar2,
                       mdate  in out nocopy varchar2,
                       fsize  in out nocopy number
                     ) return pls_integer;
--  PIPE I/O
    function  put_pipe( p_text IN varchar2,
                        p_pipe IN varchar2 default null,
                        p_time IN pls_integer default null,
                        p_size IN pls_integer default null,
                        p_nl   IN boolean  default true,
                        p_expand  boolean  default false
                      ) return pls_integer;
    procedure put_line_pipe ( p_text IN varchar2,
                              p_pipe IN varchar2 default null,
                              p_time IN pls_integer default null,
                              p_size IN pls_integer default null,
                              p_nl   IN boolean  default true );
    function  get_pipe( p_text OUT nocopy varchar2,
                        p_pipe IN varchar2 default null,
                        p_time IN pls_integer default null
                      ) return pls_integer;
    function  get_line_pipe ( p_text OUT nocopy varchar2,
                              p_pipe IN varchar2 default null,
                              p_time IN pls_integer default null ) return pls_integer;
    function  get_pipe_text( p_pipe varchar2 default null,
                             p_time pls_integer default 0) return varchar2;
    procedure setup_pipes ( p_read  IN varchar2 default STDIOPIPENAME,
                            p_write IN varchar2 default STDIOPIPENAME,
                            p_time  IN pls_integer default STDIOTIMEOUT,
                            p_size  IN pls_integer default STDIOPIPESIZE );
    procedure get_pipe_info( p_read  OUT nocopy varchar2,
                             p_write OUT nocopy varchar2,
                             p_time  OUT nocopy pls_integer,
                             p_size  OUT nocopy pls_integer );
--  SETTINGS
    function  get_setting(p_name varchar2) return varchar2 deterministic;
    pragma restrict_references(get_setting,WNDS,WNPS);
    function  setting(p_name varchar2) return varchar2 deterministic;
    pragma restrict_references(setting,WNDS,WNPS,TRUST);
    function  num_set(p_name varchar2) return number deterministic;
    pragma restrict_references(num_set,WNDS,WNPS,TRUST);
    procedure put_setting(p_name varchar2, p_value   varchar2,
                          p_description varchar2 default null);
    procedure init_setting(p_name varchar2 default null);
--  PROFILES
    function  get_resource_value(p_profile varchar2, p_name varchar2) return varchar2 deterministic;
    pragma restrict_references(get_resource_value,WNDS,WNPS);
    function  get_resource(p_profile varchar2, p_name varchar2) return varchar2 deterministic;
    pragma restrict_references(get_resource,WNDS,WNPS,TRUST);
    procedure set_resource(p_profile varchar2, p_name varchar2,
                           p_value   varchar2, p_description varchar2 default null);
    procedure init_resource(p_resource varchar2 default null);
--
    function  get_profile(p_user varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_profile,WNDS,WNPS);
    procedure Init;
--
end stdio;
/
show errors

