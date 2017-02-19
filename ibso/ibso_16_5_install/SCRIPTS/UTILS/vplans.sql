-- Скрипт выгрузки планов запросов представлений в текстовые файлы.
--
-- Результатом работы скрипта является набор файлов с именами
-- <crit_short_name>.txt, в которых содержатся планы выполнения
-- соответствующих представлений <crit_short_name>.
--
-- Запускать скрипт из под владельца.
--
-- Все файлы складываются в папку из которой запускается sql*plus,
-- поэтому имеет смысл создать отдельную папку, поместить туда скрипт,
-- сделать ее текущей и запустить скрипт командой:
-- <ваша версия sql*plus> <connect_string> @vplans.sql
-- Например:
-- plus80w ins/ibs@cent @vplans.sql
--
-- В процессе работы создаются и удаляются:
-- 1) три вспомогательных скрипта: __xplanv__.sql, __xplan__.sql и __vplans__.sql
-- 2) таблица для выполнения explain plan. Ее имя задается макросом PLAN_TABLE,
--    по умолчанию это plan_table_for_views
--


set linesize 150
set pagesize 0
set verify off
set feedback off

def WIDTH=150
def LF=chr(10)

prompt Choose plan type to generate.
prompt
prompt [1] Generate verbose plans with optimizer statistics
prompt [2] Generate plans with minimal decoration to compare with diff
prompt *** Other choices will mean [2] ***

define CHOICE='2'
accept CHOICE char format a1 prompt 'Enter choice [&&CHOICE]: ' default &&CHOICE

prompt
prompt Choose table which will be used to generate plans.
prompt This table will be created and dropped.
prompt

def PLAN_TABLE=plan_table_for_views
accept PLAN_TABLE char format a100 prompt 'Enter plan table name [&&PLAN_TABLE]: ' default &&PLAN_TABLE

prompt
prompt Recreating plan table: &&PLAN_TABLE
set term off
drop table &&PLAN_TABLE;
set term on
create table &&PLAN_TABLE (
    statement_id    varchar2(30),
    timestamp       date,
    remarks         varchar2(80),
    operation       varchar2(30),
    options         varchar2(30),
    object_node     varchar2(128),
    object_owner    varchar2(30),
    object_name     varchar2(30),
    object_instance numeric,
    object_type     varchar2(30),
    optimizer       varchar2(255),
    search_columns  number,
    id              numeric,
    parent_id       numeric,
    position        numeric,
    cost            numeric,
    cardinality     numeric,
    bytes           numeric,
    other_tag       varchar2(255),
    partition_start varchar2(255),
    partition_stop  varchar2(255),
    partition_id    numeric,
    other           long,
    distribution    varchar2(30));

