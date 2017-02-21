rem *********************************************************
rem Перекомпиляция инвалидных пакетов системы
rem (ALTER PACKAGE COMPILE BODY)
rem Запускается из-под SQL*Plus
rem *********************************************************
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
spool &oxxx..sql

select 'prompt '||object_name||chr(10)||'ALTER PACKAGE '||object_name||' COMPILE BODY;'
from user_objects where status='INVALID' and object_type='PACKAGE BODY' 
and object_name not like 'Z$%' and object_name not like 'Z#%' and object_name not like 'ZZ$%'
and object_name not like 'Z\_%' escape '\' 
order by object_name;

prompt commit;;
spool off
set termout on
spool &oxxx._pack_recomplie.log
prompt Протокол компиляции пакетов
select 'Started  compiling packages - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx.
@@plsql_optimize

select 'Finished compiling packages - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
host del &oxxx..sql
set feedback on
set heading on
--EXIT
