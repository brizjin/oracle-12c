prompt stdio body
create or replace
package body stdio is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_stdio2.sql $
 *  $Author: Alexey $
 *  $Revision: 15082 $
 *  $Date:: 2012-03-06 17:34:34 #$
 */
--
    LF      constant varchar2(1) := chr(10);
    LSEP    constant varchar2(2) := chr(127)||chr(127); /* Разделитель длинных строк */
    BUFFER_LIMIT_SIZE constant pls_integer:= 1000000;
    BUFFER_LINE_SIZE pls_integer;
    PIPE_LINE_SIZE constant pls_integer := 4000;
--
type values_tbl_t is table of varchar2(2000) index by varchar2(128);
--
setts values_tbl_t;
profs values_tbl_t;
--
read_pipe_name   varchar2(100);
write_pipe_name  varchar2(100);
schema_owner     varchar2(30);
cur_profile      varchar2(30);
stdio_buf_size   pls_integer;
stdio_pipe_size  pls_integer;
stdio_time_out   pls_integer;
last_buf_size    pls_integer;
max_buf_size     pls_integer;
buffer_written   pls_integer;
buf_enable  boolean := true;
init_pipes  boolean := true;
init_sizes  boolean := true;
v_buf_err   boolean := false;
v_buf_text  varchar2(4096);
-----------------------------------------------------
-- @METAGS transform
function transform( txt in varchar2,
                    in_text  in pls_integer,
                    out_text in pls_integer
                  ) return varchar2 is
begin
  return vfs_io.transform(txt,in_text,out_text);
end transform;
-----------------------------------------------------
-- @METAGS open
function open ( location  in varchar2,
                filename  in varchar2,
                open_mode in varchar2,
                raising   IN boolean default FALSE,
                line_size IN pls_integer default NULL,
                name_text IN pls_integer default NULL
              ) return pls_integer is
begin
  return vfs_io.open(location,filename,open_mode,raising,line_size,name_text);
exception
  when vfs_io.INVALID_PATH      then raise INVALID_PATH;
  when vfs_io.INVALID_MODE      then raise INVALID_MODE;
  when vfs_io.INVALID_OPERATION then raise INVALID_OPERATION;
end open;
--
-- @METAGS close
procedure close ( file IN OUT nocopy pls_integer ,
                  raising IN boolean default FALSE
                ) is
begin
  vfs_io.close(file,raising);
exception
  when vfs_io.INVALID_FILEHANDLE then raise INVALID_FILEHANDLE;
  when vfs_io.WRITE_ERROR        then raise WRITE_ERROR;
end close;
--
-- @METAGS close_all
procedure close_all is
begin
    f_closeall;
end close_all;
--
-- @METAGS fput
procedure fput ( file    IN pls_integer,
                 buffer  IN varchar2,
                 raising IN boolean default FALSE,
                 p_flash IN boolean default FALSE) is
begin
  vfs_io.fput(file,buffer,raising,p_flash);
exception
  when vfs_io.INVALID_FILEHANDLE then raise INVALID_FILEHANDLE;
  when vfs_io.WRITE_ERROR        then raise WRITE_ERROR;
end fput;
--
-- @METAGS put_line
procedure put_line ( file     IN pls_integer,
                     buffer   IN varchar2,
                     raising  IN boolean default FALSE,
                     in_text  IN pls_integer  default NULL,
                     out_text IN pls_integer  default NULL
				   ) is
begin
  vfs_io.put_line(file,buffer,raising,in_text,out_text);
exception
  when vfs_io.INVALID_FILEHANDLE then raise INVALID_FILEHANDLE;
  when vfs_io.WRITE_ERROR        then raise WRITE_ERROR;
end put_line;
--
-- @METAGS putf
procedure putf ( file     IN pls_integer,
                 format   IN varchar2,
                 raising  IN boolean  default FALSE,
                 in_text  IN pls_integer   default NULL,
                 out_text IN pls_integer   default NULL,
                 p_text1  IN varchar2 default NULL,
                 p_text2  IN varchar2 default NULL,
                 p_text3  IN varchar2 default NULL,
                 p_text4  IN varchar2 default NULL,
                 p_text5  IN varchar2 default NULL
				   ) is
begin
  vfs_io.putf(file,format,raising,in_text,out_text,p_text1,p_text2,p_text3,p_text4,p_text5);
end putf;
--
-- @METAGS flush
procedure flush ( file     IN  pls_integer,
                  raising  IN  boolean default FALSE ) is
begin
  vfs_io.flush(file,raising);
end flush;
--
-- @METAGS get_line
function get_line ( file     IN  pls_integer,
                    buffer   OUT nocopy varchar2,
                    raising  IN  boolean default FALSE,
                    in_text  IN  pls_integer default NULL,
                    out_text IN  pls_integer default NULL,
                    l_size   IN  pls_integer default NULL
				  ) return boolean is
