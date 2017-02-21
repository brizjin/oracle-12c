@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   SEGMENT_TABLES ConnStr
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO EXAMPLE:
@ECHO   SEGMENT_TABLES IBS/IBS@ORCL 
exit

:OK

title Change database objects...
@ECHO Change database objects...

sqlplus %1 @segment_tables