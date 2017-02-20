prompt vfs_io body
create or replace
package body vfs_io is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/Core/Utils/EXT/vfs_io2.sql $
 *	$Author: Alexey $
 *	$Revision: 15082 $
 *	$Date:: 2012-03-06 17:34:34 #$
 */
-- Text conversion strings
-- win 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ¨¸¹'
strdos varchar2(67);
strunx varchar2(67);
strwin varchar2(67);
strkoi varchar2(67);
--
    LF      constant varchar2(1) := chr(10);
    CR      constant varchar2(2) := chr(13);
    ENOENT  constant pls_integer := -2;
    EIO     constant pls_integer := -5;
    EBADF   constant pls_integer := -9;
    EACCES  constant pls_integer := -13;
    EFAULT  constant pls_integer := -14;
    EBUSY   constant pls_integer := -16;
    EINVAL  constant pls_integer := -22;
    ETXTBSY constant pls_integer := -26;
    EPIPE   constant pls_integer := -32;
--  loc types
    LT_FIO     constant pls_integer := 0;
    LT_VFS     constant pls_integer := 1;
    LT_DEFAULT          pls_integer := LT_FIO;
--  prefixes
    PRF_FIO constant varchar2(4) := 'FIO:';
    PRF_VFS constant varchar2(4) := 'VFS:';
--
type file_info_t is record (
    name      varchar2(1024),
    open_mode varchar2(10),
    stream    raw(10),
    lsize     pls_integer,
    text      pls_integer,
    loc_type  pls_integer,
    handle    pls_integer
);
type file_tbl_t is table of file_info_t index by binary_integer;
--
type alias_t is record (
    search_str  varchar2(4000),
    replace_str varchar2(4000),
    search_length pls_integer
);
type alias_tbl_t is table of alias_t index by binary_integer;
--
falias alias_tbl_t;
ffio  file_tbl_t;
fdir  file_tbl_t;
--
schema_owner     varchar2(30);
cur_profile      varchar2(30);
stdio_line_size  pls_integer;
init_size   boolean := true;
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
--
INITED boolean := false;
--
vfs_root_dir varchar2(4000);
vfs_home_dir varchar2(4000);
vfs_replace_dir varchar2(4000);
vfs_replace_length pls_integer;
vfs_slash varchar2(1) := '/';
vfs_slash2 varchar2(2) := '//';
vfs_selfdir varchar2(3) := '/./';
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
--------------------------------------------------------
function loc_type(location in varchar2) return pls_integer as
  prf varchar2(4) := upper(substr(location,1,4));
begin
  if    prf = PRF_FIO then
    return LT_FIO;
  elsif prf = PRF_VFS then
    return LT_VFS;
  else
    return LT_DEFAULT;
  end if;
end loc_type;
----------------------------------------------------------
function get_parent_path(apath in varchar2) return varchar2 as
  p pls_integer;
begin
  p := instr(apath,vfs_slash,-1);
  if p > 0 then
    return substr(apath,1,p - 1);
  else
    return null;
  end if;
end get_parent_path;
----------------------------------------------------------
function get_path(alocation in varchar2) return varchar2 as
  v varchar2(4000);
  aloc varchar2(4000) := alocation;
  l pls_integer;
begin
  l := length(aloc);
  if substr(aloc,l - 1,2) = vfs_slash || '.' then aloc := substr(aloc,1,l - 2); end if;
  if aloc is null then
    return vfs_root_dir;
  end if;
  if    substr(aloc,1,2) = '..' then
    v := get_parent_path(vfs_root_dir);
    if v is null then
      return substr(aloc,3);
    else
      return v || substr(aloc,3);
    end if;
  elsif substr(aloc,1,1) = '.' then
    if vfs_root_dir = vfs_slash then
      return substr(aloc,3);
    else
      return vfs_root_dir || substr(aloc,2);
    end if;
  elsif substr(aloc,1,1) = vfs_slash then
    return aloc;
  elsif vfs_root_dir = vfs_slash then
    return vfs_root_dir || aloc;
  else
    return vfs_root_dir || vfs_slash || aloc;
  end if;
end get_path;
----------------------------------------------------------
function correct_path(apath in varchar2, aloc_type out nocopy pls_integer, name_text in pls_integer) return varchar2 as
  i pls_integer;
  result varchar2(4000) := apath;
  prf varchar2(4);
