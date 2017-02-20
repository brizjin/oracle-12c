prompt stdio body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/STDIO2.SQL $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
stdio is
-- Text conversion strings
-- win 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ¨¸¹'
strdos varchar2(67);
strunx varchar2(67);
strwin varchar2(67);
strkoi varchar2(67);
--
    LF      constant varchar2(1) := chr(10);
    CR      constant varchar2(2) := chr(13);
    LSEP    constant varchar2(2) := chr(127)||chr(127); /* Ðàçäåëèòåëü äëèííûõ ñòðîê */
    ENOENT  constant pls_integer := -2;
    EIO     constant pls_integer := -5;
    EBADF   constant pls_integer := -9;
    EACCES  constant pls_integer := -13;
    EFAULT  constant pls_integer := -14;
    EBUSY   constant pls_integer := -16;
    EINVAL  constant pls_integer := -22;
    ETXTBSY constant pls_integer := -26;
    EPIPE   constant pls_integer := -32;
    BUFFER_LIMIT_SIZE constant pls_integer:= 1000000;
    BUFFER_LINE_SIZE pls_integer;
    PIPE_LINE_SIZE constant pls_integer := 4000;
--
type file_info_t is record (
    name      varchar2(1024),
    open_mode varchar2(10),
    stream    raw(10),
    lsize     pls_integer,
    text      pls_integer
);
type file_tbl_t is table of file_info_t index by binary_integer;
--type values_tbl_t is table of varchar2(2000) index by varchar2(128);
--type sizes_tbl_t  is table of pls_integer index by varchar2(128);
--
ffio  file_tbl_t;
fdir  file_tbl_t;
--
profs "CONSTANT".varchar2_table_s;--values_tbl_t;
pipes "CONSTANT".integer_table_s;--sizes_tbl_t;
--
read_pipe_name   varchar2(100);
write_pipe_name  varchar2(100);
cur_profile      varchar2(30);
stdio_line_size  pls_integer;
stdio_buf_size   pls_integer;
stdio_pipe_size  pls_integer;
stdio_time_out   pls_integer;
last_buf_size    pls_integer;
max_buf_size     pls_integer;
buffer_written   pls_integer;
buf_enable  boolean := true;
init_pipes  boolean := true;
init_sizes  boolean := true;
init_text   boolean := true;
--
fio_mkdir   boolean;
fio_pid  pls_integer;
fio_lha  varchar2(2000);
fio_zip  varchar2(2000);
fio_lock varchar2(2000);
fio_home varchar2(1000);
fio_srch varchar2(1000);
l_srch   pls_integer;
--
def_text       pls_integer;
nam_text       pls_integer;
slash          varchar2(1);
slash2         varchar2(2);
selfdir        varchar2(3);
def_cr_add     varchar2(10);
v_buf_err      boolean:= false;
v_buf_text     varchar2(4096);
-----------------------------------------------------
-- @METAGS get_str
function get_str (typ in pls_integer) return varchar2 is
begin
    if typ=DOSTEXT then
        return strdos;
    elsif typ=UNXTEXT then
        return strunx;
    elsif typ=WINTEXT then
        return strwin;
    elsif typ=KOITEXT then
        return strkoi;
    end if;
    if def_text=DOSTEXT then
        return strdos;
    elsif def_text=WINTEXT then
        return strwin;
    elsif def_text=KOITEXT then
        return strkoi;
    end if;
    return strunx;
end;
--
-- @METAGS transform
function transform( txt in varchar2,
                    in_text  in pls_integer,
                    out_text in pls_integer
                  ) return varchar2 is
    v_in    pls_integer;
    v_out   pls_integer;
begin
    if init_text then set_def_text(null); end if;
    v_in := nvl(in_text, def_text);
    v_out:= nvl(out_text,def_text);
    if v_in=v_out then return txt; end if;
    return translate(txt,get_str(v_in),get_str(v_out));
