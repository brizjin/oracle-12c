@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   THIRD SysConnStr
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO EXAMPLE:
@ECHO   THIRD SYS/SYS@ORCL
exit

:OK
@ECHO Creating LOGON DATABASE TRIGGER...
sqlplus "%1 as sysdba" @packages/syslogon
