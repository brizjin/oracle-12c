rem **************************************************************************
rem ���������� � ���������� � ���������� �������, ������ �.�., 25.01.2001
rem **************************************************************************

set newpage 1
set pagesize 9999
set linesize 80

rem select class_id �����, count(*) �����_������� from methods where flags not in ('Z','R') and status!='VALID' group by class_id;
select status ������, count(*) �����_������� from methods where flags not in ('Z','R') group by status;
