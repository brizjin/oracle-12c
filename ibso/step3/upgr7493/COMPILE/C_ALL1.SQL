set serveroutput on size 1000000
spool others.log
@@others
spool off
@@c_stat
exit
