REM Not asking for any key!
@ECHO OFF

if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   PATCH_FS ConnStr
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO EXAMPLE:
@ECHO   PATCH_FS IBS/IBS@ORCL 
exit

:OK

title Change FS grants for OWNER_APPSRV...
@ECHO Change FS grants for OWNER_APPSRV...

sqlplus %1 @fs_grant.sql %1 ask