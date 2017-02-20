@ECHO OFF
if "%1"=="" goto NOPARAM
if "%1"=="pause" goto NOPARAM
if not exist "%1" goto NOPARAM
GOTO OK

:NOPARAM
title Start monitor on pipes "DEBUG", "DEBUG0" ("DEBUG1", "DEBUG2", "DEBUG3")
@ECHO Start monitor on pipes "DEBUG", "DEBUG0"
@ECHO Start monitor on optional pipes "DEBUG1", "DEBUG2", "DEBUG3"
@ECHO   for parallel processes
if "%1"=="" exit
@ECHO   and press any key to continue...
pause
exit

:OK
if "%4"==""  goto DBG
if "%4"=="0" goto DBG
if "%4"=="1" goto DBG
if "%4"=="2" goto DBG
if "%4"=="3" goto DBG

title Starting monitor on pipe %4
start %1 %2 owner=%3 pipe=%4
exit

:DBG

title Starting monitor on pipes "DEBUG", "DEBUG0" ("DEBUG1", "DEBUG2", "DEBUG3")
sqlplus "%2" @utils/exit

@ECHO Starting monitor on pipe "DEBUG"...
start %1 %2 owner=%3 pipe=DEBUG

@ECHO Starting monitor on pipe "DEBUG0"...
start %1 %2 owner=%3 pipe=DEBUG0
if "%4"==""  exit
if "%4"=="0" exit

@ECHO Starting monitor on pipe "DEBUG1"...
start %1 %2 owner=%3 pipe=DEBUG1
if "%4"=="1" exit

@ECHO Starting monitor on pipe "DEBUG2"...
start %1 %2 owner=%3 pipe=DEBUG2
if "%4"=="2" exit

@ECHO Starting monitor on pipe "DEBUG3"...
start %1 %2 owner=%3 pipe=DEBUG3
exit
