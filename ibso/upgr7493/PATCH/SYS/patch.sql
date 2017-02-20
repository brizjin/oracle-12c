set serveroutput on size 1000000

@@..\settings
@@UTILS\patch_settings

def OWNER='&&IBSO_OWNER'
def AUDIT='&&AUDM_OWNER'

SET TERMOUT OFF
column yyy new_value log_file_name noprint
select 'LOG\sys_'||to_char(sysdate,'YYYYMMDD_hh24mi')||'.log' yyy from dual;
column xxx new_value ask noprint
select decode('&1','quiet','..\UTILS\dummy','ask_pars') xxx from dual;
SET TERMOUT ON

@@&&ask

SET TERMOUT OFF
column xxx new_value audmgr noprint
select decode('&&AUDIT','SYS','AUDM','','AUDM','&&AUDIT') xxx from dual;
SET TERMOUT ON

spool &log_file_name

prompt  
prompt -------------------------------------------------------------------------------- 

prompt Начало установки патча
prompt 

set timi on

@@..\UTILS\alt_sys_enable_restricted_session

prompt 

prompt * Try to stop jobs

exec &&OWNER..rtl.lock_stop
exec &&audmgr..aud_mgr.stop

exec dbms_lock.sleep(20)

spool off

spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------


prompt install ..\SYS\SYSGRANT.SQL
@@..\SYS\SYSGRANT.SQL

spool off

spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

@@..\UTILS\alt_sys_disable_restricted_session

prompt 

prompt * Try to start jobs
exec &&audmgr..aud_mgr.submit;

set timi off

spool off

exit
