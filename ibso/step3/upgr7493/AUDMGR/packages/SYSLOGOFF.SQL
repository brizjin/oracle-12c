spool syslogoff.log
define audit = AUDM

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

