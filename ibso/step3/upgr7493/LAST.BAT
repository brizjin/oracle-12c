@ECHO OFF
if "%1"=="" goto NOPARAM
GOTO OK

:NOPARAM
@ECHO USAGE:
@ECHO   LAST SysConnStr
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO EXAMPLE:
@ECHO   LAST SYS/SYS@ORCL
exit

:OK
cls
title Restarting auditor manager job...
CD AUDMGR
CALL RESTART  %1
CD ..
exit
