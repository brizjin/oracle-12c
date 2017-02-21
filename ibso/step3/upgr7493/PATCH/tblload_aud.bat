@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   TBLLOAD ConnStr
@ECHO WHERE:
@ECHO   AudConnStr - Connect String To Audit OWNER (AUD schema)
@ECHO EXAMPLE:
@ECHO   TBLLOAD AUD/AUD@ORCL
exit

:OK

cd ..\SQLLDR

title STEP 0. Clear old logs.
@ECHO STEP 0. Clear old logs.
del aud_*.log
del aud_*.bad

title STEP 1. Loading Data Into Kernel tables...
@ECHO STEP 1. Loading Data Into Kernel tables...

sqlldr %1 MES_AUD.CTL LOG=aud_mes_aud.log BAD=aud_mes_aud.bad ERRORS=100000

cd ..\PATCH