prompt Generating verbose script to explant plan
set term off
spool __xplanv__.sql
prompt     select rpad('-', &&WIDTH, '-') from dual
prompt union all
prompt     select rpad('| Operation', 58)||rpad('| Name', 51)||'|  Rows | Bytes|  Cost  | Pstart| Pstop |' from dual
prompt union all
prompt     select rpad('-', &&WIDTH, '-') from dual
prompt union all
prompt     select * from (
prompt         select /*+ no_merge */
prompt             rpad('| '||substr(lpad(' ',1*(level-1))||operation||
prompt                 decode(options, null,'',' '||options), 1, 57), 58, ' ')||'|'||
prompt             rpad(substr(object_name||' ',1, 49), 50, ' ')||'|'||
prompt             lpad(decode(cardinality,null,'  ',
prompt                 decode(sign(cardinality-1000), -1, cardinality||' ',
prompt                 decode(sign(cardinality-1000000), -1, trunc(cardinality/1000)||'K',
prompt                 decode(sign(cardinality-1000000000), -1, trunc(cardinality/1000000)||'M',
prompt                     trunc(cardinality/1000000000)||'G')))), 7, ' ') || '|' ||
prompt             lpad(decode(bytes,null,' ',
prompt                 decode(sign(bytes-1024), -1, bytes||' ',
prompt                 decode(sign(bytes-1048576), -1, trunc(bytes/1024)||'K',
prompt                 decode(sign(bytes-1073741824), -1, trunc(bytes/1048576)||'M',
prompt                     trunc(bytes/1073741824)||'G')))), 6, ' ') || '|' ||
prompt             lpad(decode(cost,null,' ',
prompt                 decode(sign(cost-10000000), -1, cost||' ',
prompt                 decode(sign(cost-1000000000), -1, trunc(cost/1000000)||'M',
prompt                     trunc(cost/1000000000)||'G'))), 8, ' ') || '|' ||
prompt             lpad(decode(partition_start, 'ROW LOCATION', 'ROWID',
prompt                 decode(partition_start, 'KEY', 'KEY', decode(partition_start,
prompt                 'KEY(INLIST)', 'KEY(I)', decode(substr(partition_start, 1, 6),
prompt                 'NUMBER', substr(substr(partition_start, 8, 10), 1,
prompt                 length(substr(partition_start, 8, 10))-1),
prompt                 decode(partition_start,null,' ',partition_start)))))||' ', 7, ' ')|| '|' ||
prompt             lpad(decode(partition_stop, 'ROW LOCATION', 'ROW L',
prompt                 decode(partition_stop, 'KEY', 'KEY', decode(partition_stop,
prompt                 'KEY(INLIST)', 'KEY(I)', decode(substr(partition_stop, 1, 6),
prompt                 'NUMBER', substr(substr(partition_stop, 8, 10), 1,
prompt                 length(substr(partition_stop, 8, 10))-1),
prompt                 decode(partition_stop,null,' ',partition_stop)))))||' ', 7, ' ')||'|' as plan
prompt         from &&PLAN_TABLE
prompt         start with id=0
prompt         connect by prior id = parent_id
prompt             and prior timestamp <= timestamp
prompt           order by id, position
prompt     )
prompt union all
prompt     select rpad('-', &&WIDTH, '-') from dual
prompt /
prompt
spool off
set term on

prompt Generating script to explant plan
set term off
spool __xplan__.sql
prompt     select * from (
prompt         select /*+ no_merge */
prompt             rpad('| '||substr(lpad(' ',1*(level-1))||operation||
prompt                 decode(options, null,'',' '||options), 1, 57), 58, ' ')||'|'||
prompt             rpad(substr(object_name||' ',1, 49), 50, ' ')||'|' as plan
prompt         from &&PLAN_TABLE
prompt         start with id=0
prompt         connect by prior id = parent_id
prompt             and prior timestamp <= timestamp
prompt           order by id, position
prompt     )
prompt /
prompt
spool off
set term on

prompt Generating script to gather plans
set term off
spool __vplans__.sql

select decode('&&CHOICE', '1', null, 'prompt '||class_id ||'.'||object_name||&&LF)||
	   'spool '||object_name||'.txt'||&&LF||
       decode('&&CHOICE', '1', 'prompt '||class_id ||'.'||object_name||&&LF, null)||
       'set term off'||&&LF||
	   'prompt '||&&LF||
       'explain plan into &&PLAN_TABLE for select * from '||object_name||';'||&&LF||
	   decode('&&CHOICE', '1', '@__xplanv__', '@__xplan__')||&&LF||
       'delete from &&PLAN_TABLE;'||&&LF||
       'set term on'||&&LF||
       'spool off'||&&LF
  from user_objects, criteria
 where object_name = short_name and status = 'VALID';

spool off
set term on

prompt
prompt Running script to gather plans:
@__vplans__

prompt
prompt Dropping plan table
drop table &&PLAN_TABLE;
prompt Deleting auxiliary scripts
host del __xplanv__.sql __xplan__.sql __vplans__.sql
exit

/*
cat vplans.txt | perl -ne "s/\|[^\|]+\|[^\|]+\|[^\|]+\|[^\|]+\|[^\|]+\|$/|/; print;" > no_cost.txt
*/
