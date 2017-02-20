rem *********************************************************
rem Сбор статистики по схеме
rem Запускается из-под SQL*Plus
rem *********************************************************
def pipe_name='DEBUG0'
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set serveroutput on size 300000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;

spool &oxxx..stt
prompt exec storage_utils.verbose := true
prompt exec storage_mgr.verbose := true
prompt exec storage_utils.verbose := true
prompt exec storage_mgr.pipe_name := '&&pipe_name'
prompt exec storage_utils.pipe_name := '&&pipe_name'
select 'alter session set sort_area_size=83886080;' from dual;
prompt set timing on
prompt

select 'prompt '||table_name||chr(10)||
  'exec storage_utils.analyze_object('''||table_name||''',null,''COMPUTE'',true,null,'''||user||''')'
  from user_tables o
 where (last_analyzed is null or last_analyzed < add_months(trunc(sysdate),-1) ) and
       (--object_name like 'EDOC%' or object_name like 'VFS%' or
       exists (select 1 from project p where p.name=o.table_name and p.type='TABLE'
                  and nvl(p.loaddata,'Y') not in ('S','T')
              )
       )
 order by table_name;

prompt set timing off
prompt
spool off

set termout on
spool &oxxx..log
prompt Протокол анализа таблиц
select 'Started  analyzing tables - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx..stt
select 'Finished analyzing tables - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
host del &oxxx..stt
set feedback on
set heading on

