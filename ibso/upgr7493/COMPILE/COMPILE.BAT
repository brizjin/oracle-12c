@ECHO OFF
if NOT "%2"=="" goto OK

@ECHO USAGE:
@ECHO   COMPILE ConnStr Option [Path_to_Oramon]
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO   Option  - Number Value:
@ECHO      0 - Compiling all methods
@ECHO      1 - Compiling invalid methods
@ECHO      2 - Compiling all method interfaces
@ECHO      3 - Compiling invalid method interfaces
@ECHO      4 - Compiling all criteria
@ECHO      5 - Compiling invalid criteria
@ECHO     10 - Compiling classes (update_class_storage)
@ECHO     11 - Compiling class interfaces
@ECHO   Path_to_Oramon - Optional: full path to Oramon.exe utility
@ECHO EXAMPLE:
@ECHO    COMPILE IBS/IBS@ORCL 0
exit

:OK

set  SQL_PLUS=sqlplusw

%SQL_PLUS% -v
if %ERRORLEVEL%==0 goto START
set  SQL_PLUS=sqlplus

:START
cls

Title Compiling dictionary objects (%2)...
@ECHO Compiling dictionary objects (%2)...

if "%3"=="" goto RUNSQL
start %3 %1 pipe=DEBUG
start %3 %1 pipe=DEBUG1
start %3 %1 pipe=DEBUG2
start %3 %1 pipe=DEBUG3

:RUNSQL
sqlplus %1 @c_mth %2
start %SQL_PLUS% %1 @c_sql %2 1
start %SQL_PLUS% %1 @c_sql %2 2
start %SQL_PLUS% %1 @c_sql %2 3
sqlplus %1 @c_sql %2 0

rem exit