begin
  return vfs_io.get_line(file,buffer,raising,in_text,out_text,l_size);
exception
  when vfs_io.INVALID_FILEHANDLE then raise INVALID_FILEHANDLE;
  when vfs_io.READ_ERROR         then raise READ_ERROR;
end;
--
-- @METAGS get_line
procedure get_line ( file     IN  pls_integer,
                     buffer   OUT nocopy varchar2,
                     raising  IN  boolean default FALSE,
                     in_text  IN  pls_integer default NULL,
                     out_text IN  pls_integer default NULL,
                     l_size   IN  pls_integer default NULL
				   ) is
begin
    if not get_line(file,buffer,raising,in_text,out_text,l_size) then
        raise rtl.NO_DATA_FOUND;
    end if;
end get_line;
--
-- @METAGS is_open
function is_open ( file  IN  pls_integer ) return boolean is
begin
  return vfs_io.is_open(file);
end is_open;
-----------------------------------------------------
procedure write_buf ( p_text varchar2, p_nl boolean default true ) is
    len  pls_integer := nvl(length(p_text),0);
    len1 pls_integer;
    pos0 pls_integer := 1;
    pos1 pls_integer;
    b_add_sep boolean;
begin
    buffer_written := 0;
    if buf_enable then
        enable_buf;
    end if;
    if len <= BUFFER_LINE_SIZE then
		if p_nl then
            if len>0 then
                dbms_output.put_line( p_text );
            else
                dbms_output.new_line;
            end if;
        elsif len>0 then
			dbms_output.put( p_text );
		end if;
		return;
	end if;
    loop
        b_add_sep:= false;
        pos1 := instr( p_text, LF, pos0 );
        if pos1=len then
            pos1 := pos1+1;
        end if;
        if pos1 = 0 or pos1>pos0+BUFFER_LINE_SIZE then
            len1 := BUFFER_LINE_SIZE;
            pos1 := pos0+BUFFER_LINE_SIZE-1;
            b_add_sep:= pos1<len;
		else
            len1 := pos1-pos0;
		end if;
        if not b_add_sep then
          dbms_output.put_line( substr(p_text,pos0,len1) );
        else
          len1 := len1-length(LSEP);
          pos1 := pos1-length(LSEP);
          dbms_output.put_line( substr(p_text,pos0,len1) || LSEP);
        end if;
        buffer_written := pos1;
        pos0 := pos1 + 1;
        exit when pos0>len;
	end loop;
end;
-- @METAGS put_line_buf
procedure put_line_buf ( p_text IN varchar2,
                         p_nl   IN boolean default true
                       ) is
begin
  write_buf(p_text,p_nl);
exception
when BUFFER_OVERFLOW or VALUE_ERROR then
  buffer_written := 0;
end;
--
function put_buf ( p_text varchar2, p_nl boolean default true, p_expand boolean default false) return pls_integer is
  len  pls_integer := nvl(length(p_text),0);
begin
  write_buf(p_text,p_nl);
  return len;
exception when BUFFER_OVERFLOW then
  if buffer_written<len then
    len := buffer_written;
    if p_expand and last_buf_size < BUFFER_LIMIT_SIZE then
      enable_buf(last_buf_size+least(32768,BUFFER_LIMIT_SIZE-last_buf_size),false);
      len := len+put_buf(substr(p_text,len+1),p_nl,true);
    end if;
  end if;
  buffer_written := 0;
  return len;
end;
-----------------------------------------------------
function get_buf ( p_text OUT nocopy varchar2 ) return pls_integer is
    v_status pls_integer;
begin
    dbms_output.get_line( p_text, v_status );
    return v_status;
end;
-- @METAGS get_line_buf
function get_line_buf ( p_text OUT nocopy varchar2 ) return pls_integer is
    v_status pls_integer;
begin
    dbms_output.get_line( p_text, v_status );
    return v_status;
exception
when others then
    return 1;
end;
--
function get_buf_text return varchar2 is
    v_text varchar2(32000);
begin
    if buf_enable then
        enable_buf(null,false);
    end if;
    if v_buf_err then
      if length(v_buf_text)=BUFFER_LINE_SIZE and substr(v_buf_text,-length(LSEP))=LSEP then
         v_text:= rtrim(v_buf_text,LSEP);
      else
         v_text:= v_buf_text||LF;
      end if;
    end if;
    v_buf_err:=FALSE;
    while get_line_buf(v_buf_text)=0
    loop
      if length(v_buf_text)=BUFFER_LINE_SIZE and substr(v_buf_text,-length(LSEP))=LSEP then
         v_text:= v_text||rtrim(v_buf_text,LSEP);
      else
         v_text:= v_text||v_buf_text||LF;
      end if;
    end loop;
    return v_text;
exception when VALUE_ERROR then
    v_buf_err:=TRUE;
    return v_text;
