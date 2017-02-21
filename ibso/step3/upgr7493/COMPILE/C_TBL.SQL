rem *********************************************************
rem Перестроение таблиц типов
rem Запускается из-под SQL*Plus
rem *********************************************************
rem set termout off
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
spool &1._tbl.log
prompt Протокол перестроения таблиц - подробности в PIPE DEBUG*
exec executor.setnlsparameters
select 'Started  rebuilding tables - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@@&1..tbl &2
select 'Finished rebuilding tables - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
set feedback on
set heading on

