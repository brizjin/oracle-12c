SET SERVEROUTPUT ON

spool audmst.log

@..\settings

Prompt Restarting auditor manager job...
ACCEPT audit   PROMPT 'Enter AUDIT MANAGER schema name (&&AUDM_OWNER):' default &&AUDM_OWNER
ACCEPT ibso    PROMPT 'Enter IBSO OWNER schema name (&&IBSO_OWNER) :'  default &&IBSO_OWNER

SET TERMOUT OFF
column xxx new_value audmgr noprint
select decode('&&audit','SYS','AUDM','','AUDM','&&audit') xxx from dual;
SET TERMOUT ON

exec &&audmgr..aud_mgr.stop;
exec &&audmgr..aud_mgr.stop;

exec dbms_lock.sleep(60)

alter trigger &&audmgr..logon_trigger compile;
alter trigger &&audmgr..logoff_trigger compile;
exec &&audmgr..aud_mgr.get_settings(true);
exec &&audmgr..aud_mgr.add_owner('&&ibso');

exec &&audmgr..aud_mgr.submit;

spool off
exit
