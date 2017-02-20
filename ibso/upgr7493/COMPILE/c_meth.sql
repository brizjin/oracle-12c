rem *********************************************************
rem Перекомпиляция операций с трансляцией из PL/Plus в PL/SQL
rem Запускается из-под SQL*Plus
rem Запрашивает имя PIPE для вывода информации
rem Использует дополнительный скрипт U_METH.SQL
rem (в нем можно модифицировать условие выборки операций)
rem *********************************************************
set feedback off
set heading off
rem accept pipe_name char format a30 prompt 'Pipe Name [&&pipe_name]: ' default &&pipe_name
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
alter system flush shared_pool;
spool u_meth.log
@@u_meth
spool off
spool &oxxx..sql
@@u_buf
@@u_buf
@@u_buf
@@u_buf
@@u_buf
@@u_buf
@@u_buf
@@u_buf
@@u_buf
@@u_buf
spool off
set termout on
spool &oxxx..out
prompt Протокол компиляции операций
select 'Started  compiling methods - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx.
select 'Finished compiling methods - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
rem host del &oxxx..sql
set feedback on
set heading on
