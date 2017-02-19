rem **************************************************************************
rem ������ ���������� �������
rem **************************************************************************

store set defaultenv replace

set echo off
set termout off

prompt ������ �������  ...
set linesize 130

host md log
spool log\meth_error.log


column today noprint new_value curdate format DATE WRAPPED TRUNC
repheader left sql.user right curdate skip center '������ ���������� �������' skip ' '

column short_name format A20 WRAPPED TRUNC heading "��������_���"
column name format A60 WRAPPED TRUNC heading "������������"
column status  format A10 WRAPPED TRUNC heading "������"
column user_modified  format A10 WRAPPED TRUNC heading "�������"
column ���� format DATE heading "����"


-- ���������� ������ ��� ����� ������� �������� ����
     select        
       class_id, short_name, name,
       status,
       user_modified, modified ����,
       to_char(sysdate, 'DD/MM/YYYY hh:mi') today
     from methods m
     where m.KERNEL='0' and ( flags<>'Z'
           or flags ='Z' and ( nvl(m.status,'NOT COMPILED')<>'NOT COMPILED'
              or m.package_name is not null ) )
      and (m.status<>'VALID'
           -- �� ��������� �������� � PL/SQL = ���, � ��� ��� PL/SQL-������
           or (substr(PROPERTIES, instr(PROPERTIES,'COMPILER ')+27, 1) <> '2'
              and not exists
                 (select * from user_objects o
                  where o.object_name = m.package_name
                    and o.object_type = 'PACKAGE BODY'))
           or exists
              (select * from user_objects o
               where o.object_name = m.package_name
                 and o.object_type = 'PACKAGE BODY'
                 and o.status!='VALID')
              and
              exists (select * from user_errors ue where ue.name = m.package_name)
          )
     order by class_id,short_name;


repheader left sql.user right curdate skip center '�������� ������ � ���������� ������� �������� �����, ������� ������' skip ' '

     select 
       class_id, short_name, name,
       status,  user_modified, modified ����,
       to_char(sysdate, 'DD/MM/YYYY hh:mi') today
     from methods m
     where m.KERNEL='0' and ( flags<>'Z'
           or flags ='Z' and ( nvl(m.status,'NOT COMPILED')<>'NOT COMPILED'
              or m.package_name is not null ) )
      and (m.status='VALID'
           and exists
              (select * from user_objects o
               where o.object_name = 'Z$U$' || m.id
                 and o.object_type = 'PACKAGE BODY'
                 and o.status!='VALID')
              and
              exists (select * from user_errors ue where ue.name = 'Z$U$' || m.id)
          )
     ;

repheader left sql.user right curdate skip center '�������� ���� ����� �� ���������� ��������� �������� � �� ����� ���� �������������� �������������' skip ' '
    select 
      class_id, short_name, name,
       status,  user_modified, modified ����,
       to_char(sysdate, 'DD/MM/YYYY hh:mi') today
    from methods where accessibility=2 and flags='R' and user_driven='0';

spool off

@defaultenv
host del  defaultenv.sql
