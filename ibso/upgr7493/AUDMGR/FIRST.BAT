@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   FIRST SysConnStr
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO EXAMPLE:
@ECHO   FIRST SYS/SYS@ORCL
exit

:OK
@ECHO Deleting logs
del *.log
@ECHO Creating auditor manager schema...
sqlplus "%1 as sysdba" @upgrade/audminit
