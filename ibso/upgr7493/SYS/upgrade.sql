set serveroutput on size 1000000

SET TERMOUT ON
ACCEPT OWNER PROMPT 'Enter IBSO OWNER schema name (IBS): '  default IBS
ACCEPT AUDIT PROMPT 'Enter AUDIT MANAGER schema name (AUDM): ' default AUDM

SET TERMOUT OFF
column yyy new_value log_file_name noprint
select 'sys_'||to_char(sysdate,'YYYYMMDD_hh24mi')||'.log' yyy from dual;
column xxx new_value audmgr noprint
select decode('&&AUDIT','SYS','AUDM','','AUDM','&&AUDIT') xxx from dual;
SET TERMOUT ON

spool &log_file_name

prompt Stop all background processes and press ENTER to continue...
pause

set timi on

@@UTILS/alt_sys_enable_restricted_session

prompt 
prompt * Try to stop jobs

exec &&OWNER..rtl.lock_stop
exec &&audmgr..aud_mgr.stop

exec dbms_lock.sleep(20)

prompt install SYS/SYSGRANT.SQL
@@SYS/SYSGRANT.SQL

spool &log_file_name append

@@UTILS/alt_sys_disable_restricted_session

prompt 
prompt * Try to start jobs
exec &&audmgr..aud_mgr.submit;

set timi off

spool off

exit
