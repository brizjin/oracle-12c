spool syslogoff.log
accept audit prompt 'Schema Name for AUDIT manager (AUDM):' default AUDM

prompt LOGOFF_TRIGGER
CREATE OR REPLACE
TRIGGER &&audit..LOGOFF_TRIGGER
BEFORE LOGOFF ON DATABASE
BEGIN
    &&audit..aud_mgr.logoff;
END;
/
sho err

spool off
exit

