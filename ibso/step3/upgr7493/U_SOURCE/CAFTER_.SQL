var s varchar2(100)
exec :s:=inst_info.Version
exec :s:=inst_info.Version
column xxx new_value v_version noprint
select :s xxx from dual;
select owner xxx from project where name='V_VERSION' and type='SETTINGS';

exec stdio.put_line_buf(rtl.open)

spool c_after.log
prompt compiling updated methods
exec method.compile_status('NOT COMPILED','DEBUG0');
exec method.compile_status('INVALID','DEBUG0');
exec method.compile_status('PROCESSED','DEBUG0');
exec method.compile_status('UPDATED','DEBUG0');
spool off

@@ufind5 1
spool c_after5.log
exec method.compile_status('UPDATED','DEBUG0');
spool off

@@ufind5 2

@@todate

