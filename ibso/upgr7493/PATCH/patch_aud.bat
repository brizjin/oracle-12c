@ECHO OFF
if "%1"=="" goto NOPARAM
GOTO OK

:NOPARAM
@ECHO USAGE:
@ECHO   PATCH_AUD AudConnStr [/q]
@ECHO WHERE:
@ECHO   AudConnStr - Connect String To Audit OWNER (AUD schema)
@ECHO   /q - Optional: Quiet (silent) mode with no questions
@ECHO EXAMPLE:
@ECHO   PATCH_AUD AUD/AUD@ORCL
exit


:OK

title Change database objects...
@ECHO Change database objects...

if "%2"=="/q" goto UP_Q1
if "%2"=="/Q" goto UP_Q1

sqlplus %1 @AUD\patch.sql %1 ask
goto END

:UP_Q1
sqlplus %1 @AUD\patch.sql %1 quiet

:END

copy *.log log\*
del *.log

