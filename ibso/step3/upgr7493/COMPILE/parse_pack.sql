rem *********************************************************
rem ������� ���� ������� �� ��� ������������ ���������� �
rem ������������� ���� �������/�������� ������ � ��������
rem RTL_ENTRIES, RTL_PARAMETERS
rem ����������� ��-��� SQL*Plus
rem *********************************************************

spool parse_pack.log

set serveroutput on 
column xxx new_value owner noprint
select user xxx from dual;

prompt ���������� �������� ������� ��

begin
  for pack in (select name from PROJECT p where p.type = 'PACKAGE')
  loop
    plib.parse_package(pack.name, '&owner');
  end loop;
end;
/
prompt ������� ������� �� ��������

spool off