prompt building indexes and constraints
exec dbms_session.reset_package
exec executor.setnlsparameters
alter session set sort_area_size=83886080;
alter session enable parallel ddl;

declare
  cls varchar2(16);
  cl  varchar2(16);
  cnt pls_integer := 0;
  pip varchar2(200) := nvl('&&pipename','storage$'||USER);
  par varchar2(100) := '&1';
  stp varchar2(100);
  b   boolean;
  b1  number;
  b2  number;
  tbl rtl.refstring_table;
  v_module  varchar2(100);
  v_action  varchar2(100);
  procedure processing is
  begin
   storage_mgr.pipe_name := pip;
   storage_utils.pipe_name := pip;
   stdio.setup_pipes(stp,pip,-1,100000);
   for n in 1..cnt loop
    if method.check_stop_flag(stp) then
      stdio.put_line_pipe('*** '||n||'.'||sqlerrm(-1013));
      exit;
    end if;
    cls := tbl(n);
    stdio.put_line_pipe(cls||' - '||n||'/'||cnt);
    storage_mgr.create_indexes(cls,1,0);
    cl := storage_mgr.is_partitioned(cls);
    if cl = '0' then
      select count(1) into cl from project where name=cls and type='UPGRADE' and param_group is not null;
    end if;
    storage_mgr.create_constraints(cls,cl<>'0');
   end loop;
  end;
begin
  storage_mgr.verbose := true;
  storage_utils.verbose := true;
  stp := Inst_Info.Owner||'.PROCESS_INDEXES';
  b := method.check_stop_flag(stp);
  dbms_application_info.read_module( v_module, v_action );
  dbms_application_info.set_module( v_module, to_char(sysdate,'HH24:MI:')||'NNFKIDX '||par );
if par in ('1','2','3') then
  pip:= pip||par;
  b1 := par;
  for c in (
    select distinct p.ord,p.name
      from class_tab_columns ctc, class_tables ct, project p
     where ct.class_id=ctc.class_id and ctc.deleted='0'
       and p.name=ct.class_id and p.type='UPGRADE'
       and (p.build=b1 and (p.owner is null or p.owner not in ('0','1','2','3'))
            or p.owner=par)
       and ( ctc.base_class_id='COLLECTION'
          or ctc.column_name = 'COLLECTION_ID'
          or ctc.base_class_id='REFERENCE' and not exists
             (select 1 from classes cl
               where cl.id=ctc.target_class_id
                 and (kernel='1' or entity_id='KERNEL')
             )
           )
     order by 1,2
           )
  loop
    cnt := cnt+1;
    tbl(cnt) := c.name;
  end loop;
  processing;
  delete from project where type like 'UPGRADE%' and build=b1;
elsif par like '-__' then
  pip:= pip||'0';
  b1 := substr(par,2,1);
  b2 := substr(par,3,1);
  for c in (
    select distinct ct.class_id
      from class_tab_columns ctc, class_tables ct
     where ct.class_id=ctc.class_id and ctc.deleted='0'
       and not exists
        ( select 1 from project p
           where p.name=ct.class_id and p.type='UPGRADE'
             and (nvl(p.build,0) between b1 and b2 and (p.owner is null or p.owner not in ('0','1','2','3'))
                  or p.owner between to_char(b1) and to_char(b2))
        )
       and ( ctc.base_class_id='COLLECTION'
          or ctc.column_name = 'COLLECTION_ID'
          or ctc.base_class_id='REFERENCE' and not exists
             (select 1 from classes cl
               where cl.id=ctc.target_class_id
                 and (kernel='1' or entity_id='KERNEL')
             )
           )
     order by 1
           )
  loop
    cnt := cnt+1;
    tbl(cnt) := c.class_id;
  end loop;
  processing;
  delete from project where type like 'UPGRADE%' and nvl(build,0) not between b1 and b2;
else
  pip:= pip||'0';
  for c in (
    select distinct ct.class_id
      from class_tab_columns ctc, class_tables ct
     where ct.class_id=ctc.class_id and ctc.deleted='0'
       and ( ctc.base_class_id='COLLECTION'
          or ctc.column_name = 'COLLECTION_ID'
          or ctc.base_class_id='REFERENCE' and not exists
             (select 1 from classes cl
               where cl.id=ctc.target_class_id
                 and (kernel='1' or entity_id='KERNEL')
             )
           )
     order by 1
           )
  loop
    cnt := cnt+1;
    tbl(cnt) := c.class_id;
  end loop;
  processing;
  delete from project where type like 'UPGRADE%';
end if;
  commit;
  dbms_application_info.set_module( v_module, v_action );
end;
/

