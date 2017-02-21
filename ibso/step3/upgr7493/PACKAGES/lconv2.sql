prompt long_conv body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/lconv2.sql $
 *  $Author: sanja $
 *  $Revision: 49122 $
 *  $Date:: 2014-07-21 17:54:10 #$
 */
long_conv is
--
type handle_t is record (
    id     varchar2(128),
    dmode  pls_integer,
    dtable varchar2(30),
    rpos   pls_integer,
    wpos   pls_integer,
    bdata  blob,
    cdata  clob,
    t      varchar2(4)
);
type handle_tbl_t is table of handle_t index by binary_integer;
handles handle_tbl_t;
--
l_inited  boolean;
l_rowids  "CONSTANT".ROWID_TABLE;
l_table   varchar2(100);
l_owner   varchar2(30);
l_from_column varchar2(30);
l_to_column   varchar2(30);
l_lob_column  varchar2(10);
--
procedure init_conversion(p_table varchar2, p_from_column varchar2, p_to_column varchar2, p_owner varchar2 default null) is
  i pls_integer;
  v_typ1  varchar2(100);
  v_typ2  varchar2(100);
begin
  l_rowids.delete;
  l_inited:= false;
  l_table := p_table;
  l_from_column := p_from_column;
  l_to_column := p_to_column;
  method.set_owner(l_table,l_owner,nvl(p_owner,inst_info.gowner));
  v_typ1 := storage_utils.get_column_type(l_table,l_from_column,'0',l_owner);
  v_typ2 := storage_utils.get_column_type(l_table,l_to_column,'0',l_owner);
  if v_typ1 is null or v_typ2 is null then
    raise rtl.no_data_found;
  elsif v_typ1='LONG RAW' and v_typ2='BLOB' then
    l_lob_column := 'b';
  elsif v_typ1='LONG' and v_typ2='CLOB' then
    l_lob_column := 'c';
  else
    raise rtl.no_data_found;
  end if;
  l_inited:= true;
end;
--
procedure add_rowid(p_rowid rowid) is
  i pls_integer;
begin
  if l_inited then
    if p_rowid is null then
      return;
    end if;
    i := nvl(l_rowids.last,0) + 1;
    l_rowids(i) := p_rowid;
    --stdio.put_line_buf(l_table||'-'||i||':'||p_rowid);
  else
    raise rtl.no_data_found;
  end if;
end;
--
procedure convert_rows is
  n pls_integer;
begin
  if l_inited then
    l_inited := false;
    n := l_rowids.count;
    if n>0 then
      forall i in 1..n
        execute immediate
        'insert into lconv(r,'||l_lob_column||') select rowid,to_lob('||l_from_column||') from '||l_owner||'.'||l_table||' where rowid=:1'
        using l_rowids(i);
      forall i in 1..n
        execute immediate
        'update '||l_table||' l set '||l_to_column||' = (select '||l_lob_column||' from lconv where r=l.rowid) where rowid=:1'
         using l_rowids(i);
      --stdio.put_line_buf(l_table||':'||n||'->'||sql%rowcount);
      l_rowids.delete;
    end if;
  else
    raise rtl.no_data_found;
  end if;
end;
--
procedure get_job_param(p_id varchar2, p_job out number, p_pos out number, p_add out varchar2) is
v_tbl "CONSTANT".refstring_table;
begin
  lib.set_refs_list(p_id,v_tbl);
  p_job:= v_tbl(1);
  p_pos:= nvl(v_tbl(2),1);
  if v_tbl.exists(3) then
    p_add:= v_tbl(3);
  end if;
