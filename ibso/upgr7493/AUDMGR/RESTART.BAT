@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   RESTART SysConnStr
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO EXAMPLE:
@ECHO   RESTART SYS/SYS@ORCL
exit

:OK
@ECHO Restarting auditor manager job...
sqlplus "%1 as sysdba" @upgrade\audmst
