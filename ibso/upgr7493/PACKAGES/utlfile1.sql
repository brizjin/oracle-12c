prompt utl_file
CREATE OR REPLACE PACKAGE utl_file AS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/utlfile1.sql $
 *  $Author: fit_manyak $
 *  $Revision: 26724 $
 *  $Date:: 24/07/08 17:49UTILS IS
 */
--
  /*
  ** FILE_TYPE - File handle
  */
  TYPE file_type IS RECORD (id PLS_INTEGER);

  /*
  ** Exceptions
  */
  invalid_path       EXCEPTION;
  invalid_mode       EXCEPTION;
  invalid_filehandle EXCEPTION;
  invalid_operation  EXCEPTION;
  read_error         EXCEPTION;
  write_error        EXCEPTION;
  internal_error     EXCEPTION;
  invalid_maxlinesize  EXCEPTION;

  /*
  ** FOPEN - open file (user-specified maximum line size)
  **
  ** This version of FOPEN allows the user to specify the desired maximum
  ** line size.  The version with the default line size is earlier in this
  ** package, for compatibility reasons.
  **
  ** As of 8.0.6, you can have a maximum of 50 files open simultaneously.
  **
  ** IN
  **   location     - directory location of file
  **   filename     - file name (including extention)
  **   open_mode    - open mode ('r', 'w', 'a')
  **   max_linesize - maximum number of characters per line, including the
  **                  newline character, for this file.
  **                  (minimum value 1, maximum value 32767)
  ** RETURN
  **   file_type handle to open file
  ** EXCEPTIONS
  **   invalid_path        - file location or name was invalid
  **   invalid_mode        - the open_mode string was invalid
  **   invalid_operation   - file could not be opened as requested
  **   invalid_maxlinesize - specified max_linesize is too large or too small
  */
  FUNCTION fopen(location     IN VARCHAR2,
                 filename     IN VARCHAR2,
                 open_mode    IN VARCHAR2,
                 max_linesize IN PLS_INTEGER DEFAULT NULL) RETURN file_type;


  /*
  ** IS_OPEN - Test if file handle is open
  **
  ** IN
  **   file - File handle
  ** RETURN
  **   BOOLEAN - Is file handle open/valid?
  */
  FUNCTION is_open(file IN file_type) RETURN BOOLEAN;

  /*
  ** FCLOSE - close an open file
  **
  ** IN
  **   file - File handle (open)
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE fclose(file IN OUT file_type);

  /*
  ** FCLOSE_ALL - close all open files for this session
  **
  ** For Emergency/Cleanup use only.  FILE_TYPE handles will not be
  ** cleared (IS_OPEN will still indicate they are valid)
  **
  ** IN
  **   file - File handle (open)
  ** EXCEPTIONS
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE fclose_all;

  /*
  ** GET_LINE - Get (read) a line of text from the file
  **
  ** IN
  **   file - File handle (open in read mode)
  ** OUT
  **   buffer - next line of text in file
  ** EXCEPTIONS
  **   no_data_found      - reached the end of file
  **   value_error        - line to long to store in buffer
  **   invalid_filehandle - not a valid file handle
  **   invalid_operation  - file is not open for reading
  **   read_error         - OS error occurred during read
  */
  PROCEDURE get_line(file   IN file_type,
                     buffer OUT VARCHAR2);

  /*
  ** PUT - Put (write) text to file
  **
  ** IN
  **   file   - File handle (open in write/append mode)
  **   buffer - Text to write
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   invalid_operation  - file is not open for writing/appending
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE put(file   IN file_type,
                buffer IN VARCHAR2);

  /*
  ** NEW_LINE - Write line terminators to file
  **
  ** IN
  **   file - File handle (open in write/append mode)
  **   lines - Number of newlines to write (default 1)
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   invalid_operation  - file is not open for writing/appending
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE new_line(file  IN file_type,
                     lines IN PLS_INTEGER := 1);

  /*
  ** PUT_LINE - Put (write) line to file
  **
  ** IN
  **   file   - File handle (open in write/append mode)
  **   buffer - Text to write
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   invalid_operation  - file is not open for writing/appending
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE put_line(file   IN file_type,
                     buffer IN VARCHAR2);

  /*
  ** PUTF - Put (write) formatted text to file
  **
  ** Format string special characters
  **     '%s' - substitute with next argument
  **     '\n' - newline (line terminator)
  **
  ** IN
  **   file - File handle (open in write/append mode)
  **   format - Formatting string
  **   arg1 - Substitution argument #1
  **   ...
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   invalid_operation  - file is not open for writing/appending
  **   write_error        - OS error occured during write operation
  */
  procedure putf(file   IN file_type,
                 format IN VARCHAR2,
                 arg1   IN VARCHAR2 DEFAULT NULL,
                 arg2   IN VARCHAR2 DEFAULT NULL,
                 arg3   IN VARCHAR2 DEFAULT NULL,
                 arg4   IN VARCHAR2 DEFAULT NULL,
                 arg5   IN VARCHAR2 DEFAULT NULL);

  /*
  ** FFLUSH - Force physical write of buffered output
  **
  ** IN
  **   file - File handle (open in write/append mode)
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   invalid_operation  - file is not open for writing/appending
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE fflush(file IN file_type);

-- FIO through STDIO
  function  fio_init return pls_integer;
  procedure fio_close;
--
  function  file_list ( location IN varchar2, dir_flag pls_integer default 0,
                        p_sort boolean default null, p_chk boolean default false,
                        name_text pls_integer default NULL ) return varchar2;
  procedure move_file ( old_name IN varchar2,
                        new_name IN varchar2, p_chk boolean default false,
                        name_text pls_integer default NULL );
  procedure delete_file ( file_name IN varchar2, p_chk boolean default false,
                          name_text pls_integer default NULL );
  function  error_message (error_number_i in number) return varchar2;
  function  mkdir (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                          name_text pls_integer default NULL) return pls_integer;
  function  f_open(filename  in varchar2,
                   open_mode in varchar2,
                   p_chk boolean default false,
                   name_text pls_integer default NULL ) return pls_integer;
  function  f_close( file IN OUT nocopy pls_integer  ) return pls_integer;
  procedure f_closeall( p_files boolean default true );
  function  f_flush(file pls_integer) return pls_integer;
  function  f_seek (file pls_integer, off_i pls_integer, how_i pls_integer default 0) return pls_integer;
  function  f_seekn(file pls_integer, off_i pls_integer, how_i pls_integer default 0) return number;
  function  f_read (file pls_integer, bf_o in out nocopy raw, sz_i pls_integer) return pls_integer;
  function  f_write(file pls_integer, bf_i in raw, sz_i pls_integer default 0) return pls_integer;
  function  f_copy( oldname varchar2,
                    newname varchar2,
                    p_chk   boolean default false,
                    p_write boolean default true,
                    name_text pls_integer default NULL) return pls_integer;
  function  f_copyn(oldname varchar2,
                    newname varchar2,
                    p_chk   boolean default false,
                    p_write boolean default true,
                    name_text pls_integer default NULL) return number;
  function  f_info(name   varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy pls_integer,
                   p_chk  boolean default false,
                   name_text pls_integer default NULL
                  ) return pls_integer;
  function  finfo( name   varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy number,
                   p_chk  boolean default false,
                   name_text pls_integer default NULL
                  ) return pls_integer;
  function  opendir( dirname varchar2, mask varchar2 default null,
                     dir_flag pls_integer default 0, p_chk boolean default false,
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
  function  read_dir(dir    pls_integer,
                     name   in out nocopy varchar2,
                     attrs  in out nocopy varchar2,
                     uowner in out nocopy varchar2,
                     gowner in out nocopy varchar2,
                     mdate  in out nocopy varchar2,
                     fsize  in out nocopy number
                   ) return pls_integer;
  function  get_file_name ( file pls_integer, p_files boolean default true ) return varchar2;
--  SETTINGS
  function  setting(p_name varchar2) return varchar2;
  function  get_resource(p_profile varchar2, p_name varchar2) return varchar2;
--  VERSION
  function  get_version return varchar2;
END utl_file;
/
show errors

