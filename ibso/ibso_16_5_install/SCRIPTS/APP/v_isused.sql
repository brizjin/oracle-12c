rem *************************************************************************
rem Использование представления в отчетах и формах методов,
rem Лагута О.Н., 10.03.2001
rem **************************************************************************

set serveroutput on size 100000
set ver off
set echo off
set newpage 1
set pagesize 9999
set linesize 125

prompt
accept v_name char prompt 'Введите имя представления для получения информации: VW_'

prompt
prompt :::::::::: Информация о представлении ::::::::::
select rpad(class_id,16) Класс, rpad(short_name,16) Представление, rpad(name,20) Наименование
       from criteria where upper(short_name)='VW_'||upper('&v_name');

prompt
prompt :::::::::: Представление используется в следующих отчетах ::::::::::
select rpad(c.id,16) Класс, rpad(c.name,20) Наименование, rpad(m.short_name,16) Метод, rpad(m.name,40) Название
       from report_objects r, methods m, classes c
       where m.id=r.method_id and c.id=m.class_id and
          upper(r.name)='VW_'||upper('&v_name')
       order by c.id, m.short_name;

prompt
prompt ::::::: Представление используется в формах следующих методов ::::::

select rpad(c.id,16) Класс, rpad(c.name,20) Наименование, rpad(m.short_name,16) Метод, rpad(m.name,40) Название
       from method_parameters p, methods m, classes c
       where m.id=p.method_id and c.id=m.class_id and
          instr(upper(p.crit_formula),'VW_'||upper('&v_name'))>0
       order by c.id, m.short_name;
