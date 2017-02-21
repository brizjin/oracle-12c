def simple=0
column xxx new_value simple noprint
select owner xxx from project where name='SIMPLE' and type='SETTINGS';

column xxx new_value cafter noprint
select decode('&&simple','1','dummy','2','todate','0','cafter','cafter_') xxx from dual;

exec dbms_session.reset_package

@@&&cafter

spool c_afterX.log

exec stdio.put_line_buf(rtl.open)
exec method.compile_status('NOT COMPILED','DEBUG0');

WHENEVER SQLERROR EXIT FAILURE
exec method.compile_status('UPDATED','DEBUG0');
WHENEVER SQLERROR CONTINUE NONE

delete from project where type='SETTINGS' and name in ('V_VERSION','SIMPLE');
commit;

spool off

exit

