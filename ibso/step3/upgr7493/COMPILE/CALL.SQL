set serveroutput on size 100000
define pipe_name = 'DEBUG'
spool objs.log
prompt clearing dependencies
delete dependencies where referencing_type='C' and referenced_type='C';
commit;
@@objs
spool off
spool build_fk.log
@@build_fk
spool off
rem spool c_options.log
rem @@c_options.sql
rem spool off
exit
