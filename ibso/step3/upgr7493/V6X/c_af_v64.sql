prompt Correcting settings

exec sysinfo.setvalue('CLS_STATIC_EVENT','0','������� �������� ������� ���������� ������������ ���������� � ������ ���������');

insert into settings(name,value,description) values('LOCK_START','LIB',
  '���� � ������������ ������ LOCK_INFO (�������� LIB - ������ ����� ����������)');

insert into settings(name,value,description) values('PLP_CACHE_CLASS','YES',
  '������� ������������� ���������� plp$class$ ��� ���������� this%class � ���������');

commit;

@@ses_user

column xxx new_value oxxx noprint
select user xxx from dual;

prompt Grant on stat_lib
grant execute on stat_lib to &&oxxx._USER;

commit;

