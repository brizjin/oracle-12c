rem **************************************************************************
rem Список инвалидных методов
rem **************************************************************************

store set defaultenv replace

set echo off
set termout off

prompt Список методов  ...
set linesize 130

host md log
spool log\meth_error.log


column today noprint new_value curdate format DATE WRAPPED TRUNC
repheader left sql.user right curdate skip center 'Список инвалидных методов' skip ' '

column short_name format A20 WRAPPED TRUNC heading "Короткое_имя"
column name format A60 WRAPPED TRUNC heading "Наименование"
column status  format A10 WRAPPED TRUNC heading "Статус"
column user_modified  format A10 WRAPPED TRUNC heading "Изменил"
column Дата format DATE heading "Дата"


-- невалидные методы без учета проблем экранных форм
     select        
       class_id, short_name, name,
       status,
       user_modified, modified Дата,
       to_char(sysdate, 'DD/MM/YYYY hh:mi') today
     from methods m
     where m.KERNEL='0' and ( flags<>'Z'
           or flags ='Z' and ( nvl(m.status,'NOT COMPILED')<>'NOT COMPILED'
              or m.package_name is not null ) )
      and (m.status<>'VALID'
           -- Не учитываем операции с PL/SQL = Нет, у них нет PL/SQL-пакета
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


repheader left sql.user right curdate skip center 'валидные методы с невалидным пакетом экранной формы, имеющим ошибки' skip ' '

     select 
       class_id, short_name, name,
       status,  user_modified, modified Дата,
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

repheader left sql.user right curdate skip center 'Операции типа Отчет со свойствами Абсолютно доступна и Не может быть активизирована пользователем' skip ' '
    select 
      class_id, short_name, name,
       status,  user_modified, modified Дата,
       to_char(sysdate, 'DD/MM/YYYY hh:mi') today
    from methods where accessibility=2 and flags='R' and user_driven='0';

spool off

@defaultenv
host del  defaultenv.sql