end;
-----------------------------------------------------
-- @METAGS enable_buf
procedure enable_buf ( p_size  IN pls_integer default null,
                       p_clear IN boolean default TRUE ) is
    v_size  pls_integer := nvl(p_size,0);
begin
    if inst_info.db_version>=10 then
      BUFFER_LINE_SIZE  := 4000;
    else
      BUFFER_LINE_SIZE  := 255;
    end if;
    if p_clear then
        dbms_output.disable;
        max_buf_size := 0;
    end if;
    if init_sizes then set_sizes; end if;
    if v_size<=0 then
        v_size := stdio_buf_size;
    end if;
    if v_size>BUFFER_LIMIT_SIZE and inst_info.db_version>=10 then
      dbms_output.enable(null);
    else
      v_size:= least(v_size,BUFFER_LIMIT_SIZE);
      dbms_output.enable(v_size);
    end if;
    last_buf_size:= v_size;
    max_buf_size := greatest(max_buf_size,v_size);
    buf_enable := false;
end;
-----------------------------------------------------
-- @METAGS disable_buf
procedure disable_buf is
begin
    dbms_output.disable;
end;
-----------------------------------------------------
function get_profile(p_user varchar2 default null) return varchar2 is
    tmp varchar2(2000);
    i   pls_integer;
    j   pls_integer;
begin
    tmp := nvl(p_user,rtl.USR);
    select properties into tmp from users where username=tmp;
    i := instr(tmp,'|PROFILE ');
    if i>0 then
        j := instr(tmp,'|',i+1);
        if j>0 then
            tmp := substr(tmp,i+9,j-i-9);
        else
            tmp := substr(tmp,i+9);
        end if;
        return nvl(upper(ltrim(rtrim(tmp))),'DEFAULT');
    end if;
    return 'DEFAULT';
exception when NO_DATA_FOUND then
    return 'DEFAULT';
end;
function get_resource_value(p_profile varchar2, p_name varchar2) return varchar2 is
    s   varchar2(2000);
begin
    select /*+ INDEX */ value  into s from profiles
     where profile=p_profile and resource_name=p_name;
    return s;
exception when no_data_found then
    return null;
end;
procedure init_resource(p_resource varchar2 default null) is
    p   varchar2(30);
    n   varchar2(30);
    i   pls_integer;
begin
  i := instr(p_resource,'.');
  if i>0 then
    p := substr(p_resource,1,i-1);
    if p is null then
      p := get_profile;
      cur_profile := p;
    end if;
    n := substr(p_resource,i+1);
    profs.delete(p||'.'||n);
  else
    profs.delete;
  end if;
end;
function get_resource(p_profile varchar2, p_name varchar2) return varchar2 is
    s   varchar2(2000);
    i   varchar2(128);
begin
    if cur_profile is null then
      cur_profile := get_profile;
    end if;
    if p_profile is null then
      s := cur_profile;
    else
      s := p_profile;
    end if;
    i := s||'.'||p_name;
    if profs.exists(i) then
      return profs(i);
    end if;
    s := get_resource_value(s,p_name);
    profs(i) := s;
    return s;
end;
procedure set_resource(p_profile varchar2, p_name varchar2,
                       p_value   varchar2, p_description varchar2 default null) is
    v_name varchar2(30) := upper(ltrim(rtrim(p_name)));
    v_prof varchar2(30) := upper(ltrim(rtrim(p_profile)));
    i varchar2(128);
begin
  if cur_profile is null then
    cur_profile := get_profile;
  end if;
  if v_prof is null then
    v_prof := cur_profile;
  end if;
  i := v_prof||'.'||v_name;
  if p_value is null then
    delete profiles where profile=v_prof and resource_name=v_name;
    profs.delete(i);
  else
    if p_description is null then
        update profiles set value=p_value
         where profile=v_prof and resource_name=v_name;
    else
        update profiles set value=p_value,description=p_description
         where profile=v_prof and resource_name=v_name;
    end if;
    if sql%rowcount=0 then
        insert into profiles(profile,resource_name,value,description)
        values (v_prof,v_name,p_value,p_description);
    end if;
    profs(i) := p_value;
  end if;
  cache_mgr.reg_event(11,i);
end;
-----------------------------------------------------
-- @METAGS fio_close
procedure fio_close is
begin
    vfs_io.fio_close;
end;
--
-- @METAGS fio_open
procedure fio_open is
begin
    vfs_io.fio_open;
end;
--
procedure formon_close is
begin
    fio_close;
end;
--
procedure formon_open is
begin
    fio_open;
end;
-----------------------------------------------------
-- @METAGS get_fio_pid
function get_fio_pid return pls_integer is
begin
    return vfs_io.get_fio_pid;
end;
-----------------------------------------------------
-- @METAGS file_list
function file_list ( location IN varchar2, dir_flag pls_integer default 0, p_sort boolean default null, p_chk boolean default false,
                     name_text pls_integer default NULL) return varchar2 is
