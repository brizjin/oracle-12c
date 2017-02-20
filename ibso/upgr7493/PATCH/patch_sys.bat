@ECHO OFF
if "%1"=="" goto NOPARAM
GOTO OK

:NOPARAM
@ECHO USAGE:
@ECHO   PATCH_SYS SysConnStr [/q]
@ECHO WHERE:
@ECHO   SysConnStr - Connect String To OWNER of DATABASE (SYS schema)
@ECHO   /q - Optional: Quiet (silent) mode with no questions
@ECHO EXAMPLE:
@ECHO   PATCH_SYS SYS/SYS@ORCL
exit

:OK

title Change database objects...
@ECHO Change database objects...

if "%2"=="/q" goto UP_Q1
if "%2"=="/Q" goto UP_Q1

sqlplus "%1 as sysdba" @SYS\patch.sql ask

goto END

:UP_Q1
sqlplus "%1 as sysdba" @SYS\patch.sql quiet

:END

copy *.log log\*
del *.log