begin
  check_open;
  i := nvl(name_text,nam_text);
  if i<>def_text then
    result := translate(result,get_str(def_text),get_str(i));
  end if;
  i := falias.first;
  while not i is null loop
    if falias(i).search_length > 0 and result like falias(i).search_str then
      result := falias(i).replace_str || substr(result,falias(i).search_length);
      exit;
    end if;
    i := falias.next(i);
  end loop;
  prf := upper(substr(result,1,4));
  aloc_type := loc_type(prf);
  if prf in (PRF_FIO,PRF_VFS) then
    result := substr(result,5);
  end if;
  if aloc_type = LT_FIO then
    if l_srch > 0 and result like fio_srch then
      result := fio_home || substr(result,l_srch);
    end if;
    result := replace(translate(result,'/\',slash2),selfdir,slash);
  else
    if vfs_replace_length > 0 and result like vfs_replace_dir then
      result := vfs_home_dir || substr(result,vfs_replace_length);
    end if;
    result := replace(translate(result,'/\',vfs_slash2),vfs_selfdir,vfs_slash);
  end if;
  return result;
end correct_path;
----------------------------------------------------------
procedure close_fio_files as
  i pls_integer;
  tmp pls_integer;
begin
  i := ffio.first;
  loop
   exit when i is null;
   if ffio(i).loc_type = LT_FIO then
    tmp := fclose(i);
   end if;
   i := ffio.next(i);
  end loop;
end close_fio_files;
----------------------------------------------------------
procedure close_fio_dirs as
  i pls_integer;
  tmp pls_integer;
begin
  i := fdir.first;
  loop
   exit when i is null;
   if fdir(i).loc_type = LT_FIO then
    tmp := closedir(i);
   end if;
   i := fdir.next(i);
  end loop;
end close_fio_dirs;
----------------------------------------------------------
-- @METAGS open
function open ( location  in varchar2,
                filename  in varchar2,
                open_mode in varchar2,
                raising   IN boolean default FALSE,
                line_size IN pls_integer default NULL,
                name_text IN pls_integer default NULL
              ) return pls_integer is
  idx pls_integer;
  lt  pls_integer;
  loc varchar2(4000);
begin
  if init_text then set_def_text(null); end if;
  idx := f_open(location || slash || filename, open_mode, false, name_text );
  if idx>0 then
   if line_size>0 then
    ffio(idx).lsize := line_size;
   end if;
   return idx;
  else
   loc := correct_path(location,lt,name_text);
   if lt = LT_FIO then
    if idx=ENOENT then
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
   else
    begin
     idx := vfs_mgr.process_error(idx,raising);
    exception
     when vfs_mgr.E_INVALID_PATH then raise INVALID_PATH;
     when vfs_mgr.E_INVALID_MODE then raise INVALID_MODE;
     when others then if raising then raise INVALID_OPERATION; else raise; end if;
    end;
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
  idx := f_close(file);
  if    idx = 0 then
   return;
  elsif ffio(file).loc_type = LT_FIO then
   if idx = EINVAL then
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
  else
   begin
    idx := vfs_mgr.process_error(idx,raising);
   exception
    when vfs_mgr.E_INVALID_HANDLE then raise INVALID_FILEHANDLE;
    when others then if raising then raise WRITE_ERROR; else raise; end if;
   end;
  end if;
end close;
--
-- @METAGS fput
procedure fput ( file    IN pls_integer,
                 buffer  IN varchar2,
                 raising IN boolean default FALSE,
                 p_flash IN boolean default FALSE) is
  idx pls_integer := 0;
begin
  if not buffer is null then
   idx := write_str(file, buffer, null,null, false );
  end if;
  if p_flash and idx>=0 then
   idx := f_flush( file );
  end if;
  if idx>=0 then
   return;
  elsif not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  elsif ffio(file).loc_type = LT_FIO then
   if idx=EINVAL then
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
  else
   begin
    idx := vfs_mgr.process_error(idx,raising);
   exception
    when vfs_mgr.E_INVALID_HANDLE then raise INVALID_FILEHANDLE;
    when others then if raising then raise WRITE_ERROR; else raise; end if;
   end;
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
  elsif ffio(file).loc_type = LT_FIO then
   if idx=EINVAL then
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
  else
   begin
    idx := vfs_mgr.process_error(idx,raising);
   exception
    when vfs_mgr.E_INVALID_HANDLE then raise INVALID_FILEHANDLE;
    when others then if raising then raise WRITE_ERROR; else raise; end if;
   end;
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
  tmp pls_integer;
begin
  if ffio(file).loc_type = LT_FIO then
   fput(file,null,raising,true);
  else
   tmp := vfs_mgr.process_error(f_flush(file),raising);
  end if;
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
  idx pls_integer;
begin
  idx := read_str(file,buf,in_text,out_text);
  if idx=0 then
   buffer := null;
   return false;
  elsif idx>0 then
   l := nvl(l_size,ffio(file).lsize);
   if length(buf)>l then
    v_in := fseek(file,pos,-idx,1);
    if raising then
     raise stdio.INVALID_LINESIZE;
    else
     message.error( constant.EXEC_ERROR, 'LINESIZE', get_file_name(file,true), l );
    end if;
   end if;
   buffer := buf;
   return true;
  elsif ffio(file).loc_type = LT_FIO then
   if idx=EINVAL then
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
  else
   begin
    idx := vfs_mgr.process_error(idx,raising);
   exception
    when vfs_mgr.E_INVALID_HANDLE then raise INVALID_FILEHANDLE;
    when others then if raising then raise READ_ERROR; else raise; end if;
   end;
  end if;
end;
--
-- @METAGS is_open
function is_open ( file  IN  pls_integer ) return boolean is
begin
    return ffio.exists(file);
end is_open;
----------------------------------------------------------
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
    if init_size then set_size; end if;
    if init_text then set_def_text(null); end if;
    fio_mkdir := false;
    close_fio_files;
    close_fio_dirs;
    not_def:= rtl.get_user_info(u);
    user_id:= u.id;
    v_user := u.ora_user;
    cur_profile := stdio.get_profile(v_user);
    v_prof := cur_profile;
    dbms_application_info.read_module( ftmp, flog );
    if schema_owner is null then
      select username  into  schema_owner
        from all_users where user_id=userenv('SCHEMAID');
    end if;
    if flog='SYSTEM_JOBS for '||schema_owner then
        if u.id>0 then
            user_id:= '+'||user_id;
            v_user := nvl(substr(ftmp,1,instr(ftmp,'.')-1),v_user);
            v_prof := stdio.get_profile(v_user);
        end if;
        v_prof := nvl(stdio.get_resource(v_prof,'JOB_PROFILE'),v_prof);
    end if;
    not_def:= v_prof<>v_def;
    flog := stdio.get_resource(v_prof,'FIO_DEBUG_LEVEL');
    froot:= stdio.get_resource(v_prof,'FIO_ROOT_DIR');
    fbase:= stdio.get_resource(v_prof,'FIO_BASE_DIR');
    if substr(upper(stdio.get_resource(v_prof,'FIO_MAKE_DIR')),1,1)='Y' then
        fio_mkdir := true;
    end if;
    if not_def then
        if flog is null then
            flog := stdio.get_resource(v_def,'FIO_DEBUG_LEVEL');
        end if;
        if froot is null then
            froot:= stdio.get_resource(v_def,'FIO_ROOT_DIR');
        end if;
        ftmp := stdio.get_resource(v_def,'FIO_BASE_DIR');
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
    fio_home := stdio.get_resource(v_def, 'FIO_HOME_DIR');
    fio_srch := stdio.get_resource(v_def, 'FIO_REPLACE_DIR')||'%';
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
    flog := ';'||nvl(stdio.get_resource(v_def,'FIO_TEMP_DIR'),'/tmp');
    if instr(fbase,flog)=0 then
        fbase:= fbase||flog;
    end if;
    flog := stdio.get_resource(v_def,'FIO_LOG_FILE');
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
    ftmp := ltrim(rtrim(stdio.setting('LOCK_START')));
    if ftmp is null or upper(ftmp) like 'LIB%' then
      fio_lock := null;
    else
      fio_lock := ftmp||' '||inst_info.owner||'.'||nvl(stdio.setting('LOCK_PROFILE'),inst_info.owner)
         ||' '||nvl(stdio.setting('LOCK_PATH'),'./lock.ini')||' % % % %';
      fexec := fexec||';'||fio_lock;
    end if;
    fio_pid := fio.open(flog,froot,fbase,substr(fexec,2),schema_owner||'.'||v_user||'.'||user_id,fdbg);
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
            close_fio_files;
            close_fio_dirs;
        exception
            when rtl.INVALID_PACKAGE_STATE then raise;
            when others then null;
        end;
        fio.close;
    end if;
    fio_pid := NULL;
end;
--
-- @METAGS fio_open
procedure fio_open is
begin
  if nvl(fio_pid,0)<=0 then fio_init;  end if;
end;
----------------------------------------------------------
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
  loc varchar2(4000);
  lt pls_integer;
begin
  loc := correct_path(location,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    t := nvl(name_text,nam_text);
    i := fio.flist(loc,l,p_chk,dir_flag);
    if i is null then
     fio_init;
     i := fio.flist(correct_path(location,lt,name_text),l,p_chk,dir_flag);
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
  else
   return flist(location,dir_flag,p_sort,name_text);
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
   if s is null then
    i := vfs_mgr.process_error(i);
   end if;
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
   if s is null then
    i := vfs_mgr.process_error(i);
   end if;
   message.error( constant.EXEC_ERROR, 'EXTERNAL_ERROR', 'DELETE_FILE', s );
  end if;
end delete_file;
----------------------------------------------------------
function mode2vfs_access_mask(mode_i in pls_integer) return pls_integer as
  res pls_integer;
begin
  if mode_i = 0 then
   return vfs_admin.ACCESS_PARENT;
  else
   res := 0;
   if bitand(mode_i,2) <> 0 then res := vfs_admin.ACCESS_WRITE; end if;
   if bitand(mode_i,5) <> 0 then res := res + vfs_admin.ACCESS_READ; end if;
   return res;
  end if;
end mode2vfs_access_mask;
----------------------------------------------------------
function flag2open_mode(aflag in pls_integer) return char as
  result varchar(2) := null;
begin
  if bitand(aflag,18/*00010010*/) <> 0 then result := 'w'; end if;
  if bitand(aflag,36/*00100100*/) <> 0 then result := 'r' || result; end if;
  return result;
end flag2open_mode;
-----------------------------------------------------
-- @METAGS fopen
function fopen (name_i in varchar2, flag_i in pls_integer, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
  i pls_integer;
  res pls_integer;
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(name_i,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.hopen(loc,flag_i,p_chk);
    if i is null then
     fio_init;
     loc := correct_path(name_i,lt,name_text);
     i := fio.hopen(loc,flag_i,p_chk);
    end if;
    if i>0 then
     res := ffio.count + 1;
     ffio(res).name := loc;
     ffio(res).lsize:= flag_i;
     ffio(res).loc_type := LT_FIO;
     ffio(res).text := nvl(name_text,nam_text);
     ffio(res).handle := i;
     return res;
    else
     return i;
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FOPEN', fio_pid);
   end if;
  else
   return f_open(name_i,flag2open_mode(flag_i),p_chk,name_text);
  end if;
end fopen;
--
-- @METAGS fcreate
function fcreate (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                  name_text pls_integer default NULL ) return pls_integer is
  res pls_integer;
  fid integer;
  i pls_integer;
  loc varchar2(4000);
  lt integer;
begin
  loc := correct_path(name_i,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.hcreate(loc,mode_i,p_chk);
    if i is null then
     fio_init;
     loc := correct_path(name_i,lt,name_text);
     i := fio.hcreate(loc,mode_i,p_chk);
    end if;
    if i>0 then
     res := ffio.count + 1;
     ffio(res).name := loc;
     ffio(res).lsize:= mode_i;
     ffio(res).loc_type := LT_FIO;
     ffio(res).text := nvl(name_text,nam_text);
     ffio(res).handle := i;
     return res;
    else
     return i;
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FCREATE', fio_pid);
   end if;
  else
   res := f_open(name_i,'w',p_chk,name_text);
   if res < vfs_mgr.ERR_SUCCESS then
    return res;
   end if;
   fid := vfs_mgr.get_file_id$(ffio(res).handle);
   if fid > vfs_mgr.ERR_SUCCESS then
    fid := vfs_admin.set_others_access(fid,mode2vfs_access_mask(mode_i));
   end if;
   return res;
  end if;
end fcreate;
--
-- @METAGS fclose
function fclose (fh_i in pls_integer) return pls_integer is
  tmp pls_integer;
  i pls_integer;
begin
  if not ffio.exists(fh_i) then
   message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(fh_i).loc_type = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    if ffio.exists(fh_i) and not ffio(fh_i).stream is null then
     i := fio.fclose(ffio(fh_i).handle, ffio(fh_i).stream );
    else
     i := fio.hclose(ffio(fh_i).handle);
     if i is null then
      fio_init;
      i := fio.hclose(ffio(fh_i).handle);
     end if;
    end if;
    if i=0 then
     ffio.delete(fh_i);
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FCLOSE', fio_pid);
   end if;
  else
   tmp := fh_i;
   return f_close(tmp);
  end if;
end fclose;
-- @METAGS fseek
function fseek (fh_i in pls_integer, pos in out nocopy varchar2, off_i in pls_integer, how_i in pls_integer) return pls_integer is
  i pls_integer;
begin
  if not ffio.exists(fh_i) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(fh_i).loc_type = LT_FIO then
    if fio_pid is null then
      fio_init;
    end if;
    if fio_pid>0 then
      i := fio.hseek(ffio(fh_i).handle,off_i,how_i,pos);
      if i is null then
        fio_init;
        i := fio.hseek(ffio(fh_i).handle,off_i,how_i,pos);
        end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FSEEK', fio_pid);
    end if;
  else
    return f_seek(fh_i,pos,off_i,how_i);
  end if;
end fseek;
--
-- @METAGS fread
function fread (fh_i in pls_integer, sz_i in pls_integer, bf_o in out nocopy raw) return pls_integer is
  i pls_integer;
begin
  if not ffio.exists(fh_i) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(fh_i).loc_type = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.hread(ffio(fh_i).handle,bf_o,sz_i);
    if i is null then
     fio_init;
     i := fio.hread(ffio(fh_i).handle,bf_o,sz_i);
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FREAD', fio_pid);
   end if;
  else
   return f_read(fh_i,bf_o,sz_i);
  end if;
end fread;
--
-- @METAGS fwrite
function fwrite (fh_i in pls_integer, bf_i in raw, sz_i in pls_integer default 0) return pls_integer is
  i pls_integer;
begin
  if not ffio.exists(fh_i) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(fh_i).loc_type = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.hwrite(ffio(fh_i).handle,bf_i,sz_i);
    if i is null then
     fio_init;
     i := fio.hwrite(ffio(fh_i).handle,bf_i,sz_i);
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FWRITE', fio_pid);
   end if;
  else
   return f_write(fh_i,bf_i,sz_i);
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
        return f_copy(a0_i,a1_i,str);
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
  if error_number_i<vfs_mgr.ERR_VFS_BASE then
    err_str := vfs_mgr.error_message(error_number_i);
  end if;
  if err_str is null then
    fio.err_msg(error_number_i,err_str);
  end if;
  if err_str is null and error_number_i>=vfs_mgr.ERR_VFS_BASE then
    return vfs_mgr.error_message(error_number_i);
  end if;
  return err_str;
end error_message;
--
-- @METAGS flist
function flist (dirname_i in varchar2, dirflag_i in pls_integer, p_sort boolean default null,
                name_text pls_integer default NULL) return varchar2 is
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(dirname_i,lt,name_text);
  if lt = LT_FIO then
    return file_list(dirname_i,dirflag_i,p_sort,true,name_text);
  else
    declare
      result varchar2(32767);
      tmp pls_integer;
    begin
      tmp := vfs_mgr.process_error(flist(dirname_i,dirflag_i,result,p_sort,true,name_text));
      return result;
    end;
  end if;
end flist;
--
function flist (dirname_i in varchar2, dirflag_i in pls_integer, filelist_o in out nocopy varchar2, p_sort boolean default null, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
  i pls_integer;
  f_path varchar2(4000);
  f_mask varchar2(4000);
  nm varchar2(4000);
  p  pls_integer;
  result pls_integer;
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(dirname_i,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    p := nvl(name_text,nam_text);
    i := fio.flist(loc,filelist_o,p_chk,dirflag_i);
    if i is null then
     fio_init;
     i := fio.flist(correct_path(dirname_i,lt,name_text),filelist_o,p_chk,dirflag_i);
    end if;
    if i>0 and p<>def_text then
     filelist_o := translate(filelist_o,get_str(p),get_str(def_text));
    end if;
    if i>1 and not p_sort is null then
     fio.qsort(filelist_o,10,p_sort);
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FLIST', fio_pid);
   end if;
  else
   nm := loc;
   p := instr(nm,vfs_slash || vfs_slash || vfs_slash,-1);
   if p > 0 then
    f_path := rtrim(substr(nm,1,p - 1));
    f_mask := substr(nm,p + 3);
   else
    f_path := nm;
    f_mask := null;
   end if;
   result := vfs_mgr.get_id_by_name$(get_path(f_path));
   if result >= 0 or result is null then
    result := vfs_mgr.get_file_list(
     filelist_o,
     result,
     f_mask,
     dirflag_i,
     p_sort
     );
    p := nvl(name_text,nam_text);
    if result>0 and p<>def_text then
     filelist_o := translate(filelist_o,get_str(p),get_str(def_text));
    end if;
   else
    filelist_o := null;
   end if;
   return result;
  end if;
end flist;
--
-- @METAGS fmove
function fmove (oldname_i in varchar2, newname_i in varchar2, p_chk boolean default true,
                name_text pls_integer default NULL ) return pls_integer is
  i pls_integer;
  p pls_integer;
  f_old_name varchar2(4000);
  f_new_path varchar2(4000);
  f_new_name varchar2(4000);
  onm varchar2(4000);
  nnm varchar2(4000);
  oid integer;
  nid integer;
  lt_old pls_integer;
  lt_new pls_integer;
  loco varchar2(4000);
  locn varchar2(4000);
begin
  loco := correct_path(oldname_i,lt_old,name_text);
  locn := correct_path(newname_i,lt_new,name_text);
  if    lt_old = LT_FIO and lt_new = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    if fio_mkdir then
     i := fio.frename(loco,locn,p_chk);
     if i is null then
      fio_init;
      i := fio.frename(correct_path(oldname_i,lt_old,name_text),correct_path(newname_i,lt_new,name_text),p_chk);
     end if;
    else
     declare
      attrs  varchar2(30);
      uowner varchar2(100);
      gowner varchar2(100);
      mdate  varchar2(30);
      fsize  varchar2(30);
     begin
      i := f_info(oldname_i,attrs,uowner,gowner,mdate,fsize,p_chk,name_text);
      if i=0 then
       if substr(attrs,1,1)='d' then
        i := -6512;
       else
        i := fio.frename(loco,locn,p_chk);
       end if;
      end if;
     end;
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FMOVE', fio_pid);
   end if;
  elsif lt_old = LT_VFS and lt_new = LT_VFS then
   onm := loco;
   nnm := locn;
   p := instr(nnm,vfs_slash,-1);
   if p > 0 then
    f_new_path := get_path(substr(nnm,1,p - 1));
    f_new_name := substr(nnm,p + 1);
   else
    f_new_path := get_path(null);
    f_new_name := nnm;
   end if;
   f_old_name := get_path(onm);
   oid := vfs_mgr.get_id_by_name$(f_old_name);
   if oid < vfs_mgr.ERR_SUCCESS then
    return oid;
   end if;
   nid := vfs_mgr.get_id_by_name$(f_new_path);
   if nid < vfs_mgr.ERR_SUCCESS then
    return nid;
   end if;
   return vfs_mgr.move$(oid,nid,f_new_name);
  else
   i := f_copy(oldname_i,newname_i,onm,p_chk,false,name_text);
   if i < 0 then
    return i;
   end if;
   i := fdelete(oldname_i,p_chk,name_text);
   return 0;
  end if;
end fmove;
--
-- @METAGS fdelete
function fdelete (filename_i in varchar2, p_chk boolean default true,
                  name_text  pls_integer default NULL ) return pls_integer is
  i pls_integer;
  p integer;
  fn varchar2(4000);
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(filename_i,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    if fio_mkdir then
     i := fio.fremove(loc,p_chk);
     if i is null then
      fio_init;
      i := fio.fremove(correct_path(filename_i,lt,name_text),p_chk);
     end if;
    else
     declare
      attrs  varchar2(30);
      uowner varchar2(100);
      gowner varchar2(100);
      mdate  varchar2(30);
      fsize  pls_integer;
     begin
      i := f_info(filename_i,attrs,uowner,gowner,mdate,fsize,p_chk,name_text);
      if i=0 then
       if substr(attrs,1,1)='d' then
        i := -6512;
       else
        i := fio.fremove(loc,p_chk);
       end if;
      end if;
     end;
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FDELETE', fio_pid);
   end if;
  else
   fn := get_path(loc);
   p := vfs_mgr.get_id_by_name$(fn);
   if p < vfs_mgr.ERR_SUCCESS then
    return p;
   end if;
   return vfs_mgr.remove$(p);
  end if;
end fdelete;
--
-- @METAGS mkdir
function mkdir (name_i in varchar2, mode_i in pls_integer, p_chk boolean default true,
                name_text pls_integer default NULL) return pls_integer is
  f_path varchar2(4000);
  f_name varchar2(4000);
  p integer;
  nm varchar2(4000);
  i pls_integer;
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(name_i,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    if fio_mkdir then
     i := fio.mkdir(loc,mode_i,p_chk);
    else
     i := -6512;
    end if;
    if i is null then
     fio_init;
     if fio_mkdir then
      i := fio.mkdir(correct_path(name_i,lt,name_text),mode_i,p_chk);
     else
      i := -6512;
     end if;
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'MKDIR', fio_pid);
   end if;
  else
   nm := loc;
   p := instr(nm,vfs_slash,-1);
   if p > 0 then
    f_path := substr(nm,1,p - 1);
    f_name := substr(nm,p + 1);
   else
    f_path := null;
    f_name := nm;
   end if;
   f_path := get_path(f_path);
   p := vfs_mgr.get_id_by_name$(f_path);
   if p < vfs_mgr.ERR_SUCCESS then return p; end if;
   return vfs_mgr.create_folder$(aname=>f_name,aparent_id=>p,aothers_access_mask=>mode2vfs_access_mask(mode_i));
  end if;
end mkdir;
---------------------------------------------------------
-- @METAGS get_env
function get_env (name in varchar2) return varchar2 is
  i pls_integer;
  s varchar2(2000);
  n varchar2(200);
  p varchar2(4);
begin
  check_open;
  n := name;
  p := upper(substr(n,1,4));
  if loc_type(p) = LT_FIO then
   if p=PRF_FIO then
    n := substr(n,5);
   end if;
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.get_env(n,s);
    if i is null then
     fio_init;
     i := fio.get_env(n,s);
    end if;
    return s;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'GETENV', fio_pid);
   end if;
  else
   if p=PRF_VFS then
     n := substr(n,5);
   end if;
   return vfs_mgr.get_env(n);
  end if;
end;
-- @METAGS put_env
function put_env (name in varchar2, value in varchar2) return pls_integer is
  i pls_integer;
  n varchar2(200);
  p varchar2(4);
begin
  check_open;
  n := name;
  p := upper(substr(n,1,4));
  if loc_type(p) = LT_FIO then
   if p=PRF_FIO then
    n := substr(n,5);
   end if;
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.put_env(n,value);
    if i is null then
     fio_init;
     i := fio.put_env(n,value);
    end if;
    return i;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'PUTENV', fio_pid);
   end if;
  else
   if p=PRF_VFS then
    n := substr(n,5);
   end if;
   return vfs_mgr.put_env(n,value);
  end if;
end;
----------------------------------------------------------
function open_mode2vfs_mode(aopen_mode in varchar2) return char as
  md varchar2(2);
begin
  md := upper(aopen_mode);
  if    md = 'R' then return vfs_mgr.MODE_READ;
  elsif md = 'W' then return vfs_mgr.MODE_WRITE;
  elsif md in ('A','A+','+A') then return vfs_mgr.MODE_APPEND;
  elsif md in ('RW','R+','+R','W+','+W') then return vfs_mgr.MODE_READWRITE;
  else return null;
  end if;
end open_mode2vfs_mode;
-----------------------------------------------------
-- @METAGS f_open
function f_open(filename  in varchar2,
                open_mode in varchar2,
                p_chk boolean default false,
                name_text pls_integer default NULL ) return pls_integer is
  fid integer;
  fn varchar2(4000);
  fmode char;
  f_name varchar2(4000);
  f_path varchar2(4000);
  i pls_integer;
  r raw(10);
  res pls_integer;
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(filename,lt,name_text);
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.fopen(loc,lower(open_mode),r,p_chk);
    if i is null then
     fio_init;
     loc := correct_path(filename,lt,name_text);
     i := fio.fopen(loc,lower(open_mode),r,p_chk);
    end if;
    if i>0 then
     res := ffio.count + 1;
     ffio(res).name := loc;
     ffio(res).open_mode:= open_mode;
     ffio(res).stream := r;
     ffio(res).lsize:= stdio_line_size;
     ffio(res).text := nvl(name_text,nam_text);
     ffio(res).loc_type := LT_FIO;
     ffio(res).handle := i;
     return res;
    else
     return i;
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_OPEN', fio_pid);
   end if;
  else
   fn := get_path(loc);
   fid := vfs_mgr.get_id_by_name$(fn);
   fmode := open_mode2vfs_mode(open_mode);
   if    fid = vfs_mgr.ERR_INVALID_PATH then
    if fmode = vfs_mgr.MODE_WRITE then
     fid := instr(fn,vfs_slash,-1);
     if fid > 0 then
      f_path := substr(fn,1,fid - 1);
      f_name := substr(fn,fid + 1);
     else
      f_path := null;
      f_name := fn;
     end if;
     fid := vfs_mgr.get_id_by_name$(f_path);
     if fid < vfs_mgr.ERR_SUCCESS then
      return fid;
     end if;
     fid := vfs_mgr.create_file$(aname=>f_name,aparent_id=>fid);
     if fid < vfs_mgr.ERR_SUCCESS then
      return fid;
     end if;
    else
     return fid;
    end if;
   elsif fid < vfs_mgr.ERR_SUCCESS then
    return fid;
   end if;
   i := vfs_mgr.open$(fid,fmode);
   if i <= 0 then
    return i;
   end if;
   res := ffio.count + 1;
   ffio(res).name := fn;
   ffio(res).open_mode := fmode;
   ffio(res).lsize:= stdio_line_size;
   ffio(res).text := nvl(name_text,nam_text);
   ffio(res).loc_type := LT_VFS;
   ffio(res).handle := i;
   return res;
  end if;
end;
-- @METAGS f_dopen
function f_dopen(handle in pls_integer, open_mode in varchar2 ) return pls_integer is
  i pls_integer;
  r raw(10);
  res pls_integer;
begin
  if not ffio.exists(handle) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(handle).loc_type = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.fdopen(ffio(handle).handle,lower(open_mode),r);
    if i is null then
     fio_init;
     i := fio.fdopen(ffio(handle).handle,lower(open_mode),r);
    end if;
    if i>0 then
     res := ffio.count + 1;
     ffio(res).name := 'Opened from handle: '||handle;
     ffio(res).stream := r;
     ffio(res).open_mode:= open_mode;
     ffio(res).lsize:= stdio_line_size;
     ffio(res).loc_type := LT_FIO;
     ffio(res).handle := i;
     return res;
    else
     return i;
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_DOPEN', fio_pid);
   end if;
  else
   return f_open(get_file_name(handle),open_mode,false,ffio(handle).text);
  end if;
end;
-- @METAGS f_close
function f_close ( file IN OUT nocopy pls_integer  ) return pls_integer is
  result pls_integer;
  i pls_integer;
begin
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
   if fio_pid>0 then
    if ffio.exists(file) then
     if ffio(file).stream is null then
      i := fio.hclose(ffio(file).handle);
     else
      i := fio.fclose(ffio(file).handle,ffio(file).stream);
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
  else
   result := vfs_mgr.close$(ffio(file).handle);
   if result = 0 then
    ffio.delete(file);
    file := null;
   end if;
   return result;
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
     if ffio(file).loc_type = LT_FIO then
      if ffio(file).stream is null then
       i := fio.hclose(ffio(file).handle);
      else
       i := fio.fclose(ffio(file).handle,ffio(file).stream);
      end if;
      if i=0 then
       ffio.delete(file);
      else
       msg := msg||','||get_file_name(file,true);
      end if;
     else
      i := f_close(file);
     end if;
    end loop;
   end if;
   if nvl(not p_files,true) then
    idx  := fdir.first;
    while not idx is null loop
     file:= idx;
     idx := fdir.next(idx);
     if fdir(file).loc_type = LT_FIO then
      i := fio.closedir(fdir(file).handle,fdir(file).stream);
      if i=0 then
       fdir.delete(file);
      else
       msg := msg||','||get_file_name(file,false);
      end if;
     else
      i := closedir(file);
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
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
   if fio_pid>0 then
    if ffio.exists(file) then
     if not ffio(file).stream is null then
      return fio.fflush(ffio(file).handle,ffio(file).stream);
     end if;
     return 0;
    else
     message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'F_FLUSH', fio_pid);
   end if;
  else
   return 0;
  end if;
end;
-- @METAGS f_seek
function f_seek (file pls_integer, pos in out nocopy varchar2, off_i pls_integer, how_i pls_integer default 0) return pls_integer is
  i pls_integer;
begin
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
    if fio_pid>0 then
      if ffio.exists(file) then
        if ffio(file).stream is null then
          return fio.hseek(ffio(file).handle,off_i,how_i,pos);
        else
          return fio.fseek(ffio(file).handle,ffio(file).stream,off_i,how_i,pos);
        end if;
      else
        message.error(constant.EXEC_ERROR,'FILEHANDLE0');
      end if;
    else
      message.error( constant.EXEC_ERROR,'INTERNAL_ERROR','F_SEEK',fio_pid);
    end if;
  else
    i := vfs_mgr.seek$(ffio(file).handle,off_i,how_i);
    if i>=0 then
      pos := i;
      return 0;
    end if;
    return i;
  end if;
end;
--
-- @METAGS f_truncate
function f_truncate ( file pls_integer, p_size pls_integer default null ) return pls_integer is
begin
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type <> LT_FIO then
    return vfs_mgr.ERR_NOT_SUPPORTED;
  end if;
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
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
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
  else
    return vfs_mgr.seek$(ffio(file).handle,0,1);
  end if;
end;
--
-- @METAGS f_read
function f_read (file pls_integer, bf_o in out nocopy raw, sz_i pls_integer) return pls_integer is
  i pls_integer;
begin
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
   if fio_pid>0 then
    if ffio.exists(file) then
     if ffio(file).stream is null then
      return fio.hread(ffio(file).handle,bf_o,sz_i);
     else
      return fio.fread(ffio(file).handle,ffio(file).stream,bf_o,sz_i);
     end if;
    else
     message.error(constant.EXEC_ERROR,'FILEHANDLE0');
    end if;
   else
    message.error( constant.EXEC_ERROR,'INTERNAL_ERROR','F_READ',fio_pid);
   end if;
  else
   return vfs_mgr.read$(ffio(file).handle,bf_o,sz_i);
  end if;
end;
-- @METAGS f_write
function f_write (file pls_integer, bf_i in raw, sz_i pls_integer default 0) return pls_integer is
begin
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
   if fio_pid>0 then
    if ffio.exists(file) then
     if ffio(file).stream is null then
      return fio.hwrite(ffio(file).handle,bf_i,sz_i);
     else
      return fio.fwrite(ffio(file).handle,ffio(file).stream,bf_i,sz_i);
     end if;
    else
     message.error(constant.EXEC_ERROR,'FILEHANDLE0');
    end if;
   else
    message.error( constant.EXEC_ERROR,'INTERNAL_ERROR','F_WRITE',fio_pid);
   end if;
  else
   return vfs_mgr.write$(ffio(file).handle,bf_i,sz_i);
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
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if ffio(file).loc_type = LT_FIO then
   if fio_pid>0 then
    if ffio.exists(file) and not ffio(file).stream is null then
     i := fio.fread(ffio(file).handle,ffio(file).stream,r,sz_i);
    else
     message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'READ_STR', fio_pid);
   end if;
  else
   i := vfs_mgr.read$(ffio(file).handle,r,sz_i);
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
  if not ffio.exists(file) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
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
  if ffio(file).loc_type = LT_FIO then
   if fio_pid>0 then
    if ffio.exists(file) and not ffio(file).stream is null then
     return fio.fwrite(ffio(file).handle,ffio(file).stream,utl_raw.cast_to_raw(l),0);
    else
     message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'WRITE_STR', fio_pid);
   end if;
  else
   return vfs_mgr.cwrite$(ffio(file).handle,l);
  end if;
end;
-- @METAGS get_file_name
function get_file_name ( file pls_integer, p_files boolean default true ) return varchar2 is
begin
  if file is null then return null; end if;
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
  p pls_integer;
  f_old_name varchar2(4000);
  f_new_path varchar2(4000);
  f_new_name varchar2(4000);
  onm varchar2(4000);
  nnm varchar2(4000);
  oid integer;
  nid integer;
  lt_old pls_integer;
  lt_new pls_integer;
  loc_o varchar2(4000);
  loc_n varchar2(4000);
begin
  loc_o := correct_path(oldname,lt_old,name_text);
  loc_n := correct_path(newname,lt_new,name_text);
  if    lt_old = LT_FIO and lt_new = LT_FIO then
    if fio_pid is null then
      fio_init;
    end if;
    if fio_pid>0 then
      i := fio.fcopy(loc_o,loc_n,p_write,p_chk,fsize);
      if i is null then
        fio_init;
        i := fio.fcopy(correct_path(oldname,lt_old,name_text),correct_path(newname,lt_new,name_text),p_write,p_chk,fsize);
      end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FCOPY', fio_pid);
    end if;
  elsif lt_old = LT_VFS and lt_new = LT_VFS then
    onm := loc_o;
    nnm := loc_n;
    p := instr(nnm,vfs_slash,-1);
    if p > 0 then
      f_new_path := get_path(substr(nnm,1,p - 1));
      f_new_name := substr(nnm,p + 1);
    else
      f_new_path := get_path(null);
      f_new_name := nnm;
    end if;
    f_old_name := get_path(onm);
    oid := vfs_mgr.get_id_by_name$(f_old_name);
    if oid < vfs_mgr.ERR_SUCCESS then return oid; end if;
    nid := vfs_mgr.get_id_by_name$(f_new_path);
    if nid < vfs_mgr.ERR_SUCCESS then return nid; end if;
    i := vfs_mgr.copy$(oid,nid,f_new_name);
    if i>=0 then
      fsize := i;
      return 0;
    end if;
    return i;
  else
   declare
    fs pls_integer;
    fd pls_integer;
    buf raw(32000);
    sz pls_integer;
    tmp pls_integer;
    res pls_integer;
   begin
    fs := f_open(oldname,'r',p_chk,name_text);
    if fs <= 0 then return fs; end if;
    fd := f_open(newname,'w',p_chk,name_text);
    if fd <= 0 then res := f_close(fs); return fd; end if;
    res := 0;
    loop
     sz := f_read(fs,buf,32000);
     if sz > 0 then
      res := res + sz;
      tmp := f_write(fd,buf,sz);
      if tmp < 0 then sz := tmp; end if;
     end if;
     exit when sz < 32000;
    end loop;
    tmp := f_close(fs);
    tmp := f_close(fd);
    if sz < 0 then
     return sz;
    else
     fsize := res;
     return 0;
    end if;
   end;
  end if;
end;
----------------------------------------------------------
function info2attrs(atype in pls_integer,
  aothers_access_mask in pls_integer, asubject_access_mask in pls_integer) return varchar2 as
  result varchar2(10);
begin
  if atype = vfs_mgr.VFS_FILE then result := '-'; else result := 'd'; end if;
  result := result || 'rw-rw-';
  if bitand(aothers_access_mask,vfs_admin.ACCESS_READ) = 0 then
   result := result || '-';
  else
   result := result || 'r';
  end if;
  if bitand(aothers_access_mask,vfs_admin.ACCESS_WRITE) = 0 then
   result := result || '-';
  else
   result := result || 'w';
  end if;
  return result || '-';
end info2attrs;
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
  f_name varchar2(512);
  f_type pls_integer;
  f_owner varchar2(30);
  f_size pls_integer;
  f_others_access_mask pls_integer;
  f_subject_access_mask pls_integer;
  f_create_date date;
  f_modify_date date;
  f_charset varchar2(20);
  f_parent_id integer;
  f_storage_id integer;
  f_description varchar2(4000);
  result pls_integer;
  i pls_integer;
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(name,lt,lt);
  if lt = LT_FIO then
    if fio_pid is null then
      fio_init;
    end if;
    if fio_pid>0 then
      i := fio.finfo(loc,attrs,uowner,gowner,mdate,fsize,p_chk);
      if i is null then
        fio_init;
        i := fio.finfo(correct_path(name,lt,name_text),attrs,uowner,gowner,mdate,fsize,p_chk);
      end if;
      return i;
    else
      message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'FINFO', fio_pid);
    end if;
  else
   f_name := get_path(loc);
   result := vfs_mgr.get_id_by_name$(f_name);
   if result < vfs_mgr.ERR_SUCCESS then return result; end if;
   attrs := null;
   uowner := null;
   gowner := null;
   mdate := null;
   fsize := null;
   result := vfs_mgr.info$(
    result,
    f_name,
    f_type,
    f_owner,
    f_size,
    f_others_access_mask,
    f_subject_access_mask,
    f_create_date,
    f_modify_date,
    f_charset,
    f_parent_id,
    f_storage_id,
    f_description);
   if result <> vfs_mgr.ERR_SUCCESS then return result; end if;
   uowner := f_owner;
   gowner := f_owner;
   mdate := to_char(nvl(f_modify_date,f_create_date),constant.date_format);
   fsize := f_size;
   attrs := info2attrs(f_type,f_others_access_mask,f_subject_access_mask);
   return result;
  end if;
end;
--
function  opendir( dirname varchar2, mask varchar2 default null,
                   dir_flag  pls_integer default 0, p_chk boolean default false,
                   name_text pls_integer default NULL) return pls_integer is
  dn varchar2(4000);
  did integer;
  i pls_integer;
  t pls_integer;
  r raw(10);
  m varchar2(100);
  loc varchar2(4000);
  lt  pls_integer;
begin
  loc := correct_path(dirname,lt,name_text);
  t := nvl(name_text,nam_text);
  if def_text<>t then
    m := translate(mask,get_str(def_text),get_str(t));
  else
    m := mask;
  end if;
  if lt = LT_FIO then
   if fio_pid is null then
    fio_init;
   end if;
   if fio_pid>0 then
    i := fio.opendir(loc,m,dir_flag,r,p_chk);
    if i is null then
     fio_init;
     loc := correct_path(dirname,lt,name_text);
     i := fio.opendir(loc,m,dir_flag,r,p_chk);
    end if;
    if i>0 then
     did := fdir.count + 1;
     fdir(did).name := loc||slash||nvl(m,'*');
     fdir(did).stream := r;
     fdir(did).lsize:= dir_flag;
     fdir(did).text := t;
     fdir(did).loc_type := LT_FIO;
     fdir(did).handle := i;
     return did;
    else
     return i;
    end if;
   else
    message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'OPENDIR', fio_pid);
   end if;
  else
   dn := get_path(loc);
   did := vfs_mgr.get_id_by_name$(dn);
   if did < vfs_mgr.ERR_SUCCESS then return did; end if;
   i := vfs_mgr.open_folder(did,m,dir_flag);
   if i > 0 then
    did := fdir.count + 1;
    fdir(did).name := dn||vfs_slash||nvl(m,'*');
    fdir(did).loc_type := LT_VFS;
    fdir(did).text := t;
    fdir(did).handle := i;
    return did;
   else
    return i;
   end if;
  end if;
end;
--
function  closedir(dir  in out nocopy pls_integer ) return pls_integer is
  result pls_integer;
  i pls_integer;
begin
  if not fdir.exists(dir) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if fdir(dir).loc_type = LT_FIO then
   if fio_pid>0 then
    if fdir.exists(dir) then
     i := fio.closedir(fdir(dir).handle,fdir(dir).stream);
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
  else
   result := vfs_mgr.close_folder(fdir(dir).handle);
   fdir.delete(dir);
   dir := null;
   return result;
  end if;
end;
--
function  resetdir(dir  pls_integer ) return pls_integer is
begin
  if not fdir.exists(dir) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if fdir(dir).loc_type = LT_FIO then
   if fio_pid>0 then
    if fdir.exists(dir) then
     return fio.resetdir(fdir(dir).handle,fdir(dir).stream);
    else
     message.error( constant.EXEC_ERROR,'FILEHANDLE0');
    end if;
   else
    message.error( constant.EXEC_ERROR,'INTERNAL_ERROR','RESETDIR',fio_pid);
   end if;
  else
   return vfs_mgr.reset_folder(fdir(dir).handle);
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
  result pls_integer;
  f_id integer;
  f_name varchar2(512);
  f_type pls_integer;
  f_owner varchar2(30);
  f_size pls_integer;
  f_others_access_mask pls_integer;
  f_subject_access_mask pls_integer;
  f_create_date date;
  f_modify_date date;
  f_charset varchar2(20);
  f_parent_id integer;
  f_storage_id integer;
  f_description varchar2(4000);
begin
  if not fdir.exists(dir) then
    message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
  end if;
  if fdir(dir).loc_type = LT_FIO then
    if fio_pid>0 then
      if fdir.exists(dir) then
        result := fio.readdir(fdir(dir).handle,fdir(dir).stream,name,attrs,uowner,gowner,mdate,fsize);
        if result>0 and fdir(dir).text<>def_text then
          name := translate(name,get_str(fdir(dir).text),get_str(def_text));
        end if;
        return result;
      else
        message.error( constant.EXEC_ERROR, 'FILEHANDLE0' );
      end if;
    else
      message.error( constant.EXEC_ERROR, 'INTERNAL_ERROR', 'READDIR', fio_pid);
    end if;
  else
   name := null;
   attrs := null;
   uowner := null;
   gowner := null;
   mdate := null;
   fsize := null;
   result := vfs_mgr.read_folder(
    fdir(dir).handle,
    f_id,
    f_name,
    f_type,
    f_owner,
    f_size,
    f_others_access_mask,
    f_subject_access_mask,
    f_create_date,
    f_modify_date,
    f_charset,
    f_parent_id,
    f_storage_id,
    f_description);
   if result > vfs_mgr.ERR_SUCCESS then
    if fdir(dir).text<>def_text then
      name := translate(f_name,get_str(fdir(dir).text),get_str(def_text));
    else
      name := f_name;
    end if;
    attrs := info2attrs(f_type,f_others_access_mask,f_subject_access_mask);
    uowner := f_owner;
    gowner := f_owner;
    mdate := to_char(nvl(f_modify_date,f_create_date),constant.date_format);
    fsize := f_size;
   end if;
   return result;
  end if;
end;
----------------------------------------------------------
procedure make_alias_list(astr in varchar2) as
  cpos integer;
  ppos integer;
  epos integer;
  cstr varchar2(4000);
  cind pls_integer;
begin
  if astr is null then return; end if;
  cpos := 0;
  loop
   ppos := cpos;
   cpos := instr(astr,';',ppos + 1);
   if cpos = 0 then
    cstr := substr(astr,ppos + 1);
   else
    cstr := substr(astr,ppos + 1,cpos - 1);
   end if;
   if not cstr is null then
    epos := instr(cstr,'=');
    cind := falias.count + 1;
    if epos > 0 then
     falias(cind).search_str := substr(cstr,1,epos - 1) || '%';
     falias(cind).replace_str := substr(cstr,epos + 1);
    else
     falias(cind).search_str := cstr || '%';
    end if;
    falias(cind).search_length := length(falias(cind).search_str);
   end if;
   exit when cpos = 0;
  end loop;
end make_alias_list;
----------------------------------------------------------
procedure io_open as
  tmp pls_integer;
  prof varchar2(30);
  dfs varchar2(4000);
  str varchar2(4000);
begin
  if init_size then set_size; end if;
  if init_text then set_def_text(null); end if;
  if INITED then io_close; end if;
  INITED := null;
  vfs_mgr.vfs_open;
  vfs_slash := vfs_mgr.PATH_SEPARATOR;
  vfs_slash2 := vfs_slash || vfs_slash;
  vfs_selfdir:= vfs_slash||'.'||vfs_slash;
  vfs_root_dir := vfs_mgr.root_dir;
  vfs_home_dir := vfs_mgr.home_dir;
  vfs_replace_dir := vfs_mgr.replace_dir || '%';
  vfs_replace_length := nvl(length(vfs_replace_dir),0);
  prof := stdio.get_profile(null);
  dfs := stdio.get_resource(prof,'DEFAULT_FILE_SYSTEM');
  if dfs is null and prof <> 'DEFAULT' then
   dfs := stdio.get_resource('DEFAULT','DEFAULT_FILE_SYSTEM');
  end if;
  LT_DEFAULT := loc_type(substr(dfs,1,3)||':');
  dfs := stdio.get_resource(prof,'FILE_ALIAS');
  if prof <> 'DEFAULT' then
   str := stdio.get_resource('DEFAULT','FILE_ALIAS');
   if not str is null then
    if not dfs is null then
     dfs := dfs || ';';
    end if;
    dfs := dfs || str;
   end if;
  end if;
  make_alias_list(dfs);
  INITED := true;
end io_open;
----------------------------------------------------------
procedure io_close as
  tmp pls_integer;
begin
  vfs_root_dir := null;
  vfs_home_dir := null;
  vfs_replace_dir := null;
  vfs_replace_length := null;
  falias.delete;
  INITED := false;
end io_close;
----------------------------------------------------------
procedure check_open as
begin
  if    INITED is null then
   null;
  elsif not INITED then
   io_open;
  end if;
end check_open;
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
        v_txt := substr(stdio.setting('DEF_TEXT'),1,1);
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
        v_txt := substr(stdio.setting('STDIO_FILE_NAME_TEXT'),1,1);
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
        v_slash := substr(stdio.setting('DEF_SLASH'),1,1);
    end if;
    if v_slash='\' then
        slash := '\';
    else
        slash := '/';
    end if;
    slash2 := slash||slash;
    selfdir:= slash||'.'||slash;
    if v_cr is null then
        v_cr := substr(stdio.setting('DEF_CR_ADD'),1,100);
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
----------------------------------------------------------
procedure set_size(line_size in pls_integer default null) as
  v_line  pls_integer := line_size;
begin
  if v_line is null then
    v_line:= stdio.num_set('STDIO_LINE_SIZE');
  end if;
  if v_line<=0 then
    v_line:= stdio.STDIOLINESIZE;
  end if;
  stdio_line_size:= v_line;
  init_size := false;
end set_size;
----------------------------------------------------------
procedure get_size(line_size out pls_integer) as
begin
  if init_size then set_size; end if;
  line_size := stdio_line_size;
end get_size;
-----------------------------------------------------
procedure Init is
begin
    io_close;
    fio_close;
    init_text := true;
    init_size := true;
end;
--
end;
/
sho err

