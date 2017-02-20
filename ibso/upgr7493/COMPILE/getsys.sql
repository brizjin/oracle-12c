set linesize 250
set pagesize 0
alter session set nls_sort=binary;
spool getsys.log
select table_name,substr(decode(substr(generated,1,1),'G','SYS$CONS<'||table_name||'>',constraint_name),1,30) name,status,
       decode(constraint_type,'R','FOREIGN '||decode(delete_rule,'NO ACTION',null,delete_rule),
              'P','PRIMARY','U','UNIQUE','CHECK') typ
  from user_constraints
 where table_name not like 'Z#%' and table_name not like 'RC$%' and table_name not like 'BIN$%'
union
select table_name,substr(decode(generated,'Y','SYS$IDX<'||table_name||'>',index_name),1,30) name,status, 'INDEX' typ
  from user_indexes
 where table_name not like 'Z#%' and table_name not like 'RC$%' and table_name not like 'BIN$%'
union
select table_name,trigger_name name,status,
       substr(substr(trigger_type,1,instr(trigger_type,' '))||triggering_event,1,50) typ
  from user_triggers
 where table_name not like 'Z#%' and table_name not like 'RC$%' and table_name not like 'BIN$%'
order by 1,2;
spool off
