rem *************************************************************************
rem ������������� ������������� � ������� � ������ �������,
rem ������ �.�., 10.03.2001
rem **************************************************************************

set serveroutput on size 100000
set ver off
set echo off
set newpage 1
set pagesize 9999
set linesize 125

prompt
accept v_name char prompt '������� ��� ������������� ��� ��������� ����������: VW_'

prompt
prompt :::::::::: ���������� � ������������� ::::::::::
select rpad(class_id,16) �����, rpad(short_name,16) �������������, rpad(name,20) ������������
       from criteria where upper(short_name)='VW_'||upper('&v_name');

prompt
prompt :::::::::: ������������� ������������ � ��������� ������� ::::::::::
select rpad(c.id,16) �����, rpad(c.name,20) ������������, rpad(m.short_name,16) �����, rpad(m.name,40) ��������
       from report_objects r, methods m, classes c
       where m.id=r.method_id and c.id=m.class_id and
          upper(r.name)='VW_'||upper('&v_name')
       order by c.id, m.short_name;

prompt
prompt ::::::: ������������� ������������ � ������ ��������� ������� ::::::

select rpad(c.id,16) �����, rpad(c.name,20) ������������, rpad(m.short_name,16) �����, rpad(m.name,40) ��������
       from method_parameters p, methods m, classes c
       where m.id=p.method_id and c.id=m.class_id and
          instr(upper(p.crit_formula),'VW_'||upper('&v_name'))>0
       order by c.id, m.short_name;
