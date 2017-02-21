prompt utl_file body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/utlfile2.sql $
 *  $Author: fit_manyak $
 *  $Revision: 26724 $
 *  $Date:: 2013-04-19 09:12:37 #$
 */
utl_file as
--
  VERSION constant varchar2(10) := '1.0';
--
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
                 max_linesize IN PLS_INTEGER DEFAULT NULL) RETURN file_type is
      f file_type;
  begin
      if max_linesize<1 or max_linesize>32767 then
          raise invalid_maxlinesize;
      end if;
      f.id := stdio.open(location,filename,open_mode,true,max_linesize);
      return f;
  exception
      when stdio.invalid_path then
          raise invalid_path;
      when stdio.invalid_mode then
          raise invalid_mode;
      when stdio.invalid_operation then
          raise invalid_operation;
  end;
  /*
  ** IS_OPEN - Test if file handle is open
  **
  ** IN
  **   file - File handle
  ** RETURN
  **   BOOLEAN - Is file handle open/valid?
  */
  FUNCTION is_open(file IN file_type) RETURN BOOLEAN is
  begin
      return stdio.is_open(file.id);
  end;
  /*
  ** FCLOSE - close an open file
  **
  ** IN
  **   file - File handle (open)
  ** EXCEPTIONS
  **   invalid_filehandle - not a valid file handle
  **   write_error        - OS error occured during write operation
  */
  PROCEDURE fclose(file IN OUT file_type) is
  begin
      stdio.close(file.id);
  exception
      when stdio.invalid_filehandle then
          raise invalid_filehandle;
      when stdio.write_error then
          raise write_error;
  end;
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
  PROCEDURE fclose_all is
  begin
      stdio.f_closeall(null);
  exception when others then
      if sqlcode=-20100 then
          raise write_error;
      end if;
      raise;
  end;
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
                     buffer OUT VARCHAR2) is
  begin
      if not stdio.get_line(file.id,buffer,true) then
          raise no_data_found;
      end if;
  exception
      when stdio.invalid_filehandle then
          raise invalid_filehandle;
      when stdio.invalid_operation then
          raise invalid_operation;
      when stdio.read_error then
          raise read_error;
  end;
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
                buffer IN VARCHAR2) is
  begin
      stdio.fput(file.id,buffer,true);
  exception
      when stdio.invalid_filehandle then
          raise invalid_filehandle;
      when stdio.invalid_operation then
          raise invalid_operation;
      when stdio.write_error then
          raise write_error;
  end;
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
                     lines IN PLS_INTEGER := 1) is
  begin
      for i in 1..lines  loop
          put_line(file,null);
      end loop;
  end;
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
                     buffer IN VARCHAR2) is
  begin
      stdio.put_line(file.id,buffer,true);
  exception
      when stdio.invalid_filehandle then
          raise invalid_filehandle;
      when stdio.invalid_operation then
          raise invalid_operation;
      when stdio.write_error then
          raise write_error;
  end;
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
                 arg5   IN VARCHAR2 DEFAULT NULL) is
      v_format  varchar2(32767) := format;
      arg   pls_integer := 1;
      j pls_integer := 1;
      i pls_integer;
  begin
      while arg<6 loop
          i := instr(v_format,'%s',j);
          if i>0 then
              j := i+2;
              v_format := substr(v_format,1,i)||arg||substr(v_format,j);
              arg := arg+1;
          else
              exit;
          end if;
      end loop;
      stdio.putf(file.id,v_format,true,null,null,arg1,arg2,arg3,arg4,arg5);
  exception
      when stdio.invalid_filehandle then
          raise invalid_filehandle;
      when stdio.invalid_operation then
          raise invalid_operation;
      when stdio.write_error then
          raise write_error;
  end;
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
  PROCEDURE fflush(file IN file_type) is
  begin
      stdio.flush(file.id,true);
  exception
      when stdio.invalid_filehandle then
          raise invalid_filehandle;
      when stdio.invalid_operation then
          raise invalid_operation;
      when stdio.write_error then
          raise write_error;
  end;
-- FIO through STDIO
function  fio_init return pls_integer is
begin
    begin
        stdio.fio_open;
    exception when others then
        if sqlcode<>-20100 then raise; end if;
    end;
    return stdio.get_fio_pid;
end;
--
procedure fio_close is
begin
    stdio.fio_close;
end;
--
function  file_list ( location IN varchar2, dir_flag pls_integer default 0,
                      p_sort boolean default null, p_chk boolean default false,
                      name_text pls_integer default NULL ) return varchar2 is
begin
    return stdio.file_list(location, dir_flag, p_sort, p_chk ,name_text);
