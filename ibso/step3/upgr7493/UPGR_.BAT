REM Not asking for any key!
@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   UPGR_ ConnStr [Path_to_Oramon] [/q]
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO   Path_to_Oramon - Optional: full path to Oramon.exe utility
@ECHO   /q - Optional: Quiet (silent) mode with no questions
@ECHO EXAMPLE:
@ECHO   UPGR_ IBS/IBS@ORCL
exit

:OK

set  SQL_PLUS=sqlplusw

%SQL_PLUS% -v
if %ERRORLEVEL%==0 goto START
set  SQL_PLUS=sqlplus

:START
cls
title STEP 0. Clear old logs
@ECHO STEP 0. Clear old logs. LOGs 'll be saved at LOG/
del /q LOG\*.*
del SQLLDR\*.log
del COMPILE\*.log
del COMPILE\*.out
del COMPILE\*.err
del COMPILE\*.del
del U_SOURCE\*.log
del U_SOURCE\*.out

title STEP 1. Change database objects...
@ECHO STEP 1. Change database objects...
if "%2"=="" goto UP_DEF
if "%2"=="/q" goto UP_Q1
if "%2"=="/Q" goto UP_Q1
if "%3"=="/q" goto UP_Q2
if "%3"=="/Q" goto UP_Q2
sqlplus %1 @UP not_strict %1 0 %2 ask
goto UP_CHK

:UP_Q2
sqlplus %1 @UP strict %1 0 %2 quiet
goto UP_CHK

:UP_Q1
sqlplus %1 @UP strict %1 0 pause quiet
goto UP_CHK

:UP_DEF
sqlplus %1 @UP not_strict %1 0 pause ask

:UP_CHK
IF NOT ERRORLEVEL 1 goto UP_OK
@ECHO Script up.sql finished with errors. Exiting...
EXIT

:UP_OK
copy *.log log\*
copy *.e?? log\*
del *.log
del *.e??
REM pause

title STEP 2. Updating sources for new kernel
@ECHO STEP 2. Updating sources for new kernel
cd u_source
start %SQL_PLUS% %1 @c_all
REM pause

title STEP 3. Compiling classes
@ECHO STEP 3. Compiling classes
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0'
cd ..\compile
start %SQL_PLUS% %1 @c_stor 0
sqlplus %1 @c_all

title STEP 4. Compiling methods
@ECHO STEP 4. Compiling methods
sqlplus %1 @c_mtd
start %SQL_PLUS% %1 @c_all1

title STEP 5. Patch for parser errors due to extended syntax
@ECHO STEP 5. Patch for parser errors due to extended syntax
cd ..\u_source
start %SQL_PLUS% %1 @c_after

title STEP 6. Compiling method interfaces
@ECHO STEP 6. Compiling method interfaces
cd ..\compile
sqlplus %1 @c_all2
cd ..
exit

