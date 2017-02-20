@ECHO OFF
if "%1"=="" goto NOPARAM
if "%2"=="" goto NOPARAM
GOTO OK

:NOPARAM
@ECHO USAGE:
@ECHO   FIRST SysConnStr AudConnStr [Option]
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO   AudConnStr - Connect String To Audit OWNER (AUD schema)
@ECHO   Option - Optional: if specified then start UPGRADE AUD
@ECHO            through Audit menu options.
@ECHO EXAMPLE:
@ECHO   FIRST SYS/SYS@ORCL AUD/AUD@ORCL
exit

:OK
cls

if not exist PATCH\UTILS\check_install_patch.sql goto START

title Checking version of IB System Object..
@ECHO Checking version of IB System Object..

sqlplus "%1 as sysdba" @PATCH/UTILS/check_install_patch
IF ERRORLEVEL 1 goto PATCHNO

@ECHO.
@ECHO.
@ECHO Current version of IB System Object and Auditor Schema allows run patch...
set /p answer=Continue run upgrade [YES/NO], default YES:
IF "%answer%" == "NO" goto END
IF "%answer%" == "N" goto END
IF "%answer%" == "No" goto END
IF "%answer%" == "no" goto END
IF "%answer%" == "n" goto END

:PATCHNO
@ECHO.
@ECHO.
@ECHO Current version of IB System Object and Auditor Schema not allows run patch.
@ECHO Continue run upgrade...
@ECHO.

:START
title Adding system grants..
@ECHO Adding system grants..
del *.log
sqlplus "%1 as sysdba" @SYS/upgrade
@ECHO Creating FIO/HASH libraries
sqlplus "%1 as sysdba" @utils/c_sys

title Creating auditor schema...
@ECHO Creating auditor schema...
CD AUDIT
CALL FIRST  %1
IF NOT ERRORLEVEL 1 goto AUDOK
@ECHO Script first.bat finished with errors. Skipping second.bat...
@GOTO AUDEND
:AUDOK
@ECHO Creating auditor schema objects...
if "%3"=="" goto AUDAUTO
CALL MENU %2
@GOTO AUDEND
:AUDAUTO
CALL SECOND %2
:AUDEND
CD ..

title Creating auditor manager schema...
@ECHO Creating auditor manager schema...
CD AUDMGR
CALL FIRST  %1
IF NOT ERRORLEVEL 1 goto AUDMOK
@ECHO Script first.bat finished with errors. Skipping second.bat and third.bat...
@GOTO AUDMERR
:AUDMOK
CALL SECOND %1
CALL THIRD %1
:AUDMERR
CD ..

:END
@ECHO End..
exit

