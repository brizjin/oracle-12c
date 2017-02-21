var s varchar2(100)
exec :s:=inst_info.Version
exec :s:=inst_info.Version
column xxx new_value v_version noprint
select :s xxx from dual;
select owner xxx from project where name='V_VERSION' and type='SETTINGS';

exec stdio.put_line_buf(rtl.open)
@@ufind
@@ufind1 1

spool c_after.log
exec patch_tool.mv_clr_obj_refcing_to_mtd_mgr;
prompt compiling updated methods
exec method.compile_status('NOT COMPILED','DEBUG0');
exec method.compile_status('INVALID','DEBUG0');
exec method.compile_status('PROCESSED','DEBUG0');
exec method.compile_status('UPDATED','DEBUG0');
spool off

@@ufind1 2
spool c_after1.log
exec method.compile_status('UPDATED','DEBUG0');
spool off
@@ufind2
spool c_after2.log
exec method.compile_status('UPDATED','DEBUG0');
spool off

@@ufind4
@@ufind5 1
spool c_after5.log
exec method.compile_status('UPDATED','DEBUG0');
spool off

@@ufind5 2

@@todate

