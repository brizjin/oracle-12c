prompt building indexes and constraints
exec executor.setnlsparameters

declare
  cls varchar2(16) := chr(1);
  cl  varchar2(16);
  cnt pls_integer;
  n   pls_integer := 0;
  pip varchar2(200) := nvl('&&pipename','storage$'||USER);
begin
  storage_mgr.pipe_name := pip;
  storage_mgr.verbose := true;
  select count(distinct ct.class_id) into cnt
    from class_tab_columns ctc, class_tables ct
   where ct.class_id=ctc.class_id
     and ctc.deleted='0'
     and ( ctc.base_class_id='COLLECTION'
        or ctc.column_name = 'COLLECTION_ID'
        or ctc.base_class_id='REFERENCE' and not exists
           (select 1 from classes cl
             where cl.id=ctc.target_class_id
               and (kernel='1' or entity_id='KERNEL')
           )
         );
  loop
    cl:=null;
    for c in (
      select distinct ct.class_id from class_tab_columns ctc, class_tables ct
       where ct.class_id>cls
         and ct.class_id=ctc.class_id
         and ctc.deleted='0'
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
      cl := c.class_id; exit;
    end loop;
    exit when cl is null;
    cls := cl;
    n := n+1;
    stdio.put_line_pipe(cls||' - '||n||'/'||cnt,pip);
    storage_mgr.create_indexes(cls,1);
    storage_mgr.create_constraints(cls);
  end loop;
end;
/
