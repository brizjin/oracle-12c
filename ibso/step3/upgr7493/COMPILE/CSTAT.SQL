rem *********************************************************
rem Сбор статистики по схеме
rem Запускается из-под SQL*Plus
rem *********************************************************
column xxx new_value pause_cmd noprint
select nvl('&1','rem') xxx from dual;
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
prompt exec storage_utils.verbose:=true
prompt exec storage_utils.pipe_name:='debug'
prompt exec storage_mgr.verbose:=true
prompt exec storage_mgr.pipe_name:='debug'
select 'prompt '||object_name||chr(10)||'exec part_mgr.analyze_object('''||object_name||''')'
  from user_objects
 where object_type='TABLE'
 order by object_name;
spool off
spool &oxxx..pse
prompt prompt optional pause before start of analyzing tables
prompt &&pause_cmd
prompt
spool off
set termout on
@&oxxx..pse
set timing on
spool &oxxx..log
prompt Протокол анализа таблиц
select 'Started  analyzing tables - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx..stt
select 'Finished analyzing tables - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
host del &oxxx..stt
host del &oxxx..pse
set feedback on
set heading on
set timing off