end;
--
function open_lob(p_blob in out nocopy blob, p_clob in out nocopy clob, p_id varchar2, p_mode pls_integer, p_table varchar2, p_type varchar2) return boolean is
v_job number;
v_pos number;
v_add varchar2(32);
dummy varchar2(32);
begin
  if (not p_blob is null and dbms_lob.isopen(p_blob)<>0) or (not p_clob is null and dbms_lob.isopen(p_clob)<>0)
  then
    return false;
  end if;
  if p_table='ORSA_JOBS_OUT' then
    get_job_param(p_id,v_job,v_pos,v_add);
    v_add:= nvl(v_add,'out');
  elsif p_table='ORSA_PAR_LOB' then
    get_job_param(p_id,v_job,v_pos,v_add);
    v_add:= nvl(v_add,'XMLDATA');
  end if;
  if p_mode=mode_readonly then
    if p_table='LICENSE_DATA' then
      select data into p_blob from license_data where id = p_id;
    elsif p_table='LRAW' then
      select bdata into p_blob from lraw where id = p_id;
    elsif p_table='LONG_DATA' then
      select bdata into p_blob from long_data where id = p_id;
    elsif p_table='ORSA_JOBS_OUT' then
      select bdata into p_blob from orsa_jobs_out where job=v_job and pos=v_pos and out_type=v_add;
    elsif p_table='ORSA_PAR_LOB' then
      if p_type='BLOB' then
        select b into p_blob from orsa_par_lob where job=v_job and pos=v_pos and name=v_add;
      elsif p_type='CLOB' then
        select c into p_clob from orsa_par_lob where job=v_job and pos=v_pos and name=v_add;
      end if;
    end if;
    if (p_type='BLOB' and p_blob is null) or (p_type='CLOB' and p_clob is null) then
      return true;
    end if;
  elsif p_mode=mode_readwrite then
    if p_table='LICENSE_DATA' then
      raise NO_PRIVILEGES;
    elsif p_table='LRAW' then
        select bdata into p_blob from lraw
           where id = p_id for update nowait;
          if p_blob is null then
            update lraw set bdata=empty_blob() where id = p_id;
          end if;
          select bdata into p_blob from lraw where id = p_id;
    elsif p_table='LONG_DATA' then
        select bdata into p_blob from long_data
           where id = p_id for update nowait;
          if p_blob is null then
            update long_data set bdata=empty_blob() where id = p_id;
          end if;
          select bdata into p_blob from long_data where id = p_id;
    elsif p_table='ORSA_JOBS_OUT' then
        select bdata into p_blob from orsa_jobs_out
           where job=v_job and pos=v_pos and out_type=v_add for update nowait;
          if p_blob is null then
            update orsa_jobs_out set bdata=empty_blob() where job=v_job and pos=v_pos and out_type=v_add;
          end if;
          select bdata into p_blob from orsa_jobs_out where job=v_job and pos=v_pos and out_type=v_add;
    elsif p_table='ORSA_PAR_LOB' then
      if p_type='BLOB' then
        select b into p_blob from orsa_par_lob
          where job=v_job and pos=v_pos and name=v_add for update nowait;
        if p_blob is null then
          update orsa_par_lob set b=empty_blob() where job=v_job and pos=v_pos and name=v_add;
        end if;
        select b into p_blob from orsa_par_lob where job=v_job and pos=v_pos and name=v_add;
      elsif p_type='CLOB' then
        select c into p_clob from orsa_par_lob
          where job=v_job and pos=v_pos and name=v_add for update nowait;
        if p_clob is null then
          update orsa_par_lob set c=empty_clob() where job=v_job and pos=v_pos and name=v_add;
        end if;
        select c into p_clob from orsa_par_lob where job=v_job and pos=v_pos and name=v_add;
      end if;
    end if;
  end if;
  if p_type='BLOB' then
    if dbms_lob.isopen(p_blob)=0 then
      dbms_lob.open(p_blob,p_mode);
    end if;
  elsif p_type='CLOB' then
    if dbms_lob.isopen(p_clob)=0 then
      dbms_lob.open(p_clob,p_mode);
    end if;
  end if;
  return true;
end;
--
function open_data(p_id varchar2, p_mode pls_integer default mode_readonly, p_table varchar2, p_type varchar2 default 'BLOB') return pls_integer is
  b blob;
  c clob;
  p pls_integer;
  s pls_integer;
  h pls_integer;
  v_type varchar2(4):= nvl(upper(p_type), 'BLOB');
begin
  if open_lob(b,c,p_id,p_mode,upper(p_table),v_type) then
    h := nvl(handles.last,0)+1;
    handles(h).id := p_id;
    handles(h).dmode:= p_mode;
    handles(h).dtable:= upper(p_table);
    handles(h).bdata := b;
    handles(h).cdata := c;
    handles(h).t := v_type;
    handles(h).rpos := 1;
    handles(h).wpos := 1;
  end if;
  return h;
end;
--
function get_data_size(p_handle pls_integer) return pls_integer is
  b blob;
  c clob;
begin
  if not handles.exists(p_handle) then
    return null;
  end if;
  if handles(p_handle).t='BLOB' then
    b := handles(p_handle).bdata;
    if b is null then
      return null;
    end if;
  elsif handles(p_handle).t='CLOB' then
    c := handles(p_handle).cdata;
    if c is null then
      return null;
    end if;
  end if;
  if open_lob(b,c,handles(p_handle).id,handles(p_handle).dmode,handles(p_handle).dtable,handles(p_handle).t) then
    handles(p_handle).bdata := b;
    handles(p_handle).cdata := c;
  end if;
  if handles(p_handle).t='BLOB' then
    return dbms_lob.getlength(b);
  else
    return dbms_lob.getlength(c);
  end if;