end transform;
-----------------------------------------------------
function correct_path( p_path in varchar2 ) return varchar2 is
begin
    if l_srch>1 and p_path like fio_srch then
        return replace(translate(fio_home||substr(p_path,l_srch),'/\',slash2),selfdir,slash);
    end if;
    return replace(translate(p_path,'/\',slash2),selfdir,slash);
end;
--
-- @METAGS open
function open ( location  in varchar2,
                filename  in varchar2,
                open_mode in varchar2,
                raising   IN boolean default FALSE,
                line_size IN pls_integer default NULL,
                name_text IN pls_integer default NULL
              ) return pls_integer is
    idx pls_integer;
begin
    if init_text then set_def_text(null); end if;
    idx := f_open( location || slash || filename, open_mode, false, name_text );
    if idx>0 then
        if line_size>0 then
            ffio(idx).lsize := line_size;
        end if;
        return idx;
    elsif idx=ENOENT then
        if raising then
            raise INVALID_PATH;
        else
            message.error( constant.EXEC_ERROR, 'FILEPATH', location || slash || filename );
        end if;
    elsif idx=EINVAL then
        if raising then
            raise INVALID_MODE;
        else
            message.error( constant.EXEC_ERROR, 'FILEMODE', filename, open_mode );
        end if;
    else
        if raising then
            raise INVALID_OPERATION;
        else
            message.error( constant.EXEC_ERROR, 'FILEOPERATION', filename );
        end if;
    end if;
end open;
--
-- @METAGS close
procedure close ( file IN OUT nocopy pls_integer ,
                  raising IN boolean default FALSE
                ) is
    idx pls_integer;
begin
    idx := f_close( file );
    if idx=0 then
        return;
    elsif idx=EINVAL then
        if raising then
            raise INVALID_FILEHANDLE;
        else
            message.error( constant.EXEC_ERROR, 'FILEHANDLE', get_file_name(file,true) );
        end if;
    else
        if raising then
            raise WRITE_ERROR;
        else
            message.error( constant.EXEC_ERROR, 'FILEWRITE', get_file_name(file,true) );
        end if;
    end if;
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
                 p_flash IN boolean default FALSE,
                 in_text  IN pls_integer default NULL,
                 out_text IN pls_integer default NULL) is
    idx pls_integer := 0;
begin
    if not buffer is null then
        idx := write_str(file, buffer, in_text, out_text, false);
    end if;
    if p_flash and idx>=0 then
        idx := f_flush( file );
    end if;
    if idx>=0 then
        return;
    elsif idx=EINVAL then
        if raising then
            raise stdio.INVALID_FILEHANDLE;
        else
            message.error( constant.EXEC_ERROR, 'FILEHANDLE', get_file_name(file,true) );
        end if;
    elsif idx in (EIO,EPIPE) then
        if raising then
            raise stdio.WRITE_ERROR;
        else
            message.error( constant.EXEC_ERROR, 'FILEWRITE', get_file_name(file,true) );
        end if;
    else
        if raising then
            raise stdio.INVALID_OPERATION;
        else
            message.error( constant.EXEC_ERROR, 'FILEOPERATION', get_file_name(file,true) );
        end if;
    end if;
end fput;
--
-- @METAGS put_line
procedure put_line ( file     IN pls_integer,
                     buffer   IN varchar2,
                     raising  IN boolean default FALSE,
                     in_text  IN pls_integer  default NULL,
                     out_text IN pls_integer  default NULL
                   ) is
    idx pls_integer := 0;
begin
    idx := write_str(file, buffer, in_text, out_text );
    if idx>=0 then
        return;
    elsif idx=EINVAL then
        if raising then
            raise stdio.INVALID_FILEHANDLE;
        else
            message.error( constant.EXEC_ERROR, 'FILEHANDLE', get_file_name(file,true) );
        end if;
    elsif idx in (EIO,EPIPE) then
        if raising then
            raise stdio.WRITE_ERROR;
        else
            message.error( constant.EXEC_ERROR, 'FILEWRITE', get_file_name(file,true) );
        end if;
    else
        if raising then
            raise stdio.INVALID_OPERATION;
        else
            message.error( constant.EXEC_ERROR, 'FILEOPERATION', get_file_name(file,true) );
        end if;
    end if;
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
    buf varchar2(32767);
    nl  varchar2(2);
    v_in    pls_integer;
    v_out   pls_integer;
begin
    if init_text then set_def_text(null); end if;
    v_in := nvl(in_text, def_text);
    v_out:= nvl(out_text,def_text);
    if instr(def_cr_add,v_out)>0 then
        nl := CR||LF;
    else
        nl := LF;
    end if;
    buf := replace(format,'%1',p_text1);
    buf := replace(buf,'%2',p_text2);
    buf := replace(buf,'%3',p_text3);
    buf := replace(buf,'%4',p_text4);
    buf := replace(buf,'%5',p_text5);
    buf := replace(buf,'\n',nl);
    buf := replace(buf,'\t',chr(9));
    buf := replace(buf,'\\','\');
    if v_in<>v_out then
        buf := translate(buf,get_str(v_in),get_str(v_out));
    end if;
    fput( file, buf, raising );
end putf;
--
-- @METAGS flush
procedure flush ( file     IN  pls_integer,
                  raising  IN  boolean default FALSE ) is
begin
    fput(file,null,raising,TRUE);
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
    buf varchar2(32767);
    pos varchar2(30);
    l   pls_integer;
    v_in    pls_integer;
    v_out   pls_integer;
    idx pls_integer;
begin
    idx := read_str(file,buf,in_text,out_text);
    if idx=0 then
        buffer := null;
        return false;
    elsif idx>0 then
        l := nvl(l_size,ffio(file).lsize);
        if length(buf)>l then
            v_in := fio.fseek( file, ffio(file).stream, -idx, 1, pos );
            if raising then
                raise stdio.INVALID_LINESIZE;
            else
                message.error( constant.EXEC_ERROR, 'LINESIZE', get_file_name(file,true), l );
            end if;
        end if;
        buffer := buf;
        return true;
    elsif idx=EINVAL then
        if raising then
            raise stdio.INVALID_FILEHANDLE;
        else
            message.error( constant.EXEC_ERROR, 'FILEHANDLE', get_file_name(file,true) );
        end if;
    elsif idx in (EIO,EPIPE) then
        if raising then
            raise stdio.READ_ERROR;
        else
            message.error( constant.EXEC_ERROR, 'FILEREAD', get_file_name(file,true) );
        end if;
    else
        if raising then
            raise stdio.INVALID_OPERATION;
        else
            message.error( constant.EXEC_ERROR, 'FILEOPERATION', get_file_name(file,true) );
        end if;
    end if;
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
    return fio_pid>0 and ffio.exists(file);
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
begin
    return rtl.get_profile(p_user);
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
      p := rtl.get_profile;
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
      cur_profile := rtl.get_profile;
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
    cur_profile := rtl.get_profile;
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
-- @METAGS fio_init
procedure fio_init is
    ftmp    varchar2(2000);
    flog    varchar2(2000);
    froot   varchar2(2000);
    fbase   varchar2(4000);
    fexec   varchar2(32000);
    user_id varchar2(30);
    v_user  varchar2(30);
    fdbg    pls_integer;
    v_prof  varchar2(30);
    v_def   varchar2(30) := 'DEFAULT';
    not_def boolean;
    i   pls_integer;
    j   pls_integer;
    u   rtl.users_info;
begin
    if init_sizes then set_sizes; end if;
    if init_text  then set_def_text(null); end if;
    fio_mkdir := false;
    ffio.delete;
    fdir.delete;
    not_def:= rtl.get_user_info(u);
    user_id:= u.id;
    v_user := u.ora_user;
    cur_profile := rtl.get_profile(v_user);
    v_prof := cur_profile;
    dbms_application_info.read_module( ftmp, flog );
    if flog='SYSTEM_JOBS for '||inst_info.owner then
        if u.id>0 then
            user_id:= '+'||user_id;
            v_user := nvl(substr(ftmp,1,instr(ftmp,'.')-1),v_user);
            v_prof := rtl.get_profile(v_user);
        end if;
        v_prof := nvl(get_resource(v_prof,'JOB_PROFILE'),v_prof);
    end if;
    not_def:= v_prof<>v_def;
    flog := get_resource(v_prof,'FIO_DEBUG_LEVEL');
    froot:= get_resource(v_prof,'FIO_ROOT_DIR');
    fbase:= get_resource(v_prof,'FIO_BASE_DIR');
    if substr(upper(get_resource(v_prof,'FIO_MAKE_DIR')),1,1)='Y' then
        fio_mkdir := true;
    end if;
    if not_def then
        if flog is null then
            flog := get_resource(v_def,'FIO_DEBUG_LEVEL');
        end if;
        if froot is null then
            froot:= get_resource(v_def,'FIO_ROOT_DIR');
        end if;
        ftmp := get_resource(v_def,'FIO_BASE_DIR');
        if fbase is null then
            fbase := ftmp;
        elsif not ftmp is null then
            fbase := fbase||';'||ftmp;
        end if;
    end if;
    begin
        fdbg := nvl(flog,'0');
    exception when others then
        fdbg := 0;
    end;
    --if fdbg<0 then fdbg:=0; end if;
    fio_home := get_resource(v_def, 'FIO_HOME_DIR');
    fio_srch := get_resource(v_def, 'FIO_REPLACE_DIR')||'%';
    l_srch := length(fio_srch);
    froot:= fio_home||froot;
    if not fbase is null then
      j := 0;
      loop
        i := instr(fbase,';',j+1);
        j := instr(fbase,':',i);
        exit when j=0;
        if j=i+2 and substr(fbase,j+1,1)='\' then null; else
            fbase := substr(fbase,1,j-1)||';'||substr(fbase,j+1);
        end if;
      end loop;
    end if;
    if substr(fbase,1,1)=';' then
        fbase := substr(fbase,2);
    end if;
    if not fio_home is null then
        fbase:= replace(replace(replace(fbase,';<',':<'),';',';'||fio_home),':<',';<');
        if substr(fbase,1,1)<>'<' then
            fbase := fio_home||fbase;
        end if;
    end if;
    flog := ';'||nvl(get_resource(v_def,'FIO_TEMP_DIR'),'/tmp');
    if instr(fbase,flog)=0 then
        fbase:= fbase||flog;
    end if;
    flog := get_resource(v_def,'FIO_LOG_FILE');
    if not_def then
        ftmp := chr(1);
        for c in (
            select resource_name,decode(profile,v_def,'2','1'),value
              from profiles
             where (profile=v_prof or profile=v_def)
               and resource_name like 'FIO\_%\_CMD' escape '\'
             order by 1,2
        )loop
          if ftmp<>c.resource_name then
            ftmp := c.resource_name;
            fexec:= fexec||';'||c.value;
            if ftmp='FIO_LHA_CMD' then
                fio_lha := c.value;
            elsif ftmp='FIO_ZIP_CMD' then
                fio_zip := c.value;
            end if;
          end if;
        end loop;
    else
        for c in (select resource_name,value from profiles
                   where profile=v_prof and resource_name like 'FIO\_%\_CMD' escape '\')
        loop
            fexec := fexec||';'||c.value;
            if c.resource_name='FIO_LHA_CMD' then
                fio_lha := c.value;
            elsif c.resource_name='FIO_ZIP_CMD' then
                fio_zip := c.value;
            end if;
        end loop;
    end if;
    ftmp := ltrim(rtrim(rtl.setting('LOCK_START')));
    if ftmp is null or upper(ftmp) like 'LIB%' then
      fio_lock := null;
    else
      fio_lock := inst_info.owner||'.'||nvl(rtl.setting('LOCK_PROFILE'),inst_info.owner);
      if instr(fio_lock,'$')>0 and nvl(substr(rtl.setting('DEF_SLASH'),1,1),'/')<>'\' then
        fio_lock := replace(fio_lock,'$','\$');
      end if;
      fio_lock := ftmp||' '||fio_lock||' '||nvl(rtl.setting('LOCK_PATH'),'./lock.ini')||' % % % %';
      fexec := fexec||';'||fio_lock;
    end if;
    fio_pid := fio.open(flog,froot,fbase,substr(fexec,2),inst_info.owner||'.'||v_user||'.'||user_id,fdbg);
    if fio_pid>0 then
      if not_def then
          ftmp := chr(1);
          for c in (
              select resource_name,decode(profile,v_def,'2','1'),value
                from profiles
               where (profile=v_prof or profile=v_def)
                 and resource_name like 'FIO\_%' escape '\' and resource_name not in
                     ('FIO_LOG_FILE','FIO_ROOT_DIR','FIO_BASE_DIR','FIO_DEBUG_LEVEL')
               order by 1,2
          )loop
            if ftmp<>c.resource_name then
              ftmp := c.resource_name;
              fbase:= c.value;
              fdbg := fio.put_env(ftmp,fbase);
            end if;
          end loop;
      else
          for c in (select resource_name,value from profiles
                     where profile = v_prof
                       and resource_name like 'FIO\_%' escape '\' and resource_name not in
                     ('FIO_LOG_FILE','FIO_ROOT_DIR','FIO_BASE_DIR','FIO_DEBUG_LEVEL'))
          loop
              ftmp := c.resource_name;
              fbase:= c.value;
              fdbg := fio.put_env(ftmp,fbase);
          end loop;
      end if;
      if not fio_lock is null then
        fdbg := fio.put_env('FIO_LOCK_START_CMD',fio_lock);
        fio_lock := upper(substr(fio_lock,1,instr(fio_lock,' ')-1))||'%';
      end if;
    else
      message.error( constant.EXEC_ERROR, 'FORMON_ERROR', to_char(fio_pid) );
    end if;
end fio_init;
--
-- @METAGS fio_close
procedure fio_close is
begin
    if fio_pid>0 then
        begin
            f_closeall;
        exception
            when rtl.INVALID_PACKAGE_STATE then raise;
            when others then null;
        end;
        fio.close;
        ffio.delete;
        fdir.delete;
    end if;
    fio_pid := NULL;
end;
--
-- @METAGS fio_open
procedure fio_open is
begin
  if nvl(fio_pid,0)<=0 then fio_init;  end if;
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
    return fio_pid;
end;
-----------------------------------------------------
-- @METAGS file_list
function file_list ( location IN varchar2, dir_flag pls_integer default 0, p_sort boolean default null, p_chk boolean default false,
                     name_text pls_integer default NULL) return varchar2 is
    i pls_integer;
    t pls_integer;
    s varchar2(1024);
    l varchar2(32767);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if t<>def_text then
      s := translate(location,get_str(def_text),get_str(t));
    else
      s := location;
    end if;
    i := fio.flist(correct_path(s),l,p_chk,dir_flag);
    if i is null then
      fio_init;
      i := fio.flist(correct_path(s),l,p_chk,dir_flag);
    end if;
    if i<0 then
      fio.err_msg(i,s);
      message.error( constant.EXEC_ERROR, 'EXTERNAL_ERROR', 'FILE_LIST', s );
    elsif i>0 then
      if t<>def_text then
        l := translate(l,get_str(t),get_str(def_text));
      end if;
      if i>1 and not p_sort is null then
        fio.qsort(l,10,p_sort);
      end if;
    end if;
    return l;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FILE_LIST', fio_pid);
  end if;
end file_list;
--
-- @METAGS move_file
procedure move_file ( old_name IN varchar2, new_name IN varchar2, p_chk boolean default false,
                      name_text   pls_integer default NULL ) is
    i pls_integer;
    s varchar2(1024);
begin
    i := fmove(old_name,new_name,p_chk,name_text);
    if i<0 then
      fio.err_msg(i,s);
      message.error( constant.EXEC_ERROR, 'EXTERNAL_ERROR', 'MOVE_FILE', s );
    end if;
end move_file;
--
-- @METAGS delete_file
procedure delete_file ( file_name IN varchar2, p_chk boolean default false,
                        name_text IN pls_integer default NULL ) is
    i pls_integer;
    s varchar2(1024);
begin
    i := fdelete(file_name,p_chk,name_text);
    if i<0 then
      fio.err_msg(i,s);
      message.error( constant.EXEC_ERROR, 'EXTERNAL_ERROR', 'DELETE_FILE', s );
    end if;
end delete_file;
-----------------------------------------------------
-- @METAGS fopen
function fopen (name_i in varchar2, flag_i in pls_integer, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
    i pls_integer;
    t pls_integer;
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := correct_path(translate(name_i,get_str(def_text),get_str(t)));
    else
      n := correct_path(name_i);
    end if;
    i := fio.hopen(n,flag_i,p_chk);
    if i is null then
      fio_init;
      if def_text<>t then
        n := correct_path(translate(name_i,get_str(def_text),get_str(t)));
      else
        n := correct_path(name_i);
      end if;
      i := fio.hopen(n,flag_i,p_chk);
    end if;
    if i>0 and not ffio.exists(i) then
      ffio(i).name := n;
      ffio(i).lsize:= flag_i;
      ffio(i).text := t;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FOPEN', fio_pid);
  end if;
end fopen;
--
-- @METAGS fcreate
function fcreate (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                  name_text pls_integer default NULL ) return pls_integer is
    i pls_integer;
    t pls_integer;
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := correct_path(translate(name_i,get_str(def_text),get_str(t)));
    else
      n := correct_path(name_i);
    end if;
    i := fio.hcreate(n,mode_i,p_chk);
    if i is null then
      fio_init;
      if def_text<>t then
        n := correct_path(translate(name_i,get_str(def_text),get_str(t)));
      else
        n := correct_path(name_i);
      end if;
      i := fio.hcreate(n,mode_i,p_chk);
    end if;
    if i>0 and not ffio.exists(i) then
      ffio(i).name := n;
      ffio(i).lsize:= mode_i;
      ffio(i).text := t;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FCREATE', fio_pid);
  end if;
end fcreate;
--
-- @METAGS fclose
function fclose (fh_i in pls_integer) return pls_integer is
    i pls_integer;
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    if ffio.exists(fh_i) and not ffio(fh_i).stream is null then
      i := fio.fclose( fh_i, ffio(fh_i).stream );
    else
      i := fio.hclose(fh_i);
      if i is null then
        fio_init;
        i := fio.hclose(fh_i);
      end if;
    end if;
    if i=0 then
      ffio.delete(fh_i);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FCLOSE', fio_pid);
  end if;
end fclose;
--
-- @METAGS fseek
function fseek (fh_i in pls_integer, pos in out nocopy varchar2, off_i in pls_integer, how_i in pls_integer) return pls_integer is
    i pls_integer;
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    i := fio.hseek(fh_i,off_i,how_i,pos);
    if i is null then
      fio_init;
      i := fio.hseek(fh_i,off_i,how_i,pos);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FSEEK', fio_pid);
  end if;
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
    i pls_integer;
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    i := fio.hread(fh_i,bf_o,sz_i);
    if i is null then
      fio_init;
      i := fio.hread(fh_i,bf_o,sz_i);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FREAD', fio_pid);
  end if;
end fread;
--
-- @METAGS fwrite
function fwrite (fh_i in pls_integer, bf_i in raw, sz_i in pls_integer default 0) return pls_integer is
    i pls_integer;
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    i := fio.hwrite(fh_i,bf_i,sz_i);
    if i is null then
      fio_init;
      i := fio.hwrite(fh_i,bf_i,sz_i);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FWRITE', fio_pid);
  end if;
end fwrite;
--
-- @METAGS lha
function lha (clinum in varchar2) return pls_integer is
begin
  return run(fio_lha, clinum, p_env=>false );
end lha;
--
-- @METAGS zip
function zip (arcname in varchar2, dirname in varchar2) return pls_integer is
begin
  return run(fio_zip, arcname, dirname, p_env=>false );
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
    i pls_integer;
    j pls_integer;
    env varchar2(2000) := ev_i;
    cmd varchar2(2000);
    str varchar2(2000);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    if p_env then
      if not env like 'FIO_%_CMD' then
        env := 'FIO_'||env||'_CMD';
      end if;
      if env='FIO_COPY_CMD' then
        return f_copy(a0_i,a1_i);
      else
        i := fio.get_env(env,cmd);
      end if;
    else
      cmd := env;
    end if;
    if cmd is null then
      return -6512;
    end if;
    if not fio_lock is null and upper(cmd) like fio_lock then
      str := dbms_utility.format_call_stack;
      j := instr(str,'.',1,2);
      i := instr(str,LF,j);
      if substr(str,j+1,i-j-1)='RTL' then
        null;
      else
        raise rtl.NO_PRIVILEGES;
      end if;
    end if;
    i := fio.run(cmd, a0_i, a1_i, a2_i, a3_i, a4_i, a5_i, a6_i, a7_i, a8_i, a9_i);
    if i is null then
      fio_init;
      if p_env then
        i := fio.get_env(env,cmd);
      end if;
      i := fio.run(cmd, a0_i, a1_i, a2_i, a3_i, a4_i, a5_i, a6_i, a7_i, a8_i, a9_i);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'RUN ' || ev_i, fio_pid);
  end if;
end run;
--
-- @METAGS error_message
function  error_message (error_number_i in pls_integer) return varchar2 is
    err_str varchar2(1024);
begin
    fio.err_msg(error_number_i,err_str);
    return err_str;
end error_message;
--
-- @METAGS flist
function flist (dirname_i in varchar2, dirflag_i in pls_integer, p_sort boolean default null,
                name_text pls_integer default NULL) return varchar2 is
begin
    return file_list(dirname_i,dirflag_i,p_sort,true,name_text);
end flist;
--
function flist (dirname_i in varchar2, dirflag_i in pls_integer, filelist_o in out nocopy varchar2, p_sort boolean default null, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
    i pls_integer;
    t pls_integer;
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := translate(dirname_i,get_str(def_text),get_str(t));
    else
      n := dirname_i;
    end if;
    i := fio.flist(correct_path(n),filelist_o,p_chk,dirflag_i);
    if i is null then
      fio_init;
      i := fio.flist(correct_path(n),filelist_o,p_chk,dirflag_i);
    end if;
    if i>0 and t<>def_text then
       filelist_o := translate(filelist_o,get_str(t),get_str(def_text));
    end if;
    if i>1 and not p_sort is null then
       fio.qsort(filelist_o,10,p_sort);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FLIST', fio_pid);
  end if;
end flist;
--
-- @METAGS fmove
function fmove (oldname_i in varchar2, newname_i in varchar2, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
    i pls_integer;
    t pls_integer;
    o varchar2(1024);
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      o := translate(oldname_i,get_str(def_text),get_str(t));
      n := translate(newname_i,get_str(def_text),get_str(t));
    else
      o := oldname_i;
      n := newname_i;
    end if;
    if fio_mkdir then
      i := fio.frename(correct_path(o),correct_path(n),p_chk);
      if i is null then
        fio_init;
        i := fio.frename(correct_path(o),correct_path(n),p_chk);
      end if;
    else
      declare
        attrs  varchar2(30);
        uowner varchar2(100);
        gowner varchar2(100);
        mdate  varchar2(30);
        fsize  varchar2(30);
      begin
        i := f_info(o,attrs,uowner,gowner,mdate,fsize,p_chk,def_text);
        if i=0 then
          if substr(attrs,1,1)='d' then
            i := -6512;
          else
            i := fio.frename(correct_path(o),correct_path(n),p_chk);
          end if;
        end if;
      end;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FMOVE', fio_pid);
  end if;
end fmove;
--
-- @METAGS fdelete
function fdelete (filename_i in varchar2, p_chk boolean default true,
                  name_text  pls_integer default NULL ) return pls_integer is
    i pls_integer;
    t pls_integer;
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := translate(filename_i,get_str(def_text),get_str(t));
    else
      n := filename_i;
    end if;
    if fio_mkdir then
      i := fio.fremove(correct_path(n),p_chk);
      if i is null then
        fio_init;
        i := fio.fremove(correct_path(n),p_chk);
      end if;
    else
      declare
        attrs  varchar2(30);
        uowner varchar2(100);
        gowner varchar2(100);
        mdate  varchar2(30);
        fsize  varchar2(30);
      begin
        i := f_info(n,attrs,uowner,gowner,mdate,fsize,p_chk,def_text);
        if i=0 then
          if substr(attrs,1,1)='d' then
            i := -6512;
          else
            i := fio.fremove(correct_path(n),p_chk);
          end if;
        end if;
      end;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FDELETE', fio_pid);
  end if;
end fdelete;
--
-- @METAGS mkdir
function mkdir (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                name_text pls_integer default NULL) return pls_integer is
    i pls_integer;
    t pls_integer;
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := translate(name_i,get_str(def_text),get_str(t));
    else
      n := name_i;
    end if;
    if fio_mkdir then
      i := fio.mkdir(correct_path(n),mode_i,p_chk);
    else
      i := -6512;
    end if;
    if i is null then
      fio_init;
      if fio_mkdir then
        i := fio.mkdir(correct_path(n),mode_i,p_chk);
      else
        i := -6512;
      end if;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'MKDIR', fio_pid);
  end if;
end mkdir;
-----------------------------------------------------
-- @METAGS qsort
procedure qsort (buf in out nocopy varchar2, p_char varchar2 default null, p_mode boolean default true) is
begin
    fio.qsort(buf,nvl(ascii(p_char),10),p_mode);
end;
-- @METAGS get_env
function get_env (name in varchar2) return varchar2 is
    i pls_integer;
    s varchar2(2000);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    i := fio.get_env(name,s);
    if i is null then
      fio_init;
      i := fio.get_env(name,s);
    end if;
    return s;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'GETENV', fio_pid);
  end if;
end;
-- @METAGS put_env
function put_env (name in varchar2, value in varchar2) return pls_integer is
    i pls_integer;
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    i := fio.put_env(name,value);
    if i is null then
      fio_init;
      i := fio.put_env(name,value);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'PUTENV', fio_pid);
  end if;
end;
-----------------------------------------------------
-- @METAGS f_open
function f_open(filename  in varchar2,
                open_mode in varchar2,
                p_chk boolean default false,
                name_text pls_integer default NULL ) return pls_integer is
    i pls_integer;
    t pls_integer;
    r raw(10);
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := correct_path(translate(filename,get_str(def_text),get_str(t)));
    else
      n := correct_path(filename);
    end if;
    i := fio.fopen(n,lower(open_mode),r,p_chk);
    if i is null then
      fio_init;
      if def_text<>t then
        n := correct_path(translate(filename,get_str(def_text),get_str(t)));
      else
        n := correct_path(filename);
      end if;
      i := fio.fopen(n,lower(open_mode),r,p_chk);
    end if;
    if i>0 then
      ffio(i).name := n;
      ffio(i).stream := r;
      ffio(i).open_mode:= open_mode;
      ffio(i).lsize:= stdio_line_size;
      ffio(i).text := t;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_OPEN', fio_pid);
  end if;
end;
-- @METAGS f_dopen
function f_dopen(handle in pls_integer, open_mode in varchar2 ) return pls_integer is
    i pls_integer;
    r raw(10);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    i := fio.fdopen(handle,lower(open_mode),r);
    if i is null then
      fio_init;
      i := fio.fdopen(handle,lower(open_mode),r);
    end if;
    if i>0 then
      if not ffio.exists(i) then
        ffio(i).name := 'Opened from handle: '||handle;
      end if;
      ffio(i).stream := r;
      ffio(i).open_mode:= open_mode;
      ffio(i).lsize:= stdio_line_size;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_DOPEN', fio_pid);
  end if;
end;
-- @METAGS f_close
function f_close ( file IN OUT nocopy pls_integer  ) return pls_integer is
    i pls_integer;
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if ffio(file).stream is null then
        i := fio.hclose( file );
      else
        i := fio.fclose( file, ffio(file).stream );
      end if;
      if i=0 then
        ffio.delete(file);
        file := null;
      end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_CLOSE', fio_pid);
  end if;
end;
-- @METAGS f_closeall
procedure f_closeall(p_files boolean default null) is
    i    pls_integer;
    idx  pls_integer;
    file pls_integer;
    msg  varchar2(30000);
begin
  if fio_pid>0 then
    if nvl(p_files,true) then
      idx := ffio.first;
      while not idx is null loop
        file:= idx;
        idx := ffio.next(idx);
        if ffio(file).stream is null then
          i := fio.hclose( file );
        else
          i := fio.fclose( file, ffio(file).stream );
        end if;
        if i=0 then
          ffio.delete(file);
        else
          msg := msg||','||get_file_name(file,true);
        end if;
      end loop;
    end if;
    if nvl(not p_files,true) then
      idx  := fdir.first;
      while not idx is null loop
        file:= idx;
        idx := fdir.next(idx);
        i := fio.closedir( file, fdir(file).stream );
        if i=0 then
          fdir.delete(file);
        else
          msg := msg||','||get_file_name(file,false);
        end if;
      end loop;
    end if;
    if not msg is null then
        message.error( constant.EXEC_ERROR, 'FILEWRITE', substr(msg,2) );
    end if;
  end if;
end;
-- @METAGS f_flush
function f_flush ( file pls_integer  ) return pls_integer is
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if ffio(file).stream is null then
        return 0;
      end if;
      return fio.fflush( file, ffio(file).stream );
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_FLUSH', fio_pid);
  end if;
end;
-- @METAGS f_seek
function f_seek (file pls_integer, pos in out nocopy varchar2, off_i pls_integer, how_i pls_integer default 0) return pls_integer is
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if ffio(file).stream is null then
        return fio.hseek( file, off_i, how_i, pos );
      else
        return fio.fseek( file, ffio(file).stream, off_i, how_i, pos );
      end if;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_SEEK', fio_pid);
  end if;
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
  if fio_pid>0 then
    if ffio.exists(file) and ffio(file).stream is not null then
      return fio.ftruncate( file, ffio(file).stream, p_size );
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_TRUNCATE', fio_pid);
  end if;
end;
-- @METAGS f_tell
function f_tell (file pls_integer) return number is
  i pls_integer;
  p varchar2(30);
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if ffio(file).stream is null then
        i := fio.hseek( file, 0, 1, p );
      else
        i := fio.ftell( file, ffio(file).stream, p );
      end if;
      if i=0 then
        return to_number(p);
      end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_SEEK', fio_pid);
  end if;
end;
--
-- @METAGS f_read
function f_read (file pls_integer, bf_o in out nocopy raw, sz_i pls_integer) return pls_integer is
    i pls_integer;
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if ffio(file).stream is null then
        return fio.hread( file, bf_o, sz_i );
      else
        return fio.fread( file, ffio(file).stream, bf_o, sz_i );
      end if;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_READ', fio_pid);
  end if;
end;
-- @METAGS f_write
function f_write (file pls_integer, bf_i in raw, sz_i pls_integer default 0) return pls_integer is
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if ffio(file).stream is null then
        return fio.hwrite( file, bf_i, sz_i );
      else
        return fio.fwrite( file, ffio(file).stream, bf_i, sz_i );
      end if;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_WRITE', fio_pid);
  end if;
end;
-- @METAGS read_str
function read_str (file pls_integer, str in out nocopy varchar2,
                   in_text  pls_integer  default NULL,
                   out_text pls_integer  default NULL,
                   sz_i pls_integer default 0) return pls_integer is
    v_in    pls_integer;
    v_out   pls_integer;
    i   pls_integer;
    j   pls_integer;
    r   raw(32767);
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      if not ffio(file).stream is null then
        i := fio.fread( file, ffio(file).stream, r, sz_i );
      elsif sz_i>0 then
        i := fio.hread( file, r, sz_i );
      else
        message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
      end if;
      if i<0 then
        str := null;
      else
        str := utl_raw.cast_to_varchar2(r);
        v_in := nvl(in_text, def_text);
        v_out:= nvl(out_text,def_text);
        if v_in<>v_out then
          str := translate(str,get_str(v_in),get_str(v_out));
        end if;
        if nvl(sz_i,0)=0 then
          j:=length(str);
          if substr(str,j,1)=LF then
            j:=j-1;
            if j>0 and instr(def_cr_add,v_in)>0 and substr(str,j,1)=CR then
              j:=j-1;
            end if;
            if j>0 then
              str:=substr(str,1,j);
            else
              str:=null;
            end if;
          end if;
        end if;
      end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'READ_STR', fio_pid);
  end if;
end;
-- @METAGS write_str
function write_str (file pls_integer, str varchar2,
                    in_text  pls_integer  default NULL,
                    out_text pls_integer  default NULL,
                    p_nl boolean default true) return pls_integer is
    v_in    pls_integer;
    v_out   pls_integer;
    i   pls_integer;
    l   varchar2(32767);
begin
  if fio_pid>0 then
    if ffio.exists(file) then
      v_in := nvl(in_text, def_text);
      v_out:= nvl(out_text,def_text);
      if p_nl then
        i := length(str);
        if instr(def_cr_add,v_out)>0 and (i is null or substr(str,i,1)!=CR) then
          if v_in=v_out then
            l:=str||CR||LF;
          else
            l:=translate(str,get_str(v_in),get_str(v_out))||CR||LF;
          end if;
        elsif v_in=v_out then
          l:=str||LF;
        else
          l:=translate(str,get_str(v_in),get_str(v_out))||LF;
        end if;
      elsif v_in=v_out then
        l:=str;
      else
        l:=translate(str,get_str(v_in),get_str(v_out));
      end if;
      if ffio(file).stream is null then
        return fio.hwrite( file, utl_raw.cast_to_raw(l), 0 );
      else
        return fio.fwrite( file, ffio(file).stream, utl_raw.cast_to_raw(l), 0 );
      end if;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'WRITE_STR', fio_pid);
  end if;
end;
-- @METAGS get_file_name
function get_file_name ( file pls_integer, p_files boolean default true ) return varchar2 is
begin
  if file is null then return null; end if;
  if fio_pid>0 then
    if nvl(p_files,true) then
      if ffio.exists(file) then
        if ffio(file).text<>def_text then
          return translate(ffio(file).name,get_str(ffio(file).text),get_str(def_text));
        end if;
        return ffio(file).name;
      end if;
    end if;
    if nvl(not p_files,true) then
      if fdir.exists(file) then
        if fdir(file).text<>def_text then
          return translate(fdir(file).name,get_str(fdir(file).text),get_str(def_text));
        end if;
        return fdir(file).name;
      end if;
    end if;
  end if;
  return null;
end;
--
function f_copy ( oldname varchar2,
                  newname varchar2,
                  fsize   in out nocopy varchar2,
                  p_chk   boolean default false,
                  p_write boolean default true,
                  name_text pls_integer default NULL) return pls_integer is
    i pls_integer;
    t pls_integer;
    o varchar2(1024);
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      o := translate(oldname,get_str(def_text),get_str(t));
      n := translate(newname,get_str(def_text),get_str(t));
    else
      o := oldname;
      n := newname;
    end if;
    i := fio.fcopy(correct_path(o),correct_path(n),p_write,p_chk,fsize);
    if i is null then
      fio_init;
      i := fio.fcopy(correct_path(o),correct_path(n),p_write,p_chk,fsize);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FCOPY', fio_pid);
  end if;
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
    i pls_integer;
    t pls_integer;
    n varchar2(1024);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := translate(name,get_str(def_text),get_str(t));
    else
      n := name;
    end if;
    i := fio.finfo(correct_path(n),attrs,uowner,gowner,mdate,fsize,p_chk);
    if i is null then
      fio_init;
      i := fio.finfo(correct_path(n),attrs,uowner,gowner,mdate,fsize,p_chk);
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FINFO', fio_pid);
  end if;
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
    i pls_integer;
    t pls_integer;
    r raw(10);
    n varchar2(1024);
    m varchar2(100);
begin
  if fio_pid is null then
    fio_init;
  end if;
  if fio_pid>0 then
    t := nvl(name_text,nam_text);
    if def_text<>t then
      n := correct_path(translate(dirname,get_str(def_text),get_str(t)));
      m := translate(mask,get_str(def_text),get_str(t));
    else
      n := correct_path(dirname);
      m := mask;
    end if;
    i := fio.opendir(n,m,dir_flag,r,p_chk);
    if i is null then
      fio_init;
      if def_text<>t then
        n := correct_path(translate(dirname,get_str(def_text),get_str(t)));
      else
        n := correct_path(dirname);
      end if;
      i := fio.opendir(n,m,dir_flag,r,p_chk);
    end if;
    if i>0 then
      fdir(i).name := n||slash||nvl(m,'*');
      fdir(i).stream := r;
      fdir(i).lsize:= dir_flag;
      fdir(i).text := t;
    end if;
    return i;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'OPENDIR', fio_pid);
  end if;
end;
--
function  closedir(dir  in out nocopy pls_integer ) return pls_integer is
    i pls_integer;
begin
  if fio_pid>0 then
    if fdir.exists(dir) then
      i := fio.closedir( dir, fdir(dir).stream );
      if i=0 then
        fdir.delete(dir);
        dir := null;
      end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'CLOSEDIR', fio_pid);
  end if;
