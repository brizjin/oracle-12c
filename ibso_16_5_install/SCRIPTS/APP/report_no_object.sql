rem **************************************************************************
rem Список отсутствующих объектов отчетов, Лагута О.Н., 12.07.2001
rem **************************************************************************

store set defaultenv replace

prompt _Список отсутствующих объектов отчетов
host md log
spool log\report_no_object.log

set termout off
set echo off
set linesize 160

column today noprint new_value curdate
repheader left sql.user right curdate skip center 'Список отсутствующих объектов отчетов' skip ' '

column class_id format A20 WRAPPED TRUNC heading "Класс"
column short_name format A20 WRAPPED TRUNC heading "Короткое_имя"
column name format A50 WRAPPED TRUNC heading "Отчет"
column report_object format A20 WRAPPED TRUNC heading "Объект отчета"
column ro_name format A20 WRAPPED TRUNC heading "Объект отчета"

rem -- Данная проверка устарела- нужна была ранее для отчетов Crystal Reports
rem select m.class_id, m.short_name, m.name, m.report_object объект, decode(m.report_on_proc,1,'Процедура', '') процедура,
rem        to_char(sysdate,'dd.mm.yyyy hh24:mi') today
rem     from methods m
rem    where m.flags='R' and m.report_type not like ('ORACLE%') and m.report_object is not null and
rem          not exists (select object_name from user_objects uo where uo.object_name=upper(m.report_object))
rem    order by 1,2;


select m.class_id, m.short_name, m.name, ro.name ro_name, ro.type тип,
       to_char(sysdate,'dd.mm.yyyy hh24:mi') today
   from methods m, report_objects ro
   where m.flags='R' and ro.method_id=m.id and not exists (select object_name from user_objects uo where uo.object_name=upper(ro.name))
   order by 1,2;

spool off

@defaultenv
host del  defaultenv.sql
