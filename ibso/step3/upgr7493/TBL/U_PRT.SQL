prompt var pip varchar2(100)
prompt exec :pip := '&&pipe_name'
set define off
prompt exec :pip := rtrim(:pip||'&1','0')
set define on
prompt exec dbms_session.reset_package
prompt exec executor.setnlsparameters
select 'alter session set sort_area_size=83886080;' from dual;
select 'alter session enable parallel dml;' from settings where name='STORAGE_FORCE_PARALLEL';
select 'alter session enable parallel ddl;' from settings where name='STORAGE_FORCE_PARALLEL';
select 'alter tablespace &&tstab coalesce;' from dual;
select 'alter tablespace &&tsidx coalesce;' from dual;
prompt set timing on

var yyy varchar2(10);

declare
  s varchar2(20);
  b varchar2(30);
  p varchar2(30);
  l varchar2(30);
  x varchar2(30);
  i pls_integer;
begin
  :yyy := '0';
  begin
    select param_value into x from storage_parameters
     where param_group='GLOBAL' and param_name='COMPRESS_PARTITIONS';
    if upper(substr(nvl(x,'0'),1,1)) in ('1','Y') then
      x := ' nocompress) compress';
    else
      x := ')';
    end if;
  exception when others then
    x := ')';
  end;
  begin
    select value into l from settings where name='STORAGE_FORCE_NOLOGGING';
    if upper(substr(nvl(l,'1'),1,1)) in ('1','Y') then
      l := ' nologging';
    else
      l := null;
    end if;
  exception when others then
    l := ' nologging';
  end;
  begin
    select value into p from settings where name='STORAGE_FORCE_PARALLEL';
    p := upper(nvl(p,'0'));
    if substr(p,1,1)='N' then
      i := 0;
    elsif substr(p,1,1)='Y' then
      i := 1;
    else
      i := p;
      if i<1 then
        i := 0;
      end if;
    end if;
  exception when others then
    i := 0;
  end;
  if i>1 then
    p := 'parallel '||i;
  elsif i>0 then
    p := 'parallel';
  else
    p := 'noparallel';
  end if;
  for c in (
    select p.ord, ct.class_id, ct.table_name, cp.class_id prt_class,
           p.crt_user,p.mod_user,p.stage,p.loaddata,p.param_group,p.notes,p.fname
      from &&usertables ut, project p, class_tables ct, class_partitions cp
     where ut.table_name=ct.table_name &&whereclause
       and ct.table_name like 'Z#%'
       and ct.class_id = cp.class_id(+)
       and cp.partition_position(+) is null
       and p.name = ct.class_id
       and p.type like 'UPGRADE%'
       and ( '&1' in ('1','2','3') and p.build='&1'
         or nvl('&1','0') not in ('1','2','3') and nvl(p.build,0) not between 1 and 3 )
     union
    select p.ord, p.name, null, null,
           null,null,to_number(null),null,null,p.notes,null
      from project p
     where p.name='<COMMAND>' and p.type like 'UPGRADE%'
       and ( '&1' in ('1','2','3') and p.build='&1'
         or nvl('&1','0') not in ('1','2','3') and nvl(p.build,0) not between 1 and 3 )
     order by 1, 2
  ) loop
    if c.class_id='<COMMAND>' then
      stdio.put_line_buf(chr(10)||c.notes||chr(10));
    elsif c.fname is not null then
      stdio.put_line_buf(chr(10)||'prompt '||c.class_id||'.'||c.fname);
      stdio.put_line_buf('declare');
      stdio.put_line_buf('  v_free varchar2(10); v_init varchar2(10); v_next varchar2(10); v_idx varchar2(30); v_degr varchar2(30);');
      stdio.put_line_buf('  v_ts varchar2(30); v_prt varchar2(10); v_sql varchar2(20000); v_tbl varchar2(30); v_col varchar2(30); v_own varchar2(30);');
      stdio.put_line_buf('begin v_tbl:='''||c.table_name||'''; v_col:='''||c.fname||'''; v_own:=storage_utils.get_object_schema(v_tbl,''TABLE'',''0'');');
      if c.loaddata='0' then s:='_REF'; b:=x; else s:='_COL'; b:=')'; end if;
      if c.fname = 'COLLECTION_ID' then
        stdio.put_line_buf('v_idx := ''Z#IX_''||v_tbl||''_COLL'';');
      else
        stdio.put_line_buf('select ''Z#IX_''||table_name||'''||s||'''||column_id into v_idx from dba_tab_columns where table_name=v_tbl and owner=v_own and column_name=v_col;');
      end if;
      if c.loaddata='0' then s:='*'||nvl(abs(c.stage),1); else s:=null; end if;
      stdio.put_line_buf('select freelists,trunc(initial_extent'||s||'/1024),trunc(initial_extent'||s||'/2048),tablespace_name,partitioned,');
      stdio.put_line_buf('  decode(ltrim(degree),''1'','' noparallel'',''default'','' parallel'','' parallel ''||ltrim(degree))');
      stdio.put_line_buf('  into v_free,v_init,v_next,v_ts,v_prt,v_degr from dba_indexes where index_name=''PK_''||v_tbl||''_ID'' and table_owner=v_own;');
      stdio.put_line_buf('if v_prt=''YES'' then');
      stdio.put_line_buf('for c in (select partition_name,freelists,trunc(initial_extent'||s||'/1024) ini,trunc(initial_extent'||s||'/2048) nxt,tablespace_name');
      stdio.put_line_buf('  from dba_ind_partitions where index_name=''PK_''||v_tbl||''_ID'' and index_owner=v_own order by partition_position desc');
      stdio.put_line_buf(') loop');
      stdio.put_line_buf('  v_free:=nvl(c.freelists,1); v_init:=nvl(c.ini,256); v_next:=nvl(c.nxt,v_init);');
      stdio.put_line_buf('  if v_sql is null then v_sql:='''||b||'''; v_prt:=''5''; else v_sql:='',''||v_sql; v_prt:=''0''; end if;');
      stdio.put_line_buf('  v_sql:=''');
      stdio.put_line_buf('  partition ''||c.partition_name||'' tablespace ''||c.tablespace_name||'' pctfree ''||v_prt||'' initrans 2 maxtrans 255');
      stdio.put_line_buf('    storage (pctincrease 0 minextents 1 maxextents unlimited');
      stdio.put_line_buf('    freelists ''||v_free||'' initial ''||v_init||''K next ''||v_next||''K )''||v_sql;');
      stdio.put_line_buf('end loop;');
      if c.loaddata='0' then s:=null; else s:=',KEY'; end if;
      stdio.put_line_buf('  v_sql:='''||s||') local (''||v_sql;');
      stdio.put_line_buf('else');
      stdio.put_line_buf('  v_free:=nvl(v_free,1); v_init:=nvl(v_init,1024); v_next:=nvl(v_next,v_init);');
      stdio.put_line_buf('  v_sql:='')');
      stdio.put_line_buf('    tablespace ''||v_ts||'' pctfree 5 initrans 2 maxtrans 255');
      stdio.put_line_buf('    storage (pctincrease 0 minextents 1 maxextents unlimited');
      stdio.put_line_buf('    freelists ''||v_free||'' initial ''||v_init||''K next ''||v_next||''K )'';');
      stdio.put_line_buf('end if;');
      if c.loaddata='0' then s:=null; else s:=' unique'; end if;
      stdio.put_line_buf('storage_utils.execute_sql(''create'||s||' index ''||v_idx||'' on ''||v_tbl||''(''||v_col||v_sql||''');
      stdio.put_line_buf('  '||p||l||' compute statistics'',v_idx,false,v_own);');
      stdio.put_line_buf('storage_utils.execute_sql(''alter index ''||v_idx||v_degr||'' logging'',''ALTER ''||v_idx,false,v_own);');
      stdio.put_line_buf('end;');
      stdio.put_line_buf('/'||chr(10));
    elsif c.prt_class is not null then
      stdio.put_line_buf(chr(10)||'prompt '||c.class_id);
      if c.loaddata='0' then s:='false';
      else if c.loaddata='1' then s:='true';
      else s:='null'; end if; end if;
      stdio.put_line_buf('exec dict_mgr.add_partition('''
        ||c.class_id||''',null,p_pipe_name=>:pip,p_build=>'||s||',p_ratio=>'||nvl(c.stage,0.5)
        ||',p_tspace=>'''||nvl(c.crt_user,'&&tstab')||''',p_idx_ts=>'''||nvl(c.mod_user,'&&tsidx')||''')');
    else
      stdio.put_line_buf(chr(10)||'prompt '||c.class_id);
      s := null;
      b := 'false';
      if c.loaddata='0' then
        s := ',p_mode=>1';
      elsif c.loaddata='1' then
        b := 'true';
      end if;
      if not c.param_group is null then
        i := null;
        begin
          i := c.param_group;
        exception when others then
          i := null;
        end;
        if i>=0 then
          s := ',p_id=>'||i||s;
        elsif i<0 and s is null then
          s := ',p_id=>'||(-i)||',p_mode=>4';
        end if;
      end if;
      if c.notes is null then
        stdio.put_line_buf('exec storage_mgr.reconcile_class_table('''
          ||c.class_id||''',true,:pip,'||b||','||nvl(abs(c.stage),0.9)||','''||nvl(c.crt_user,'&&tstab')
          ||''',p_idxtspace=>'''||nvl(c.mod_user,'&&tsidx')||''''||s||')');
      else
        stdio.put_line_buf('begin storage_mgr.reconcile_class_table('''
          ||c.class_id||''',true,:pip,'||b||','||nvl(abs(c.stage),0.9)||','''||nvl(c.crt_user,'&&tstab')
          ||''',p_idxtspace=>'''||nvl(c.mod_user,'&&tsidx')||''',p_condition=>');
        stdio.put_line_buf(''''||replace(c.notes,'''','''''')||''''||s||');');
        stdio.put_line_buf('end;');
        stdio.put_line_buf('/'||chr(10));
      end if;
    end if;
    :yyy := '1';
  end loop;
  if :yyy='1' then
    stdio.put_line_buf(chr(10));
  end if;
