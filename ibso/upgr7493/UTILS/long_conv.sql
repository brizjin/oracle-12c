spool long_conv.log

var mes varchar2(2000)
var own varchar2(100)
var cnv number;

print mes

exec :cnv := 0; :mes := null;

begin
  select '1' into :cnv from user_tab_columns
   where table_name='LRAW' and column_name='DATA';
exception when no_data_found then
  :mes := 'LRAW.DATA not exists...';
  :cnv := 0;
end;
/

print mes

begin
  if :cnv=1 then
    execute immediate 'insert into lconv(r,b) select rowid,to_lob(data) from lraw where data is not null';
    update lraw l
       set bdata = (select b from lconv where r=l.rowid)
     where data is not null;
    :mes := 'LRAW.BDATA column values converted: '||sql%rowcount;
    commit;
    execute immediate 'alter table lraw drop column data';
  else
    :mes := 'LRAW.BDATA convertation skipped...';
  end if;
end;
/

print mes

exec :cnv := 0; :mes := null; :own := null;

begin
  begin
    select object_type into :own
      from user_objects where object_name='LONG_DATA';
    if :own='SYNONYM' then
      select table_owner into :own
        from user_synonyms where synonym_name='LONG_DATA';
    else
      :own := USER;
    end if;
  exception when no_data_found then
    :mes := 'LONG_DATA object not exists...';
    return;
  end;
  select '1' into :cnv from dba_tab_columns
   where owner=:own and table_name='LONG_DATA' and column_name='DATA';
exception when no_data_found then
  :mes := 'LONG_DATA.DATA not exists...';
  :cnv := 0;
end;
/

print mes

begin
  if :cnv=1 then
    execute immediate 'insert into lconv(r,b) select rowid,to_lob(data) from long_data where data is not null';
    update long_data l
       set bdata = (select b from lconv where r=l.rowid)
     where data is not null;
    :mes := 'LONG_DATA.BDATA column values converted: '||sql%rowcount;
    commit;
    execute immediate 'alter table '||:own||'.long_data drop column data';
  else
    :mes := 'LONG_DATA.BDATA convertation skipped...';
  end if;
end;
/

print mes

exec :cnv := 0; :mes := null; :own := null;

begin
  begin
    select object_type into :own
      from user_objects where object_name='ORSA_JOBS_OUT';
    if :own='SYNONYM' then
      select table_owner into :own
        from user_synonyms where synonym_name='ORSA_JOBS_OUT';
    else
      :own := USER;
    end if;
  exception when no_data_found then
    :mes := 'ORSA_JOBS_OUT object not exists...';
    return;
  end;
  select '1' into :cnv from dba_tab_columns
   where owner=:own and table_name='ORSA_JOBS_OUT' and column_name='BODY';
exception when no_data_found then
  :mes := 'ORSA_JOBS_OUT.BODY not exists...';
  :cnv := 0;
end;
/

print mes

begin
  if :cnv=1 then
    execute immediate 'insert into lconv(r,b) select rowid,to_lob(body) from orsa_jobs_out where body is not null';
    update orsa_jobs_out l
       set bdata = (select b from lconv where r=l.rowid)
     where body is not null;
    :mes := 'ORSA_JOBS_OUT.BDATA column values converted: '||sql%rowcount;
    commit;
    execute immediate 'alter table '||:own||'.orsa_jobs_out drop column body';
  else
    :mes := 'ORSA_JOBS_OUT.BDATA convertation skipped...';
  end if;
end;
/

print mes

spool off

