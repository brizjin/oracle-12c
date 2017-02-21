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

@ECHO Loading Data Into Kernel tables...

cd sqlldr

sqlldr %1 entries.ctl
sqlldr %1 params.ctl
sqlldr %1 parser.ctl
sqlldr %1 messages.ctl
sqlldr %1 project.ctl
sqlldr %1 update_journal.ctl ERRORS=100000

cd ..