end;
--
procedure move_file ( old_name IN varchar2,
                      new_name IN varchar2, p_chk boolean default false,
                      name_text pls_integer default NULL ) is
begin
    stdio.move_file(old_name, new_name, p_chk, name_text);
end;
--
procedure delete_file ( file_name IN varchar2, p_chk boolean default false,
                        name_text pls_integer default NULL ) is
begin
    stdio.delete_file(file_name, p_chk, name_text);
end;
--
function  error_message (error_number_i in number) return varchar2 is
begin
    return stdio.error_message(error_number_i);
end;
--
function  mkdir (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                        name_text pls_integer default NULL) return pls_integer is
begin
    return stdio.mkdir(name_i, mode_i, p_chk ,name_text);
end;
--
function  f_open(filename  in varchar2,
                 open_mode in varchar2,
                 p_chk boolean default false,
                 name_text pls_integer default NULL ) return pls_integer is
begin
    return stdio.f_open(filename, open_mode, p_chk, name_text);
end;
--
function  f_close( file IN OUT nocopy pls_integer  ) return pls_integer is
begin
    return stdio.f_close(file);
end;
--
procedure f_closeall(p_files boolean default true) is
begin
    stdio.f_closeall(p_files);
end;
--
function  f_flush( file pls_integer  ) return pls_integer is
begin
    return stdio.f_flush(file);
end;
--
function  f_seek(file pls_integer, off_i pls_integer, how_i pls_integer default 0) return pls_integer is
begin
    return stdio.f_seek(file, off_i, how_i);
end;
--
function  f_seekn(file pls_integer, off_i pls_integer, how_i pls_integer default 0) return number is
begin
    return stdio.f_seekn(file, off_i, how_i);
end;
--
function  f_read(file pls_integer, bf_o in out nocopy raw, sz_i pls_integer) return pls_integer is
begin
    return stdio.f_read(file, bf_o, sz_i);
end;
--
function  f_write(file pls_integer, bf_i in raw, sz_i pls_integer default 0) return pls_integer is
begin
    return stdio.f_write(file, bf_i, sz_i);
end;
--
function  f_copy( oldname varchar2,
                  newname varchar2,
                  p_chk   boolean default false,
                  p_write boolean default true,
                  name_text pls_integer default NULL) return pls_integer is
begin
    return stdio.f_copy(oldname, newname, p_chk, p_write, name_text);
end;
--
function  f_copyn(oldname varchar2,
                  newname varchar2,
                  p_chk   boolean default false,
                  p_write boolean default true,
                  name_text pls_integer default NULL) return number is
begin
    return stdio.f_copyn(oldname, newname, p_chk, p_write, name_text);
end;
--
function  f_info(name   varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy pls_integer,
                 p_chk  boolean default false,
                 name_text pls_integer default NULL
                ) return pls_integer is
begin
    return stdio.f_info(name, attrs, uowner, gowner, mdate, fsize, p_chk, name_text);
end;
--
function  finfo( name   varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy number,
                 p_chk  boolean default false,
                 name_text pls_integer default NULL
                ) return pls_integer is
begin
    return stdio.finfo(name, attrs, uowner, gowner, mdate, fsize, p_chk, name_text);
end;
--
function  opendir( dirname varchar2, mask varchar2 default null,
                   dir_flag pls_integer default 0, p_chk boolean default false,
                   name_text pls_integer default NULL) return pls_integer is
begin
    return stdio.opendir(dirname, mask, dir_flag, p_chk, name_text);
end;
--
function  closedir(dir  in out nocopy pls_integer ) return pls_integer is
begin
    return stdio.closedir(dir);
end;
--
function  resetdir(dir  pls_integer ) return pls_integer is
begin
    return stdio.resetdir(dir);
end;
--
function  readdir( dir    pls_integer,
                   name   in out nocopy varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy pls_integer
                 ) return pls_integer is
begin
    return stdio.readdir(dir, name, attrs, uowner, gowner, mdate, fsize);
end;
--
function  read_dir(dir    pls_integer,
                   name   in out nocopy varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy number
                 ) return pls_integer is
begin
    return stdio.read_dir(dir, name, attrs, uowner, gowner, mdate, fsize);
end;
--
function get_file_name ( file pls_integer, p_files boolean default true ) return varchar2 is
begin
    return stdio.get_file_name(file, p_files);
end;
--
function  setting(p_name varchar2) return varchar2 is
begin
    return stdio.setting(p_name);
end;
--
function  get_resource(p_profile varchar2, p_name varchar2) return varchar2 is
begin
    return stdio.get_resource(p_profile,p_name);
end;
--
function  get_version return varchar2 is
begin
    return VERSION;
end;
--
END utl_file;
/
show errors package body utl_file

