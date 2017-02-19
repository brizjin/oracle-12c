rem **************************************************************************
rem ������ ������������� �������� �������, ������ �.�., 12.07.2001
rem **************************************************************************

store set defaultenv replace

prompt _������ ������������� �������� �������
host md log
spool log\report_no_object.log

set termout off
set echo off
set linesize 160

column today noprint new_value curdate
repheader left sql.user right curdate skip center '������ ������������� �������� �������' skip ' '

column class_id format A20 WRAPPED TRUNC heading "�����"
column short_name format A20 WRAPPED TRUNC heading "��������_���"
column name format A50 WRAPPED TRUNC heading "�����"
column report_object format A20 WRAPPED TRUNC heading "������ ������"
column ro_name format A20 WRAPPED TRUNC heading "������ ������"

rem -- ������ �������� ��������- ����� ���� ����� ��� ������� Crystal Reports
rem select m.class_id, m.short_name, m.name, m.report_object ������, decode(m.report_on_proc,1,'���������', '') ���������,
rem        to_char(sysdate,'dd.mm.yyyy hh24:mi') today
rem     from methods m
rem    where m.flags='R' and m.report_type not like ('ORACLE%') and m.report_object is not null and
rem          not exists (select object_name from user_objects uo where uo.object_name=upper(m.report_object))
rem    order by 1,2;


select m.class_id, m.short_name, m.name, ro.name ro_name, ro.type ���,
       to_char(sysdate,'dd.mm.yyyy hh24:mi') today
   from methods m, report_objects ro
   where m.flags='R' and ro.method_id=m.id and not exists (select object_name from user_objects uo where uo.object_name=upper(ro.name))
   order by 1,2;

spool off

@defaultenv
host del  defaultenv.sql
