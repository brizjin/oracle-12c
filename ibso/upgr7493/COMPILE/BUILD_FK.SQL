prompt creating cascade constraints
exec storage_utils.verbose := true;
exec storage_utils.pipe_name := 'DEBUG';
exec storage_mgr.verbose := true;
exec storage_mgr.pipe_name := 'DEBUG';

declare
    t "CONSTANT".refstring_table;
begin
    storage_utils.verbose := true;
    storage_utils.pipe_name := 'DEBUG';
    storage_mgr.verbose := true;
    storage_mgr.pipe_name := 'DEBUG';
    storage_utils.WS('Creating cascade constraints...');
    select /*+ INDEX_ASC(cr UNQ_CLS_REL_CHLD_DIST) */
           t1.class_id
      bulk collect into t
      from class_tables t2,class_tables t1, class_relations cr
     where cr.distance = 1
       and cr.child_id = t1.class_id
       and cr.parent_id= t2.class_id
       and nvl(t1.param_group,'X')<>'PARTITION'
       and nvl(t2.param_group,'X')<>'PARTITION'
       and not exists(
         select 1 from dba_constraints uc
          where uc.table_name = t1.table_name
            and uc.owner = nvl(t1.owner,inst_info.gowner)
            and uc.constraint_type = 'R'
            and uc.r_owner = nvl(t2.owner,inst_info.gowner)
            and uc.r_constraint_name = 'PK_'||t2.table_name||'_ID'
                     )
     order by cr.child_id;
    for i in 1..t.count loop
      storage_mgr.create_fk_by_objid(t(i));
    end loop;
    storage_utils.WS('Creating cascade constraints finished.');
end;
/

prompt reconstructing cascade constraints
declare
    t "CONSTANT".refstring_table;
begin
    storage_utils.verbose := true;
    storage_utils.pipe_name := 'DEBUG';
    storage_mgr.verbose := true;
    storage_mgr.pipe_name := 'DEBUG';
    storage_utils.WS('Reconstructing cascade constraints...');
    select /*+ INDEX_ASC(cr UNQ_CLS_REL_CHLD_DIST) */
           t1.class_id
      bulk collect into t
      from dba_constraints uc, class_tables t2,class_tables t1, class_relations cr
     where cr.distance = 1
       and cr.child_id = t1.class_id
       and cr.parent_id= t2.class_id
       and nvl(t1.param_group,'X')<>'PARTITION'
       and nvl(t2.param_group,'X')<>'PARTITION'
       and uc.table_name = t1.table_name
       and uc.owner = nvl(t1.owner,inst_info.gowner)
       and uc.constraint_type = 'R'
       and uc.r_owner = nvl(t2.owner,inst_info.gowner)
       and uc.r_constraint_name = 'PK_'||t2.table_name||'_ID'
       and uc.delete_rule = 'CASCADE'
     order by cr.child_id;
    for i in 1..t.count loop
      storage_mgr.create_fk_by_objid(t(i));
    end loop;
    storage_utils.WS('Reconstructing cascade constraints finished.');
end;
/

