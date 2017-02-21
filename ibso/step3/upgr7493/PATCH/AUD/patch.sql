set serveroutput on size 1000000

column xxx new_value ask noprint
select decode('&&2','quiet','..\UTILS\dummy','AUD\ask_pars') xxx from dual;

@@../AUDIT/init dummy &&1
@@UTILS/patch_settings

SET TERMOUT OFF
column yyy new_value log_file_name noprint
select 'LOG\aud_'||to_char(sysdate,'YYYYMMDD_hh24mi')||'.log' yyy from dual;
SET TERMOUT ON

spool &log_file_name

prompt  
prompt -------------------------------------------------------------------------------- 

prompt �������� ����������� ��������� �����
prompt 

@@check_install_aud
print mess
@@../UTILS/exit_when ':can_run_patch = 0'

prompt  
prompt --------------------------------------------------------------------------------

prompt ������ ��������� �����
prompt 

@@&&ask

set timi on

@@../UTILS/alt_sys_enable_restricted_session

spool off


spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ����������� �������� � ��������� INVALID
prompt 

var invalid_objects_before varchar2(4000);
var cntInvBefore number;

declare 
tab dbms_utility.lname_array;
begin
select object_name BULK COLLECT INTO tab from user_objects 
	where status='INVALID' and object_type='PACKAGE BODY' 
	and object_name not like 'Z$%' and object_name not like 'Z#%' and object_name not like 'ZZ$%' 
	order by object_name;

dbms_utility.table_to_comma(tab, :cntInvBefore, :invalid_objects_before);
end;
/

print invalid_objects_before

spool off


spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt �������� ��������
prompt 

@@../UTILS/alt_sys_disable_restricted_session

spool off

column xxx new_value ConnStr noprint
select :constr xxx from dual;

host tblload_aud.bat &&ConnStr 

undef ConnStr

spool &log_file_name append
prompt �������� �������� ���������, log-����� � ����� SQLLDR

@@../UTILS/alt_sys_enable_restricted_session

spool off

spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ���������� ������� 
prompt 


prompt install ..\AUDIT\PACKAGES\CLEAR1.SQL
@@../AUDIT/PACKAGES/CLEAR1.SQL

prompt install ..\AUDIT\PACKAGES\UTIL1.SQL
@@../AUDIT/PACKAGES/UTIL1.SQL

prompt install ..\AUDIT\PACKAGES\CLEAR2.SQL
@@../AUDIT/PACKAGES/CLEAR2.SQL

prompt install ..\AUDIT\PACKAGES\LIC2.PLB
@@../AUDIT/PACKAGES/LIC2.PLB

prompt install ..\AUDIT\PACKAGES\MAIL2.SQL
@@../AUDIT/PACKAGES/MAIL2.SQL

prompt install ..\AUDIT\PACKAGES\UTIL2.SQL
@@../AUDIT/PACKAGES/UTIL2.SQL

spool off

spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt �������� ��������� �����
prompt 

var invalid_objects_after varchar2(4000);
var cntInvAfter number;

declare 
tab dbms_utility.lname_array;
i number;
begin

select object_name BULK COLLECT INTO tab from user_objects 
	where status='INVALID' and object_type='PACKAGE BODY' 
	and object_name not like 'Z$%' and object_name not like 'Z#%' and object_name not like 'ZZ$%' 
	order by object_name;

i:= tab.first;
:invalid_objects_after := '';

while (i is not null) loop
  if instr(:invalid_objects_before, tab(i)) = 0 then
	:invalid_objects_after := :invalid_objects_after||chr(10)|| tab(i);
  end if;
  i := tab.next(i);
end loop;

if :invalid_objects_after is not null then
  :invalid_objects_after := chr(10)||chr(10)||'--------------------------------------------------------------------------------'
		||chr(10)||'!!!WARNING!!!'||chr(10)||'����� ������ ���������� ��������� ������ ������������� � ��������:'
		||:invalid_objects_after;
else
  :invalid_objects_after := chr(10)||'���� ���������� �������!';
end if;

end;
/

print invalid_objects_after


spool off


spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ������ ���� AUDIT_ADMIN ���� ��� ����
@@../AUDIT/UPGRADE/drop_role_audit_admin.sql 1

@@../UTILS/alt_sys_disable_restricted_session

set timi off

prompt  
prompt ����������� ������ ����� ��������
select clear.full_version version from dual;

spool off

exit

