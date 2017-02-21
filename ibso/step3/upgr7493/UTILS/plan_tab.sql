var mes varchar2(2000);

declare
  b boolean;
  v_typ varchar2(100);
  v_tbl varchar2(100);
  v_sql varchar2(1000);
begin
  :mes := null;
  for c in (select object_type from user_objects where object_name='PLAN_TABLE') loop
    v_typ := c.object_type;
    exit;
  end loop;
  if v_typ = 'SYNONYM' then
    b := false;
    for c in (select table_name from user_synonyms
               where synonym_name='PLAN_TABLE' and table_owner = 'SYS') loop
      v_tbl := c.table_name;
      b := true;
    end loop;
    if b then
      b := false;
      for c in (select table_name from dba_synonyms
                 where owner = 'PUBLIC' and synonym_name='PLAN_TABLE' and table_owner = 'SYS') loop
        if v_tbl <> c.table_name then
          v_tbl := c.table_name;
          b := true;
        end if;
      end loop;
    end if;
    if b then
      v_typ := null;
    else
      :mes := 'Synonym for PLAN_TABLE exists...';
    end if;
  elsif v_typ = 'TABLE' then
    b := inst_info.db_version > 9;
    if b then
      b := false;
      for c in (select table_name from dba_synonyms
                 where owner = 'PUBLIC' and synonym_name='PLAN_TABLE' and table_owner = 'SYS') loop
        v_tbl := c.table_name;
        b := true;
      end loop;
    end if;
    if b then
      v_sql := 'drop table plan_table';
      execute immediate v_sql;
      :mes := 'Table PLAN_TABLE dropped.'||chr(10);
      v_typ := null;
    else
      v_sql := 'grant all on plan_table to '||inst_info.owner||'_ADMIN';
      execute immediate v_sql;
      :mes := 'Grant on PLAN_TABLE to ADMIN role created.'||chr(10);
      v_sql := 'grant select on plan_table to '||inst_info.owner||'_USER';
      execute immediate v_sql;
      :mes := :mes||'Grant on PLAN_TABLE to USER role created.'||chr(10);
    end if;
  else
    :mes := 'Non-standard Object ' || v_typ || ' PLAN_TABLE exists...';
  end if;
  if v_typ is null then
    v_sql := 'create or replace synonym plan_table for sys.' || v_tbl;
    execute immediate v_sql;
    :mes := :mes || 'Synonym PLAN_TABLE created.'||chr(10);
  end if;
exception when others then
  :mes := 'ERROR: '||v_sql||chr(10)||sqlerrm;
end;
/

print mes

