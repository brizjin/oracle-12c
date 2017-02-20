@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   REVERSE_IDX AudConnStr
@ECHO WHERE:
@ECHO   AudConnStr - Connect String To Audit OWNER (AUD schema)
@ECHO EXAMPLE:
@ECHO   REVERSE_IDX AUD/AUD@ORCL
exit

:OK
@ECHO Alter index osh_obj_id...
sqlplus %1 @reverse_idx_osh_obj_id
