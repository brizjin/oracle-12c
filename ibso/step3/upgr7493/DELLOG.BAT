REM Not asking for any key!
@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   DELLOG Owner
@ECHO WHERE:
@ECHO   Owner - IB System Object Owner Schema name
@ECHO EXAMPLE:
@ECHO   DELLOG IBS
exit

:OK
@ECHO Deleting all logs
del *.log
del *.dmp
del LOG\*.*
del AUDIT\*.log
del PATCH\LOG\*.log
del AUDMGR\*.log
del SQLLDR\*.log
del COMPILE\*.log
del COMPILE\*.out
del COMPILE\*.e??
del COMPILE\*.del
del COMPILE\%1.sql
del COMPILE\*.tbl
del U_SOURCE\*.log
del U_SOURCE\*.out

