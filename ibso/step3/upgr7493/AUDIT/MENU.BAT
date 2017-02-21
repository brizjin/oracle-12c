@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   MENU AudConnStr
@ECHO WHERE:
@ECHO   AudConnStr - Connect String To Audit OWNER (AUD schema)
@ECHO EXAMPLE:
@ECHO   MENU AUD/AUD@ORCL
exit

:OK
@ECHO Creating audit schema objects...
sqlplus %1 @c_menu load_aud_data %1

