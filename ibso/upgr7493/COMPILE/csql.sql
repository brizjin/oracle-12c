rem *********************************************************
rem Перекомпиляция операций с трансляцией из PL/Plus в PL/SQL
rem Запускается из-под SQL*Plus
rem Запрашивает имя PIPE для вывода информации
rem Использует дополнительный скрипт U_METH.SQL
rem (в нем можно модифицировать условие выборки операций)
rem *********************************************************
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set verify off
set serveroutput on size 300000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;
set termout on
spool &oxxx.&1-&2..out
prompt Протокол компиляции
select 'Started  compilation - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx. &2
select 'Finished compilation - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off

set feedback on
set heading on

rem exit

