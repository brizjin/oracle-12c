rem *********************************************************
rem Удаление пользовательских сессий
rem (ALTER SYSTEM KILL SESSION)
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
select 'prompt deleting '||s.osuser||' - '||s.username||' - '||s.module||chr(10)||
 'ALTER SYSTEM KILL SESSION '''||s.SID||','||s.SERIAL#||''';'
  from v$session s, rtl_users u
 where s.username=u.ora_user
   and (s.audsid>0 and s.audsid=u.id or s.audsid=0 and s.client_info=to_char(-u.id));
spool off
set termout on
spool &oxxx._del.log
@&oxxx.
spool off
host del &oxxx..sql
set feedback on
set heading on
