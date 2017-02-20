REM Not asking for any key!
@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   UPGR ConnStr [Processes] [Path_to_Oramon]
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO   Processes - Optional: Number of additional parallel processes
@ECHO               for rebuilding tables (maximum 3)
@ECHO   Path_to_Oramon - Optional: full path to Oramon.exe utility
@ECHO EXAMPLE:
@ECHO   UPGR IBS/IBS@ORCL

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
if "%3"=="" goto UP_2
sqlplus %1 @UP strict %1 %2 %3 ask
goto UP_CHK

:UP_2
if "%2"==""  goto UP_DEF
if "%2"=="0" goto UP_DEF
if "%2"=="1" goto UP_1
if "%2"=="2" goto UP_1
if "%2"=="3" goto UP_1
if not exist "%2" goto UP_DEF
sqlplus %1 @UP strict %1 0 %2 ask
goto UP_CHK

:UP_1
sqlplus %1 @UP strict %1 %2 pause ask
goto UP_CHK

:UP_DEF
sqlplus %1 @UP strict %1 0 pause ask

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

title STEP 3. Rebuilding class tables
@ECHO STEP 3. Rebuilding class tables
cd ..\compile
if "%2"=="1" goto PROC1
if "%2"=="2" goto PROC2
if "%2"=="3" goto PROC3
goto PROC0

:PROC3
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0', 'DEBUG1', 'DEBUG2', 'DEBUG3'
@ECHO Optional pause before start of rebuilding tables
pause
start %SQL_PLUS% %1 @c_reb 1 1
start %SQL_PLUS% %1 @c_reb 2 2
start %SQL_PLUS% %1 @c_reb 3 3
goto CONT3

:PROC2
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0', 'DEBUG1', 'DEBUG2'
@ECHO Optional pause before start of rebuilding tables
pause
start %SQL_PLUS% %1 @c_reb 1 1
start %SQL_PLUS% %1 @c_reb 2 2
goto CONT2

:PROC1
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0', 'DEBUG1'
@ECHO Optional pause before start of rebuilding tables
pause
start %SQL_PLUS% %1 @c_reb 1 1
goto CONT1

:PROC0
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0'
sqlplus %1 @c_reb 1 0

:CONT1
sqlplus %1 @c_reb 2 0

:CONT2
sqlplus %1 @c_reb 3 0

:CONT3
sqlplus %1 @c_reb 0 0

if "%2"=="1" goto CONTX
if "%2"=="2" goto CONTX
if "%2"=="3" goto CONTX
goto CONT

:CONTX
title Optional pause after finish of rebuilding tables
@ECHO Optional pause after finish of rebuilding tables
pause

:CONT
sqlplus %1 @c_reb X 0

title STEP 4. Compiling classes
@ECHO STEP 4. Compiling classes

if "%2"=="1" goto STOR1
if "%2"=="2" goto STOR2
if "%2"=="3" goto STOR3
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0'
start %SQL_PLUS% %1 @c_stor 0
goto ALL

:STOR1
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0', 'DEBUG1'
start %SQL_PLUS% %1 @c_stor 1
start %SQL_PLUS% %1 @c_stor -11
goto ALL

:STOR2
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0', 'DEBUG1', 'DEBUG2'
start %SQL_PLUS% %1 @c_stor 1
start %SQL_PLUS% %1 @c_stor 2
start %SQL_PLUS% %1 @c_stor -12
goto ALL

:STOR3
@ECHO Run monitor on pipes 'DEBUG', 'DEBUG0', 'DEBUG1', 'DEBUG2', 'DEBUG3'
start %SQL_PLUS% %1 @c_stor 1
start %SQL_PLUS% %1 @c_stor 2
start %SQL_PLUS% %1 @c_stor 3
start %SQL_PLUS% %1 @c_stor -13

:ALL
sqlplus %1 @c_all

title STEP 5. Compiling methods
@ECHO STEP 5. Compiling methods
sqlplus %1 @c_mtd
start %SQL_PLUS% %1 @c_all1

title STEP 6. Patch for parser errors due to extended syntax
@ECHO STEP 6. Patch for parser errors due to extended syntax
cd ..\u_source
start %SQL_PLUS% %1 @c_after

title STEP 7. Compiling method interfaces
@ECHO STEP 7. Compiling method interfaces
cd ..\compile
sqlplus %1 @c_all2
cd ..
exit

