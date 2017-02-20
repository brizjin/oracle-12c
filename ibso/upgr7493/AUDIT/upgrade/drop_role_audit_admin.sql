-- PLATFORM-3603. � ����� � ���������� � Oracle 12� ��������� ���� � ������ 'AUDIT_ADMIN',
-- ������������� ���������� ���� � 'AUD_REVISOR' - �.�. ������� ����� ���� � ���� �� �������, � ������ ����� �������.
-- �������� s - '1' - ����������� ���� � ����� ������, '0' - �� �����������.
set verify off
declare
  n number;
  role_name varchar2(20) := 'AUDIT_ADMIN';
  s varchar(1) := &1;
begin 
    select count(username) into n from user_role_privs
     where granted_role = role_name;
    -- ���� ���������� ���� 'AUDIT_ADMIN' ����������, �� ������ �
    if (n > 0) then
      begin
        execute immediate 'DROP ROLE ' || role_name;
        dbms_output.put_line('DROP ROLE ' || role_name || ' - OK');
      exception when others then 
        dbms_output.put_line('DROP ROLE '||role_Name||' - '||sqlerrm);
      end;
      -- C������ ���� 'AUD_REVISOR', ������� ��������� ����
      if (s = '1') then
      	utils.roles;
      end if;
    end if;
end;
/