end;
/

select 'alter tablespace &&tstab coalesce;' from dual where :yyy='1';
select 'alter tablespace &&tsidx coalesce;' from dual where :yyy='1';

select 'prompt '||ct.class_id||chr(10)||'exec dict_mgr.add_partition('''
   ||ct.class_id||''',null,p_pipe_name=>:pip,p_build=>null,p_ratio=>0.5,p_tspace=>''&&tstab'',p_idx_ts=>''&&tsidx'')'
  from &&usertables ut, class_tables ct, class_partitions cp
 where ut.table_name=ct.table_name &&whereclause
   and ct.class_id = cp.class_id
   and cp.partition_position is null
   and nvl('&1','0') not in ('1','2','3')
   and not exists
 ( select 1 from project p where p.name=ct.class_id and p.type='UPGRADE' )
 order by ut.blocks desc, ct.class_id;

select 'prompt '||ct.class_id||chr(10)||'exec storage_mgr.reconcile_class_table('''
   ||ct.class_id||''',true,:pip,false,0.9,''&&tstab'',p_idxtspace=>''&&tsidx'')'
  from &&usertables ut, class_tables ct
 where ut.table_name=ct.table_name &&whereclause
   and :v_ver<5.0
   and nvl('&1','0') not in ('1','2','3')
   and ct.table_name like 'Z#%'
   and not exists
 ( select 1 from project p where p.name=ct.class_id and p.type='UPGRADE' )
   and not exists
 ( select 1 from class_partitions cp
    where cp.class_id=ct.class_id and cp.partition_position is null )
 order by ut.blocks desc, ct.class_id;

exec stdio.put_line_buf(chr(10))

select 'exec storage_mgr.add_dependencies('''||cr.parent_id||''','''||cr.child_id||''')'
  from project p, class_relations cr, class_partitions cp
 where cr.parent_id = cp.class_id
   and cp.partition_position is null
   and cr.distance>0 and :v_ver>=5.0
   and p.name = cp.class_id
   and p.type = 'UPGRADE'
   and ( '&1' in ('1','2','3') and p.build='&1'
     or nvl('&1','0') not in ('1','2','3') and nvl(p.build,0) not between 1 and 3 )
   and not exists
 ( select 1 from class_partitions cp1 where cp1.class_id=cr.child_id and cp1.partition_position is null )
union
select 'exec storage_mgr.add_dependencies('''||cr.parent_id||''','''||cr.child_id||''')'
  from project p, class_relations cr
 where cr.distance>0 and :v_ver>=5.0
   and p.name = cr.parent_id
   and p.type = 'UPGRADE'
   and ( '&1' in ('1','2','3') and p.build='&1'
     or nvl('&1','0') not in ('1','2','3') and nvl(p.build,0) not between 1 and 3 )
   and p.param_group is not null and p.fname is null
   and not exists
 ( select 1 from project p1 where p1.name=cr.child_id and p1.type='UPGRADE' )
;

prompt set timing off

