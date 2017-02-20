REM Not asking for any key!
@ECHO OFF

if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   PATCH_IBS ConnStr [/q]
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO   /q - Optional: Quiet (silent) mode with no questions
@ECHO EXAMPLE:
@ECHO   PATCH_IBS IBS/IBS@ORCL 
exit

:OK

title Change database objects...
@ECHO Change database objects...

if "%2"=="/q" goto UP_Q1
if "%2"=="/Q" goto UP_Q1

sqlplus %1 @IBS\patch.sql %1 ask
goto END

:UP_Q1
sqlplus %1 @IBS\patch.sql %1 quiet

:END

copy *.log log\*
del *.log
