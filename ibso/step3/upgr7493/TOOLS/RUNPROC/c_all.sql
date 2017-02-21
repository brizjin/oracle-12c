SET SERVEROUTPUT ON SIZE 100000
spool c_all.log
Prompt * Installation RUNPROC - ORACLE server
ACCEPT TUSERS PROMPT 'USER tablespace:'
ACCEPT TSPACEI PROMPT 'Index tablespace:'
@@queries
@@runproc1
@@run_mgr1
@@runproc2
@@run_mgr2
@@c_usr
spool off
exit
