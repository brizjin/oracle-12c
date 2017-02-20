
var s varchar2(2000)
declare
  s varchar2(2000);
  x varchar2(1);
begin
  for c in (select file_spec from user_libraries where library_name='LIBLOCK')
  loop
    s := c.file_spec;
  end loop;
  s := nvl(s,'/u/tools/lock/liblock.so');
  if instr(s,'\')>0 then
    x := '\';
  else
    x := '/';
  end if;
  :s := substr(s,1,instr(s,x,-1))||'lock.ini';
end;
/

prompt SHOW_SYSTEM_MENU
insert into settings(name,value,description) values('SHOW_SYSTEM_MENU','YES',
  '������� ������ ���������� ����');
prompt VIEW_OBJECT_ATTRIBUTES
insert into settings(name,value,description) values('VIEW_OBJECT_ATTRIBUTES','NO',
  '���������� �������������, ���������� ����������� ��������� ������ � ������ �������������, � ������ "�������� ���������� ����������"');
prompt NO_EXTEND_RIGHT_COLUMN
insert into settings(name,value,description) values('NO_EXTEND_RIGHT_COLUMN','NO',
  '�� ��������� ��������� ������� ������������� �� ��� ������ �������');
prompt REPLACE_TYPE_MENU
insert into settings(name,value,description) values('REPLACE_TYPE_MENU','NO',
  '������� ������ ���� ����� ��������� ����');
prompt HIDE_NOVIEW_TYPES
insert into settings(name,value,description) values('HIDE_NOVIEW_TYPES','NO',
  '���������� ������ �� ���� � �����������, ������� �� ������ �������� ����, �� � ����� ��������� ������������ �������������, �� ���������� ������ "�������� ������ � ���������"');
prompt MESSAGE_PERIOD
insert into settings(name,value,description) values('MESSAGE_PERIOD','60',
  '�������� ������� �������� ������� ��������� � ��������');
prompt MAX_SESSIONS_ALLOWED
insert into settings(name,value,description) values('MAX_SESSIONS_ALLOWED','0',
  '����������� ���������� ���������� �������� ������ (0 - ����������� ���)');

prompt LOCK_TIMEOUT
insert into settings(name,value,description) values('LOCK_TIMEOUT','300',
  '����������� ���������� ������ (� ���.) ������������ ������ ������������, �� ��������� �������� ������ ���������');
prompt RESTRICTED_MODE
insert into settings(name,value,description) values('RESTRICTED_MODE','NO',
  '������� ������������� ������� � ������� (YES - ���� � ������� ����������� ������)');
prompt LOCK_PATH
insert into settings(name,value,description) values('LOCK_PATH',:s,
  '���� � ����� �������� LOCK_INFO (��� �������� ��������)');
prompt LOCK_PROFILE
insert into settings(name,value,description) values('LOCK_PROFILE',USER,
  '������� �������� LOCK_INFO (��� �������� ��������)');
prompt LOCK_SERVERS
insert into settings(name,value,description) values('LOCK_SERVERS','2',
  '������������ ���������� ���������� ����������');

insert into storage_parameters(param_group, param_name, param_value)
  values('GLOBAL','CHECK_PLSQL','&&CHKPLS');

exec patch_tool.update_props;

commit;



