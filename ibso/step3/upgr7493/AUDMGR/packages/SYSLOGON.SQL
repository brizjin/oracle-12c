spool syslogon.log
define audit = AUDM
prompt LOGON_TRIGGER
CREATE OR REPLACE 
TRIGGER &&audit..LOGON_TRIGGER
AFTER LOGON ON DATABASE
BEGIN
    &&audit..aud_mgr.init_contexts;
END;
/
sho err

rem @@updusers

spool off
exit