end;
--
function read_data$(p_handle pls_integer, p_data in out nocopy raw, p_datac in out varchar2, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer is
  b blob;
  c clob;
  p pls_integer;
  s pls_integer;
begin
  p_data := null;
  p_datac := null;
  if handles(p_handle).t='BLOB' then
    b := handles(p_handle).bdata;
    if b is null then
      return null;
    end if;
  elsif handles(p_handle).t='CLOB' then
    c := handles(p_handle).cdata;
    if c is null then
      return null;
    end if;
  end if;
  if open_lob(b,c,handles(p_handle).id,handles(p_handle).dmode,handles(p_handle).dtable,handles(p_handle).t) then
    handles(p_handle).bdata := b;
    handles(p_handle).cdata := c;
  end if;
  if p_pos>0 then
    p := p_pos;
  else
    p := handles(p_handle).rpos;
  end if;
  if p_size between 1 and 32000 then
    s := p_size;
  else
    s := 32000;
  end if;
  begin
    if handles(p_handle).t='BLOB' then
      dbms_lob.read(b,s,p,p_data);
    elsif handles(p_handle).t='CLOB' then
      dbms_lob.read(c,s,p,p_datac);
    end if;
    handles(p_handle).rpos := p+s;
  exception when no_data_found then
    if nvl(handles(p_handle).t,'BLOB')='BLOB' then
      handles(p_handle).rpos := dbms_lob.getlength(b)+1;
    elsif handles(p_handle).t='CLOB' then
      handles(p_handle).rpos := dbms_lob.getlength(c)+1;
    end if;
    s := 0;
  end;
  return s;
end;
--
function read_data (p_handle pls_integer, p_data in out nocopy raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer is
dummy varchar2(1);
begin
  return read_data$(p_handle, p_data, dummy, p_size, p_pos);
end;
function read_datac (p_handle pls_integer, p_datac in out nocopy varchar2, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer is
dummy raw(1);
begin
  return read_data$(p_handle, dummy, p_datac, p_size, p_pos);
end;
--
function clear_data(p_handle pls_integer, p_size pls_integer default null) return pls_integer is
  b blob;
  c clob;
  o boolean;
  s pls_integer;
  v_job number;
  v_pos number;
  v_add varchar2(32);
begin
  if handles(p_handle).dmode=mode_readonly then
    raise NO_PRIVILEGES;
  end if;
  if nvl(handles(p_handle).t,'BLOB')='BLOB' then
    b := handles(p_handle).bdata;
    if b is null then
      return null;
    end if;
  elsif handles(p_handle).t='CLOB' then
    c := handles(p_handle).cdata;
    if c is null then
      return null;
    end if;
  end if;
  o := open_lob(b,c,handles(p_handle).id,handles(p_handle).dmode,handles(p_handle).dtable,handles(p_handle).t);
  if p_size>0 then
    if handles(p_handle).t='BLOB' then
      dbms_lob.trim(b,s);
    elsif handles(p_handle).t='CLOB' then
      dbms_lob.trim(c,s);
    end if;
    s := p_size;
  else
    if handles(p_handle).t='BLOB' then
      dbms_lob.close(b);
    elsif handles(p_handle).t='CLOB' then
      dbms_lob.close(c);
    end if;
    if handles(p_handle).dtable='ORSA_JOBS_OUT' then
       get_job_param(handles(p_handle).id,v_job,v_pos,v_add);
    elsif handles(p_handle).dtable='ORSA_PAR_LOB' then
       get_job_param(handles(p_handle).id,v_job,v_pos,v_add);
    end if;
    if p_size is null then
      if handles(p_handle).dtable='LRAW' then
        update lraw set bdata=null where id=handles(p_handle).id;
      elsif handles(p_handle).dtable='LONG_DATA' then
        update long_data set bdata=null where id=handles(p_handle).id;
      elsif handles(p_handle).dtable='ORSA_JOBS_OUT' then
        update orsa_jobs_out set bdata=null where job=v_job and pos=v_pos and out_type=v_add;
      elsif handles(p_handle).dtable='ORSA_PAR_LOB' then
        if handles(p_handle).t='BLOB' then
          update orsa_par_lob set b=null where job=v_job and pos=v_pos and name=v_add;
        elsif handles(p_handle).t='CLOB' then
          update orsa_par_lob set c=null where job=v_job and pos=v_pos and name=v_add;
        end if;
      end if;
      b := null;
    else
      if handles(p_handle).dtable='LRAW' then
        update lraw set bdata=empty_blob() where id=handles(p_handle).id
          returning bdata into b;
      elsif handles(p_handle).dtable='LONG_DATA' then
        update long_data set bdata=empty_blob() where id=handles(p_handle).id
          returning bdata into b;
      elsif handles(p_handle).dtable='ORSA_JOBS_OUT' then
        update orsa_jobs_out set bdata=empty_blob() where job=v_job and pos=v_pos and out_type=v_add
          returning bdata into b;
      elsif handles(p_handle).dtable='ORSA_PAR_LOB' then
        if handles(p_handle).t='BLOB' then
          update orsa_par_lob set b=empty_blob() where job=v_job and pos=v_pos and name=v_add
            returning b into b;
        elsif handles(p_handle).t='CLOB' then
          update orsa_par_lob set c=empty_clob() where job=v_job and pos=v_pos and name=v_add
            returning c into c;
        end if;
      end if;
      if handles(p_handle).t='BLOB' then
        dbms_lob.open(b,handles(p_handle).dmode);
      elsif handles(p_handle).t='CLOB' then
        dbms_lob.open(c,handles(p_handle).dmode);
      end if;
      s := 0;
    end if;
  end if;
  if handles(p_handle).t='BLOB' then
    handles(p_handle).bdata := b;
  elsif handles(p_handle).t='CLOB' then
    handles(p_handle).cdata := c;
  end if;
  handles(p_handle).rpos := 1;
  handles(p_handle).wpos := 1;
  return s;
end;
--
function write_data$(p_handle pls_integer, p_data raw, p_datac in varchar2, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer is
  b blob;
  c clob;
  o boolean;
  p pls_integer;
  s pls_integer;
begin
  if handles(p_handle).dmode=mode_readonly then
    raise NO_PRIVILEGES;
  end if;
  if handles(p_handle).t='BLOB' then
    b := handles(p_handle).bdata;
  elsif handles(p_handle).t='CLOB' then
    c := handles(p_handle).cdata;
  end if;
  o := open_lob(b,c,handles(p_handle).id,handles(p_handle).dmode,handles(p_handle).dtable,handles(p_handle).t);
  if p_pos>0 then
    p := p_pos;
  else
    p := handles(p_handle).wpos;
  end if;
  if p_size>0 then
    s := p_size;
  else
    if handles(p_handle).t='BLOB' then
      s := nvl(utl_raw.length(p_data),0);
    elsif handles(p_handle).t='CLOB' then
      s := nvl(utl_raw.length(p_datac),0);
    end if;
  end if;
  if s>0 then
    if handles(p_handle).t='BLOB' then
      dbms_lob.write(b,s,p,p_data);
    elsif handles(p_handle).t='CLOB' then
      dbms_lob.write(c,s,p,p_datac);
    end if;
    o := true;
  end if;
  if o then
    if handles(p_handle).t='BLOB' then
      handles(p_handle).bdata := b;
    elsif handles(p_handle).t='CLOB' then
      handles(p_handle).cdata := c;
    end if;
    handles(p_handle).wpos := p+s;
  end if;
  return s;
end;
--
function write_data(p_handle pls_integer, p_data raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer is
begin
  return write_data$(p_handle, p_data, null, p_size, p_pos);
end;
function write_datac(p_handle pls_integer, p_datac varchar2, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer is
begin
  return write_data$(p_handle, null, p_datac, p_size, p_pos);
end;
--
function close_data(p_handle pls_integer, p_commit boolean default true) return pls_integer is
  b blob;
  c clob;
  l pls_integer;
begin
  if not handles.exists(p_handle) then
    return l;
  end if;
  l := get_data_size(p_handle);
  if handles(p_handle).t='BLOB' then
    b := handles(p_handle).bdata;
    if not b is null and dbms_lob.isopen(b)<>0 then
      dbms_lob.close(b);
    end if;
  elsif handles(p_handle).t='CLOB' then
    c := handles(p_handle).cdata;
    if not c is null and dbms_lob.isopen(c)<>0 then
      dbms_lob.close(c);
    end if;
  end if;
  if handles(p_handle).dmode=mode_readwrite then
    if not p_commit then
      rollback;
    else
      if p_commit then
        commit;
      end if;
    end if;
  end if;
  handles.delete(p_handle);
  return l;
end;
--
end long_conv;
/
show err package body long_conv

