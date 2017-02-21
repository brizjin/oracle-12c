set linesize 250
set pagesize 0
SET HEADING OFF
SET FEEDBACK OFF
alter session set nls_sort=binary;
spool getsys.log
select table_name,decode(substr(generated,1,1),'G','SYS$CONS<'||table_name||'>',constraint_name) name,status,
       decode(constraint_type,'R','FOREIGN '||decode(delete_rule,'NO ACTION',null,delete_rule),
              'P','PRIMARY','U','UNIQUE','CHECK') typ
  from project p, dba_constraints c
 where c.table_name=p.name and p.type='TABLE' and c.owner=p.owner
union
select table_name,decode(generated,'Y','SYS$IDX<'||table_name||'>',index_name) name,status, 'INDEX' typ
  from project p, dba_indexes i
 where i.table_name=p.name and p.type='TABLE' and i.owner=p.owner
union
select table_name,trigger_name name,status,
       substr(substr(trigger_type,1,instr(trigger_type,' '))||triggering_event,1,50) typ
  from project p, user_triggers t
 where t.table_name=p.name and p.type='TABLE'
order by 1,2;
spool off