begin
  return vfs_io.file_list(location,dir_flag,p_sort,p_chk,name_text);
end file_list;
--
-- @METAGS move_file
procedure move_file ( old_name IN varchar2, new_name IN varchar2, p_chk boolean default false,
                      name_text   pls_integer default NULL ) is
begin
  vfs_io.move_file(old_name,new_name,p_chk,name_text);
end move_file;
--
-- @METAGS delete_file
procedure delete_file ( file_name IN varchar2, p_chk boolean default false,
                        name_text IN pls_integer default NULL ) is
begin
  vfs_io.delete_file(file_name,p_chk,name_text);
end delete_file;
-----------------------------------------------------
-- @METAGS fopen
function fopen (name_i in varchar2, flag_i in pls_integer, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
begin
  return vfs_io.fopen(name_i,flag_i,p_chk,name_text);
end fopen;
--
-- @METAGS fcreate
function fcreate (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                  name_text pls_integer default NULL ) return pls_integer is
begin
  return vfs_io.fcreate(name_i,mode_i,p_chk,name_text);
end fcreate;
--
-- @METAGS fclose
function fclose (fh_i in pls_integer) return pls_integer is
begin
  return vfs_io.fclose(fh_i);
end fclose;
--
-- @METAGS fseek
function fseek (fh_i in pls_integer, pos in out nocopy varchar2, off_i in pls_integer, how_i in pls_integer) return pls_integer is
begin
  return vfs_io.fseek(fh_i,pos,off_i,how_i);
end fseek;
--
function fseek (fh_i in pls_integer, off_i in pls_integer, how_i in pls_integer) return pls_integer is
  i pls_integer;
  p varchar2(30);
begin
  i := fseek(fh_i,p,off_i,how_i);
  if i=0 then
    begin
      i := p;
    exception when rtl.NUMERIC_OVERFLOW then
      i := 2147483647;
    end;
  end if;
  return i;
end;
--
function fseekn(fh_i in pls_integer, off_i in pls_integer, how_i in pls_integer) return number is
  i pls_integer;
  p varchar2(30);
begin
  i := fseek(fh_i,p,off_i,how_i);
  if i=0 then
    return to_number(p);
  end if;
  return i;
end;
--
-- @METAGS fread
function fread (fh_i in pls_integer, sz_i in pls_integer, bf_o in out nocopy raw) return pls_integer is
begin
  return vfs_io.fread(fh_i,sz_i,bf_o);
end fread;
--
-- @METAGS fwrite
function fwrite (fh_i in pls_integer, bf_i in raw, sz_i in pls_integer default 0) return pls_integer is
begin
  return vfs_io.fwrite(fh_i,bf_i,sz_i);
end fwrite;
--
-- @METAGS lha
function lha (clinum in varchar2) return pls_integer is
begin
  return vfs_io.lha(clinum);
end lha;
--
-- @METAGS zip
function zip (arcname in varchar2, dirname in varchar2) return pls_integer is
begin
  return vfs_io.zip(arcname,dirname);
end zip;
--
-- @METAGS run
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
             p_env  boolean default true) return pls_integer is
begin
  return vfs_io.run(ev_i,a0_i,a1_i,a2_i,a3_i,a4_i,a5_i,a6_i,a7_i,a8_i,a9_i,p_env);
end run;
--
-- @METAGS error_message
function  error_message (error_number_i in pls_integer) return varchar2 is
begin
  return vfs_io.error_message(error_number_i);
end error_message;
--
-- @METAGS flist
function flist (dirname_i in varchar2, dirflag_i in pls_integer, p_sort boolean default null,
                name_text pls_integer default NULL) return varchar2 is
begin
  return vfs_io.flist(dirname_i,dirflag_i,p_sort,name_text);
