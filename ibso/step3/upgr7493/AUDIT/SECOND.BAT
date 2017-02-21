@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   SECOND AudConnStr
@ECHO WHERE:
@ECHO   AudConnStr - Connect String To Audit OWNER (AUD schema)
@ECHO EXAMPLE:
@ECHO   SECOND AUD/AUD@ORCL
exit

:OK
@ECHO Creating audit schema objects...
sqlplus %1 @c_all load_aud_data %1
