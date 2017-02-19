rem *********************************************************
rem Ќепроинициализированные колонки-массивы
rem «апускаетс€ из-под SQL*Plus
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

spool c_coll_not_init_act.sql

select --'prompt *** '||table_name||chr(10)
'declare aa integer; begin SELECT count(1) into aa from '||table_name||' where '||COLUMN_NAME||' is null;'
||'if aa <> 0 then Dbms_OutPut.Put_Line('''||table_name||'.'||COLUMN_NAME||'=''||aa); end if; end; '||chr(10)||'/'
||chr(10)||' '
  from class_tab_columns 
 where base_class_id = 'COLLECTION'
   and deleted <> '1'
	order by class_id;

spool off
set termout on
spool c_coll_not_init_act.log
prompt _ѕротокол выборки непроинициализированных колонок-массивов
select 'Started  - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@c_coll_not_init_act.sql
select 'Finished - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
prompt _ѕротокол выборки непроинициализированных колонок-массивов
spool off
host del c_coll_not_init_act.sql
set feedback on
set heading on
EXIT
