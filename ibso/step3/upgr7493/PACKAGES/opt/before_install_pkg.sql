set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set serveroutput on size 10000000
set linesize 8000
set arraysize 1
set trimspool on
set trimout on
set timi off

spool before_install_pkg_script.sql

select 
'prompt run action('||t.id||')'||chr(13)||chr(13)||
'prompt '|| t.action_name ||chr(13)||chr(13)||
'begin '||chr(13)||
t.script ||chr(13)||
'update update_journal set Status = 1 where id = '||t.id||';' ||chr(13)||
'commit;'||chr(13)||
'end;'||chr(13)||
'/'||chr(13)||chr(13)
from UPDATE_JOURNAL t
where nvl(t.status,'0') = '0' and nvl(t.is_before,'0') = '1' 
order by t.priority, t.id;

spool off

set timi on
set termout on
set feedback on
set heading on

spool LOG\ibs_before_install_pkg.log 
prompt Выполнение скриптов до обновления пакетов

@before_install_pkg_script

host del before_install_pkg_script.sql

spool off

