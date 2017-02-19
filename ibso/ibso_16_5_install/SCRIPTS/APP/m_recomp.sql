rem **************************************************************************
rem �������������� �������� � ������������ ��������, ������ �.�., 24.01.2001
rem **************************************************************************

set serveroutput on size 100000
set ver off

select status ������, count(*) �����_������� from methods where flags not in ('Z','R') group by status;

prompt
prompt �������������� ������� �� ��������:
prompt I - INVALID
prompt N - NOT COMPILED
prompt P - PROCESSED
prompt U - UPDATED
prompt ��� ���������������� ������� ������: CL=[%]���_������[%]
prompt ��� ���� ������� ������: +CL=[%]���_������[%]
prompt
accept code char prompt '������� ������ �������� (I,N,P,U, ����� ������ ��� ��� ������):'
prompt
prompt �������� ���������� ������������ � ����� COMPILE$ ...
set termout off

declare
c varchar2(30);
i integer;
status varchar2(30);
stemp varchar2(30) := 'FOR_COMPILE';
begin
c:=upper('&&code');
i:=instr(c,'=');
if i>0 and substr(c,1,i) like '%CL=' then   -- ������ ������
   update methods set status=stemp
      where flags!='Z' and class_id like substr(c,i+1) and
            (substr(c,1,1)='+' or status!='VALID');
   c:=stemp;
end if;

if c = 'I' then
   status:='INVALID';
 elsif c = 'N' then
   status:='NOT COMPILED';
 elsif c = 'P' then
   status:='PROCESSED';
 elsif c = 'U' then
   status:='UPDATED';
 else
   status:=c;
end if;
i:=rtl.open;
method.compile_status(status);
end;
/