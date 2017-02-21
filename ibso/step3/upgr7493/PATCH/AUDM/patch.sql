set serveroutput on size 1000000

var constr varchar2(200)
exec :constr:='&1'
undef 1

@@../settings
@@UTILS/patch_settings

SET TERMOUT OFF

column xxx new_value ConnStr noprint
select :constr xxx from dual;

def audit='&&AUDM_OWNER'

column xxx new_value ask noprint
select decode('&2','quiet','..\UTILS\dummy','AUDM\ask_pars') xxx from dual;
SET TERMOUT ON

@@&&ask

SET TERMOUT OFF

column xxx new_value audmgr noprint
select decode('&&audit','SYS','AUDM','','AUDM','&&audit') xxx from dual;

column yyy new_value log_file_name noprint
select 'LOG\audm_'||to_char(sysdate,'YYYYMMDD_hh24mi')||'.log' yyy from dual;

SET TERMOUT ON

spool &log_file_name

prompt  
prompt -------------------------------------------------------------------------------- 

prompt �������� ����������� ��������� �����
prompt 

@@check_install_audm
print mess
@@../UTILS/exit_when ':can_run_patch = 0'

prompt  
prompt -------------------------------------------------------------------------------- 

prompt ������ ��������� �����
prompt 

set timi on

Prompt * Try to stop jobs

exec &&audmgr..aud_mgr.stop;


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

prompt ���������� ������� 
prompt 


prompt install ..\AUDMGR\PACKAGES\AUD1.SQL
@@../AUDMGR/PACKAGES/AUD1.SQL

prompt install ..\AUDMGR\PACKAGES\AUD2.SQL
@@../AUDMGR/PACKAGES/AUD2.SQL

prompt install ..\AUDMGR\PACKAGES\ORA_USER_PASSWORD_SET.SQL
@@../AUDMGR/PACKAGES/ORA_USER_PASSWORD_SET.SQL

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

prompt * Try to start jobs
exec &&audmgr..aud_mgr.submit;

set timi off

spool off
exit