end;
--
function  resetdir(dir  pls_integer ) return pls_integer is
begin
  if fio_pid>0 then
    if fdir.exists(dir) then
      return fio.resetdir( dir, fdir(dir).stream );
    else
      message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
  else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'RESETDIR', fio_pid);
  end if;
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
    i pls_integer;
begin
    if fio_pid>0 then
      if fdir.exists(dir) then
        i := fio.readdir( dir, fdir(dir).stream,name,attrs,uowner,gowner,mdate,fsize);
        if i>0 and fdir(dir).text<>def_text then
          name := translate(name,get_str(fdir(dir).text),get_str(def_text));
        end if;
        return i;
      else
        message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
      end if;
    else
      message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'READDIR', fio_pid);
    end if;
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
    v_pipe  := upper(nvl(p_pipe,write_pipe_name));
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
    if p_expand and v_status = 1 then
        if pipes.exists(v_pipe) then
          len1 := pipes(v_pipe);
        else
          begin
            select pipe_size into len1 from v$db_pipes where name=v_pipe and rownum<=1;
          exception when no_data_found then
            len1 := v_size;
          end;
          pipes(v_pipe) := greatest(len1,v_size);
        end if;
        len1:= (len1+nvl(len,0))/8192;
        len1:= greatest((len1+4)*8192,v_size);
        if v_size<len1 and len1<=1048576  then
          pipes(v_pipe) := len1;
          if pos0>1 then
            v_status := put_pipe(substr(p_text,pos0),v_pipe,v_time,len1,p_nl,false);
          else
            v_status := put_pipe(p_text,v_pipe,v_time,len1,p_nl,false);
          end if;
        end if;
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
    pipes(v_read) := stdio_pipe_size;
    pipes(v_write):= stdio_pipe_size;
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
begin
    return rtl.get_setting(p_name);
