set serveroutput on size 100000
define pipe_name = 'DEBUG'
define rebuild = 'NO'
define del_params = 'NO'
define del_controls = 'NO'
define ignore_errors = 'YES'
@@ctlprint
spool errfrm.log
@@errfrm
spool off
spool errctl.log
@@errctl
spool off
spool c_mtd.log
prompt dropping qual_aliases
drop table qual_aliases;
spool off
exit
