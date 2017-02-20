spool syslogon.log
accept audit prompt 'Schema Name for AUDIT manager (AUDM):' default AUDM
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