end;
procedure init_setting(p_name varchar2 default null) is
begin
    rtl.clear_setting(p_name);
end;
function setting(p_name varchar2) return varchar2 is
begin
    return rtl.setting(p_name);
end;
function num_set(p_name varchar2) return number is
begin
    return rtl.num_set(p_name);
end;
procedure put_setting(p_name varchar2, p_value   varchar2,
                      p_description varchar2 default null) is
begin
    rtl.put_setting(p_name,p_value,p_description);
end;
-----------------------------------------------------
-- @METAGS set_def_text
procedure set_def_text( p_txt      varchar2,
                        p_slash    varchar2 default null,
                        p_add_cr   varchar2 default null,
                        p_name_txt varchar2 default null) is
    v_slash varchar2(1) := substr(p_slash,1,1);
    v_txt   varchar2(1) := substr(p_txt,1,1);
    v_cr    varchar2(100) := substr(p_add_cr,1,100);
begin
    if strdos is null then
      strdos
        :=chr(128)||chr(129)||chr(130)||chr(131)||chr(132)||chr(133)||chr(134)||chr(135)||chr(136)||chr(137)||chr(138)||chr(139)||chr(140)||chr(141)||chr(142)||chr(143)
        ||chr(144)||chr(145)||chr(146)||chr(147)||chr(148)||chr(149)||chr(150)||chr(151)||chr(152)||chr(153)||chr(154)||chr(155)||chr(156)||chr(157)||chr(158)||chr(159)
        ||chr(160)||chr(161)||chr(162)||chr(163)||chr(164)||chr(165)||chr(166)||chr(167)||chr(168)||chr(169)||chr(170)||chr(171)||chr(172)||chr(173)||chr(174)||chr(175)
        ||chr(224)||chr(225)||chr(226)||chr(227)||chr(228)||chr(229)||chr(230)||chr(231)||chr(232)||chr(233)||chr(234)||chr(235)||chr(236)||chr(237)||chr(238)||chr(239)
        ||chr(240)||chr(241)||chr(252);
      strunx
        :=chr(176)||chr(177)||chr(178)||chr(179)||chr(180)||chr(181)||chr(182)||chr(183)||chr(184)||chr(185)||chr(186)||chr(187)||chr(188)||chr(189)||chr(190)||chr(191)
        ||chr(192)||chr(193)||chr(194)||chr(195)||chr(196)||chr(197)||chr(198)||chr(199)||chr(200)||chr(201)||chr(202)||chr(203)||chr(204)||chr(205)||chr(206)||chr(207)
        ||chr(208)||chr(209)||chr(210)||chr(211)||chr(212)||chr(213)||chr(214)||chr(215)||chr(216)||chr(217)||chr(218)||chr(219)||chr(220)||chr(221)||chr(222)||chr(223)
        ||chr(224)||chr(225)||chr(226)||chr(227)||chr(228)||chr(229)||chr(230)||chr(231)||chr(232)||chr(233)||chr(234)||chr(235)||chr(236)||chr(237)||chr(238)||chr(239)
        ||chr(161)||chr(241)||chr(240);
      strwin
        :=chr(192)||chr(193)||chr(194)||chr(195)||chr(196)||chr(197)||chr(198)||chr(199)||chr(200)||chr(201)||chr(202)||chr(203)||chr(204)||chr(205)||chr(206)||chr(207)
        ||chr(208)||chr(209)||chr(210)||chr(211)||chr(212)||chr(213)||chr(214)||chr(215)||chr(216)||chr(217)||chr(218)||chr(219)||chr(220)||chr(221)||chr(222)||chr(223)
        ||chr(224)||chr(225)||chr(226)||chr(227)||chr(228)||chr(229)||chr(230)||chr(231)||chr(232)||chr(233)||chr(234)||chr(235)||chr(236)||chr(237)||chr(238)||chr(239)
        ||chr(240)||chr(241)||chr(242)||chr(243)||chr(244)||chr(245)||chr(246)||chr(247)||chr(248)||chr(249)||chr(250)||chr(251)||chr(252)||chr(253)||chr(254)||chr(255)
        ||chr(168)||chr(184)||chr(185);
      strkoi
        :=chr(225)||chr(226)||chr(247)||chr(231)||chr(228)||chr(229)||chr(246)||chr(250)||chr(233)||chr(234)||chr(235)||chr(236)||chr(237)||chr(238)||chr(239)||chr(240)
        ||chr(242)||chr(243)||chr(244)||chr(245)||chr(230)||chr(232)||chr(227)||chr(254)||chr(251)||chr(253)||chr(255)||chr(249)||chr(248)||chr(252)||chr(224)||chr(241)
        ||chr(193)||chr(194)||chr(215)||chr(199)||chr(196)||chr(197)||chr(214)||chr(218)||chr(201)||chr(202)||chr(203)||chr(204)||chr(205)||chr(206)||chr(207)||chr(208)
        ||chr(210)||chr(211)||chr(212)||chr(213)||chr(198)||chr(200)||chr(195)||chr(222)||chr(219)||chr(221)||chr(223)||chr(217)||chr(216)||chr(220)||chr(192)||chr(209)
        ||chr(179)||chr(163)||chr(191);
    end if;
    if v_txt is null then
        v_txt := substr(rtl.setting('DEF_TEXT'),1,1);
    end if;
    v_txt := upper(v_txt);
    if v_txt='W' then
        def_text := WINTEXT;
    elsif v_txt='D' then
        def_text := DOSTEXT;
    elsif v_txt='K' then
        def_text := KOITEXT;
    else
        def_text := UNXTEXT;
    end if;
    v_txt := substr(p_name_txt,1,1);
    if v_txt is null then
        v_txt := substr(rtl.setting('STDIO_FILE_NAME_TEXT'),1,1);
    end if;
    v_txt := upper(v_txt);
    if v_txt='W' then
        nam_text := WINTEXT;
    elsif v_txt='D' then
        nam_text := DOSTEXT;
    elsif v_txt='K' then
        nam_text := KOITEXT;
    elsif v_txt='U' then
        nam_text := UNXTEXT;
    else
        nam_text := def_text;
    end if;
    if v_slash is null then
        v_slash := substr(rtl.setting('DEF_SLASH'),1,1);
    end if;
    if v_slash='\' then
        slash := '\';
    else
        slash := '/';
    end if;
    slash2 := slash||slash;
    selfdir:= slash||'.'||slash;
    if v_cr is null then
        v_cr := substr(rtl.setting('DEF_CR_ADD'),1,100);
    end if;
    v_cr := nvl(upper(v_cr),'DK');
    def_cr_add := null;
    if instr(v_cr,'D')>0 then
        def_cr_add := DOSTEXT;
    end if;
    if instr(v_cr,'U')>0 then
        def_cr_add := def_cr_add||UNXTEXT;
    end if;
    if instr(v_cr,'W')>0 then
        def_cr_add := def_cr_add||WINTEXT;
    end if;
    if instr(v_cr,'K')>0 then
        def_cr_add := def_cr_add||KOITEXT;
    end if;
    init_text := false;
end set_def_text;
-----------------------------------------------------
-- @METAGS set_sizes
procedure set_sizes( line_size   IN  pls_integer default null,
                     buffer_size IN  pls_integer default null ) is
    v_line  pls_integer := line_size;
    v_buf   pls_integer := buffer_size;
begin
    if v_line is null then
        v_line:= num_set('STDIO_LINE_SIZE');
    end if;
    if v_buf is null then
        v_buf := num_set('STDIO_BUFFER_SIZE');
    end if;
    if v_line<=0 then
        v_line:= STDIOLINESIZE;
    end if;
    if v_buf<=0 then
        v_buf := STDIOBUFFERSIZE;
    end if;
    stdio_line_size:= v_line;
    stdio_buf_size := v_buf;
    last_buf_size:= nvl(last_buf_size,0);
    max_buf_size := nvl(max_buf_size,0);
    init_sizes := false;
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
    line_size := stdio_line_size;
    buffer_size := stdio_buf_size;
end;
-----------------------------------------------------
procedure Init is
begin
    fio_close;
    init_text  := true;
    init_pipes := true;
    init_sizes := true;
    buf_enable := true;
    cur_profile:= null;
end;
-----------------------------------------------------
end stdio;
/
show errors package body stdio