end flist;
--
function flist (dirname_i in varchar2, dirflag_i in pls_integer, filelist_o in out nocopy varchar2, p_sort boolean default null, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
begin
  return vfs_io.flist(dirname_i,dirflag_i,filelist_o,p_sort,p_chk,name_text);
end flist;
--
-- @METAGS fmove
function fmove (oldname_i in varchar2, newname_i in varchar2, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
begin
  return vfs_io.fmove(oldname_i,newname_i,p_chk,name_text);
end fmove;
--
-- @METAGS fdelete
function fdelete (filename_i in varchar2, p_chk boolean default true,
                  name_text  pls_integer default NULL ) return pls_integer is
begin
  return vfs_io.fdelete(filename_i,p_chk,name_text);
end fdelete;
--
-- @METAGS mkdir
function mkdir (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                name_text pls_integer default NULL) return pls_integer is
begin
  return vfs_io.mkdir(name_i,mode_i,p_chk,name_text);
end mkdir;
-----------------------------------------------------
-- @METAGS qsort
procedure qsort (buf in out nocopy varchar2, p_char varchar2 default null, p_mode boolean default true) is
begin
    fio.qsort(buf,nvl(ascii(p_char),10),p_mode);
end;
-----------------------------------------------------
function get_env (name in varchar2) return varchar2 is
begin
  return vfs_io.get_env(name);
end;
-- @METAGS put_env
function put_env (name in varchar2, value in varchar2) return pls_integer is
begin
  return vfs_io.put_env(name,value);
end;
-----------------------------------------------------
-- @METAGS f_open
function f_open(filename  in varchar2,
                open_mode in varchar2,
                p_chk boolean default false,
                name_text pls_integer default NULL ) return pls_integer is
begin
  return vfs_io.f_open(filename,open_mode,p_chk,name_text);
end;
-- @METAGS f_dopen
function f_dopen(handle in pls_integer, open_mode in varchar2 ) return pls_integer is
begin
  return vfs_io.f_dopen(handle,open_mode);
end;
-- @METAGS f_close
function f_close ( file IN OUT nocopy pls_integer  ) return pls_integer is
begin
  return vfs_io.f_close(file);
end;
-- @METAGS f_closeall
procedure f_closeall(p_files boolean default null) is
begin
  vfs_io.f_closeall(p_files);
end;
-- @METAGS f_flush
function f_flush ( file pls_integer  ) return pls_integer is
begin
  return vfs_io.f_flush(file);
end;
-- @METAGS f_seek
function f_seek (file pls_integer, pos in out nocopy varchar2, off_i pls_integer, how_i pls_integer default 0) return pls_integer is
begin
  return vfs_io.f_seek(file,pos,off_i,how_i);
end;
--
function f_seek (file pls_integer, off_i pls_integer, how_i pls_integer default 0) return pls_integer is
  i pls_integer;
  p varchar2(30);
begin
  i := f_seek(file,p,off_i,how_i);
  if i=0 then
    begin
      i := p;
    exception when rtl.NUMERIC_OVERFLOW then
      i := 2147483647;
    end;
  end if;
  return i;
end;
--
function f_seekn(file pls_integer, off_i pls_integer, how_i pls_integer default 0) return number is
  i pls_integer;
  p varchar2(30);
begin
  i := f_seek(file,p,off_i,how_i);
  if i=0 then
    return to_number(p);
  end if;
  return i;
end;
--
-- @METAGS f_truncate
function f_truncate ( file pls_integer, p_size pls_integer default null ) return pls_integer is
begin
  return vfs_io.f_truncate(file,p_size);
end;
-- @METAGS f_tell
function f_tell (file pls_integer) return number is
begin
  return vfs_io.f_tell(file);
end;
--
-- @METAGS f_read
function f_read (file pls_integer, bf_o in out nocopy raw, sz_i pls_integer) return pls_integer is
begin
  return vfs_io.f_read(file,bf_o,sz_i);
end;
-- @METAGS f_write
function f_write (file pls_integer, bf_i in raw, sz_i pls_integer default 0) return pls_integer is
begin
  return vfs_io.f_write(file,bf_i,sz_i);
end;
-- @METAGS read_str
function read_str (file pls_integer, str in out nocopy varchar2,
                   in_text  pls_integer  default NULL,
                   out_text pls_integer  default NULL,
                   sz_i pls_integer default 0) return pls_integer is
begin
  return vfs_io.read_str(file,str,in_text,out_text,sz_i);
end;
-- @METAGS write_str
function write_str (file pls_integer, str varchar2,
                    in_text  pls_integer  default NULL,
                    out_text pls_integer  default NULL,
                    p_nl boolean default true) return pls_integer is
begin
  return vfs_io.write_str(file,str,in_text,out_text,p_nl);
end;
-- @METAGS get_file_name
function get_file_name ( file pls_integer, p_files boolean default true ) return varchar2 is
begin
  return vfs_io.get_file_name(file,p_files);
end;
--
function f_copy ( oldname varchar2,
                  newname varchar2,
                  fsize   in out nocopy varchar2,
                  p_chk   boolean default false,
                  p_write boolean default true,
                  name_text pls_integer default NULL) return pls_integer is
begin
  return vfs_io.f_copy(oldname,newname,fsize,p_chk,p_write,name_text);
end;
--
function f_copy ( oldname varchar2,
                  newname varchar2,
                  p_chk   boolean default false,
                  p_write boolean default true,
                  name_text pls_integer default NULL) return pls_integer is
  i pls_integer;
  s varchar2(30);
begin
  i := f_copy(oldname,newname,s,p_chk,p_write,name_text);
  if i=0 then
    begin
      i := s;
    exception when rtl.NUMERIC_OVERFLOW then
      i := 2147483647;
    end;
  end if;
  return i;
end;
--
function f_copyn( oldname varchar2,
                  newname varchar2,
                  p_chk   boolean default false,
                  p_write boolean default true,
                  name_text pls_integer default NULL) return number is
  i pls_integer;
  s varchar2(30);
begin
  i := f_copy(oldname,newname,s,p_chk,p_write,name_text);
  if i=0 then
    return to_number(s);
  end if;
  return i;
end;
--
function f_info( name   varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy varchar2,
                 p_chk  boolean default false,
                 name_text pls_integer default NULL
                ) return pls_integer is
begin
  return vfs_io.f_info(name,attrs,uowner,gowner,mdate,fsize,p_chk,name_text);
end;
--
function f_info( name   varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy pls_integer,
                 p_chk  boolean default false,
                 name_text pls_integer default NULL
                ) return pls_integer is
  i pls_integer;
  s varchar2(30);
begin
  i := f_info(name,attrs,uowner,gowner,mdate,s,p_chk,name_text);
  if i=0 then
    begin
      fsize := s;
    exception when rtl.NUMERIC_OVERFLOW then
      fsize := -1;
    end;
  else
    fsize := null;
  end if;
  return i;
end;
--
function finfo ( name   varchar2,
                 attrs  in out nocopy varchar2,
                 uowner in out nocopy varchar2,
                 gowner in out nocopy varchar2,
                 mdate  in out nocopy varchar2,
                 fsize  in out nocopy number,
                 p_chk  boolean default false,
                 name_text pls_integer default NULL
                ) return pls_integer is
  i pls_integer;
  s varchar2(30);
begin
  i := f_info(name,attrs,uowner,gowner,mdate,s,p_chk,name_text);
  if i=0 then
    fsize := s;
  else
    fsize := null;
  end if;
  return i;
end;
--
function  opendir( dirname varchar2, mask varchar2 default null,
                   dir_flag  pls_integer default 0, p_chk boolean default false,
                   name_text pls_integer default NULL) return pls_integer is
begin
  return vfs_io.opendir(dirname,mask,dir_flag,p_chk,name_text);
end;
--
function  closedir(dir  in out nocopy pls_integer ) return pls_integer is
begin
  return vfs_io.closedir(dir);
end;
--
function  resetdir(dir  pls_integer ) return pls_integer is
begin
  return vfs_io.resetdir(dir);
end;
--
function  readdir( dir    pls_integer,
                   name   in out nocopy varchar2,
                   attrs  in out nocopy varchar2,
                   uowner in out nocopy varchar2,
                   gowner in out nocopy varchar2,
                   mdate  in out nocopy varchar2,
                   fsize  in out nocopy varchar2
                 ) return pls_integer is
begin
  return vfs_io.readdir(dir,name,attrs,uowner,gowner,mdate,fsize);
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
  i pls_integer;
  s varchar2(30);
begin
  i := readdir(dir,name,attrs,uowner,gowner,mdate,s);
  if i>0 then
    begin
      fsize := s;
    exception when rtl.NUMERIC_OVERFLOW then
      fsize := -1;
    end;
  else
    fsize := null;
  end if;
  return i;
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
  i pls_integer;
  s varchar2(30);
begin
  i := readdir(dir,name,attrs,uowner,gowner,mdate,s);
  if i>0 then
    fsize := s;
  else
    fsize := null;
  end if;
  return i;
end;
-----------------------------------------------------
function put_pipe ( p_text IN varchar2,
                    p_pipe IN varchar2 default null,
                    p_time IN pls_integer default null,
                    p_size IN pls_integer default null,
                    p_nl   IN boolean  default true,
                    p_expand  boolean  default false
                  ) return pls_integer is
	v_status pls_integer;
    v_pipe  varchar2(100);
    v_time  pls_integer;
    v_size  pls_integer;
    len     pls_integer := length(p_text);
    len1    pls_integer;
    pos0    pls_integer := 1;
    pos1    pls_integer;
    b_add_sep boolean;
begin
    if init_pipes then setup_pipes; end if;
    v_size  := nvl(p_size,stdio_pipe_size);
    if v_size<=0 then return 0; end if;
    v_pipe  := nvl(p_pipe,write_pipe_name);
    v_time  := nvl(p_time,stdio_time_out+1);
    dbms_pipe.reset_buffer;
    if len>0 and (p_nl or len>PIPE_LINE_SIZE) then
        loop
            b_add_sep:= false;
            pos1 := instr( p_text, LF, pos0 );
            if pos1=len then
                pos1 := pos1+1;
            end if;
            if pos1 = 0 or pos1>pos0+PIPE_LINE_SIZE then
                len1 := PIPE_LINE_SIZE;
                pos1 := pos0+PIPE_LINE_SIZE-1;
                b_add_sep:= pos1<len;
            else
                len1 := pos1-pos0;
            end if;
            if not b_add_sep then
              dbms_pipe.pack_message( substr(p_text,pos0,len1) );
            else
              len1 := len1-length(LSEP);
              pos1 := pos1-length(LSEP);
              dbms_pipe.pack_message( substr(p_text,pos0,len1) || LSEP );
            end if;
            v_status:=dbms_pipe.send_message( v_pipe, v_time, v_size );
            pos1 := pos1 + 1;
            exit when pos1>len or v_status<>0;
            pos0 := pos1;
        end loop;
    else
        dbms_pipe.pack_message(p_text);
        v_status:=dbms_pipe.send_message( v_pipe, v_time, v_size );
    end if;
    if p_expand and v_status=1 then
      begin
        v_pipe := upper(v_pipe);
        select pipe_size into len1 from v$db_pipes where name=v_pipe;
        len1:= (len1+nvl(len,0))/8192;
        len1:= (len1+4)*8192;
        if v_size<len1 and len1<=1048576  then
          if pos0>1 then
            v_status := put_pipe(substr(p_text,pos0),v_pipe,v_time,len1,p_nl,false);
          else
            v_status := put_pipe(p_text,v_pipe,v_time,len1,p_nl,false);
          end if;
        end if;
      exception when no_data_found then null;
      end;
    end if;
    return v_status;
end;
-- @METAGS put_line_pipe
procedure put_line_pipe ( p_text IN varchar2,
                          p_pipe IN varchar2 default null,
                          p_time IN pls_integer default null,
                          p_size IN pls_integer default null,
                          p_nl   IN boolean  default true
                        ) is
	v_status pls_integer;
begin
    v_status := put_pipe(p_text,p_pipe,p_time,p_size,p_nl);
exception when others then
    null;
end put_line_pipe;
-----------------------------------------------------
function get_pipe ( p_text OUT nocopy varchar2,
                    p_pipe IN varchar2 default null,
                    p_time IN pls_integer default null
                  ) return pls_integer is
	v_status pls_integer;
    v_pipe  varchar2(100);
    v_time  pls_integer;
    v_itm   pls_integer;
    v_num   number;
    v_dat   date;
    v_raw   raw(4096);
    v_row   rowid;
    v_msg   varchar2(4096);
    v_text  varchar2(32767);
begin
    if init_pipes then setup_pipes; end if;
    v_pipe := nvl(p_pipe,read_pipe_name);
    v_time := nvl(p_time,stdio_time_out);
    v_text := null;
    dbms_pipe.reset_buffer;
    v_status:=dbms_pipe.receive_message( v_pipe, v_time );
    if v_status=0 then
      loop
        v_itm := dbms_pipe.next_item_type;
  --        0    no more items
  --        9    varchar2
  --        6    number
  --       11    rowid
  --       12    date
  --       23    raw
        exit when v_itm=0;
        if not v_text is null then v_text := v_text||LF; end if;
        if v_itm=9 then
            dbms_pipe.unpack_message(v_msg);
        elsif v_itm=6 then
            dbms_pipe.unpack_message(v_num);
            v_msg := to_char(v_num);
        elsif v_itm=12 then
            dbms_pipe.unpack_message(v_dat);
            v_msg := to_char(v_dat,'HH24:MI:SS DD/MM/YYYY');
        elsif v_itm=23 then
            dbms_pipe.unpack_message_raw(v_raw);
            v_msg := rawtohex(v_raw);
        elsif v_itm=11 then
            dbms_pipe.unpack_message_rowid(v_row);
            v_msg := rowidtochar(v_row);
        end if;
        v_text := v_text||v_msg;
      end loop;
    end if;
    p_text := v_text;
    return v_status;
end;
-- @METAGS get_line_pipe
function get_line_pipe ( p_text OUT nocopy varchar2,
                         p_pipe IN varchar2 default null,
                         p_time IN pls_integer default null
                       ) return pls_integer is
begin
    return get_pipe(p_text,p_pipe,p_time);
exception when others then
    return  -1;
end get_line_pipe;
-----------------------------------------------------
function get_pipe_text ( p_pipe varchar2 default null,
                         p_time pls_integer default 0) return varchar2 is
  v_msg   varchar2(5000);
  v_text  varchar2(32767);
  v_pipe  varchar2(100);
  v_time  pls_integer  := p_time;
begin
  if init_pipes then setup_pipes; end if;
  v_pipe := nvl(p_pipe,read_pipe_name);
  v_time := nvl(p_time,stdio_time_out);
  while get_pipe(v_msg,v_pipe,v_time)=0 loop
    if length(v_msg)=PIPE_LINE_SIZE and substr(v_msg,-length(LSEP))=LSEP then
       v_text := v_text||rtrim(v_msg,LSEP);
    else
       v_text := v_text||v_msg||LF;
    end if;
    exit when length(v_text)>28000;
    v_time := 0;
  end loop;
  return v_text;
end;
-----------------------------------------------------
-- @METAGS setup_pipes
procedure setup_pipes ( p_read  IN varchar2 default STDIOPIPENAME,
                        p_write IN varchar2 default STDIOPIPENAME,
                        p_time  IN pls_integer default STDIOTIMEOUT,
                        p_size  IN pls_integer default STDIOPIPESIZE
                      ) is
    v_read  varchar2(100) := nvl(p_read, read_pipe_name );
    v_write varchar2(100) := nvl(p_write,write_pipe_name);
    v_time pls_integer := nvl(p_time, stdio_time_out );
    v_size pls_integer := nvl(p_size, stdio_pipe_size);
begin
    if v_read is null or v_read=STDIOPIPENAME then
        v_read:=STDIOPIPENAME||rtl.session_id;
    end if;
    if v_write is null or v_write=STDIOPIPENAME then
        v_write:=STDIOPIPENAME||rtl.session_id;
    end if;
    read_pipe_name := v_read;
    write_pipe_name:= v_write;
    stdio_time_out := nvl(v_time,STDIOTIMEOUT);
    stdio_pipe_size:= nvl(v_size,STDIOPIPESIZE);
    init_pipes := false;
end setup_pipes;
-----------------------------------------------------
-- @METAGS get_pipe_info
procedure get_pipe_info( p_read  OUT nocopy varchar2,
                         p_write OUT nocopy varchar2,
                         p_time  OUT nocopy pls_integer,
                         p_size  OUT nocopy pls_integer
                        ) is
begin
    if init_pipes then setup_pipes; end if;
    p_read  := read_pipe_name;
    p_write := write_pipe_name;
    p_time  := stdio_time_out;
    p_size  := stdio_pipe_size;
end get_pipe_info;
-----------------------------------------------------
function get_setting(p_name varchar2) return varchar2 is
    s   varchar2(2000);
begin
    select /*+ INDEX */ value  into s from settings where name=p_name;
    return s;
exception when no_data_found then
    return null;
end;
procedure init_setting(p_name varchar2 default null) is
begin
  if p_name is null then
    setts.delete;
  else
    setts.delete(p_name);
  end if;
end;
function setting(p_name varchar2) return varchar2 is
    s   varchar2(2000);
begin
    if setts.exists(p_name) then
      return setts(p_name);
    end if;
    s := get_setting(p_name);
    setts(p_name) := s;
    return s;
end;
function num_set(p_name varchar2) return number is
    n   number;
begin
    n := setting(p_name);
    return n;
exception when others then
    return null;
end;
procedure put_setting(p_name varchar2, p_value   varchar2,
                      p_description varchar2 default null) is
    v_name varchar2(30) := upper(ltrim(rtrim(p_name)));
begin
  if p_value is null then
    delete settings where name=v_name;
    setts.delete(v_name);
  else
    if p_description is null then
        update settings set value=p_value where name=v_name;
    else
        update settings set value=p_value, description=p_description where name=v_name;
    end if;
    if sql%rowcount=0 then
        insert into settings(name,value,description) values (v_name,p_value,p_description);
    end if;
    setts(v_name) := p_value;
  end if;
  cache_mgr.reg_event(10,v_name);
end;
-----------------------------------------------------
-- @METAGS set_def_text
procedure set_def_text( p_txt      varchar2,
                        p_slash    varchar2 default null,
                        p_add_cr   varchar2 default null,
                        p_name_txt varchar2 default null) is
begin
  vfs_io.set_def_text(p_txt,p_slash,p_add_cr,p_name_txt);
end set_def_text;
-----------------------------------------------------
-- @METAGS set_sizes
procedure set_sizes( line_size   IN  pls_integer default null,
                     buffer_size IN  pls_integer default null ) is
    v_buf   pls_integer := buffer_size;
begin
    if v_buf is null then
        v_buf := num_set('STDIO_BUFFER_SIZE');
    end if;
    if v_buf<=0 then
        v_buf := STDIOBUFFERSIZE;
    end if;
    stdio_buf_size := v_buf;
    init_sizes := false;
    vfs_io.set_size(line_size);
end;
-----------------------------------------------------
procedure get_buf_sizes( cur_size OUT nocopy pls_integer,
                         max_size OUT nocopy pls_integer ) is
begin
    if init_sizes then set_sizes; end if;
    cur_size := last_buf_size;
    max_size := max_buf_size;
end;
-- @METAGS get_sizes
procedure get_sizes( line_size   OUT nocopy pls_integer,
                     buffer_size OUT nocopy pls_integer ) is
begin
    if init_sizes then set_sizes; end if;
    buffer_size := stdio_buf_size;
    vfs_io.get_size(line_size);
end;
-----------------------------------------------------
procedure Init is
begin
    init_pipes := true;
    init_sizes := true;
    buf_enable := true;
    cur_profile:= null;
    vfs_io.init;
end;
-----------------------------------------------------
end stdio;
/
show errors

