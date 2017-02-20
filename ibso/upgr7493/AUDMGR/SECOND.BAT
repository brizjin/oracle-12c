@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   SECOND SysConnStr
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO EXAMPLE:
@ECHO   SECOND SYS/SYS@ORCL
exit

:OK
@ECHO Creating auditor manager schema objects...
sqlplus "%1 as sysdba" @upgrade\audm
