rem *********************************************************
rem Удаляет неиспользуемые в словаре системы пакеты
rem интерфейсов классов, интерфейсов операций и самих операций
rem Чистит SOURCES от неиспользуемых текстов операций.
rem Запускается из-под SQL*Plus
rem Использует дополнительный скрипт U_CLEAR.SQL
rem *********************************************************
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set serveroutput on size 1000000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;
spool &oxxx..drp
@@u_clear
spool off
set termout on
spool &oxxx..del
prompt Протокол удаления пакетов
select 'Started  deleting packages - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx..drp
select 'Finished deleting packages - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
set feedback on

prompt deleting from sources
delete from sources s where not exists
  (select 1 from methods m where m.id=s.name);
commit;

prompt deleting from errors
delete from errors where nvl(type,'X')<>'VIEW' and not exists
  (select 1 from methods where id=method_id);
delete from errors where type='VIEW' and not exists
  (select 1 from criteria where id=method_id);
commit;

prompt deleting from dependencies
delete from dependencies where referencing_type not in ('C','V') and not exists
  (select 1 from methods where id=referencing_id);
commit;
--delete from dependencies where referenced_type not in ('A','C','V') and not exists
--  (select 1 from methods where id=referenced_id); -- packages
--commit;
delete from dependencies where referencing_type='V' and not exists
  (select 1 from criteria where id=referencing_id);
commit;
delete from dependencies where referenced_type='V' and not exists
  (select 1 from criteria where id=referenced_id);
commit;
delete from dependencies where referencing_type='C' and not exists
  (select 1 from classes where id=referencing_id);
commit;
--delete from dependencies where referenced_type in ('A','C') and not exists
--  (select 1 from classes where id=referenced_id); -- tables/views/types
--commit;

prompt deleting from topics
delete topics t where topic='DESCRIPTION' and not exists
  (select 1 from lraw l where l.id=t.id);
commit;
delete topics t where class='CLASS' and not exists
  (select 1 from classes c where c.id=t.owner);
commit;
delete topics t where topic='CLASS' and not exists
  (select 1 from classes c where c.id=t.id);
commit;
delete topics t where topic='TOPIC' and not exists
  (select 1 from topics c where c.class='TOPIC' and c.owner=t.id);
commit;
delete topics t where class='METHOD' and not exists
  (select 1 from methods m where m.id=t.owner);
commit;
delete topics t where class='CRITERION' and not exists
  (select 1 from criteria m where m.id=t.owner);
commit;

prompt deleting columns definitions
delete from class_tab_columns c where not exists
  (select 1 from class_tables t where t.class_id=c.class_id);

delete from class_rec_fields f where exists
  (select 1 from class_tables t where t.class_id=f.class_id);

delete from class_part_columns c where not exists
  (select 1 from class_partitions p
    where p.class_id=c.class_id and p.partition_position=c.partition_position);
commit;

exec patch_tool.clear_methods;

spool off
host del &oxxx..drp
set heading on
