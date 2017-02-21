@ECHO OFF
if NOT "%1"=="" goto OK

@ECHO USAGE:
@ECHO   TBLLOAD ConnStr
@ECHO WHERE:
@ECHO   ConnStr - Connect String To OWNER of IB System Object.
@ECHO EXAMPLE:
@ECHO   TBLLOAD IBS/IBS@ORCL
exit

:OK

cd ..\SQLLDR

title STEP 0. Clear old logs.
@ECHO STEP 0. Clear old logs.
del ibs_*.log
del ibs_*.bad

title STEP 1. Loading Data Into Kernel tables...
@ECHO STEP 1. Loading Data Into Kernel tables...

sqlldr %1 UPDATE_JOURNAL.CTL LOG=ibs_update_journal.log BAD=ibs_update_journal.bad ERRORS=100000
sqlldr %1 PARSER.CTL LOG=ibs_parser.log BAD=ibs_parser.bad ERRORS=100000
sqlldr %1 MESSAGES.CTL LOG=ibs_messages.log BAD=ibs_messages.bad ERRORS=100000
sqlldr %1 PROJECT.CTL LOG=ibs_project.log BAD=ibs_project.bad ERRORS=100000
sqlldr %1 PARAMS.CTL LOG=ibs_params.log BAD=ibs_params.bad ERRORS=100000
sqlldr %1 ENTRIES.CTL LOG=ibs_entries.log BAD=ibs_entries.bad ERRORS=100000

cd ..\PATCH
