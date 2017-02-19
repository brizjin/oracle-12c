rem **************************************************************************
rem Информация о классе, Лагута О.Н., 21.02.2003
rem **************************************************************************

set serveroutput on size 100000
set ver off
set echo off
set newpage 1
set pagesize 9999
set linesize 125

prompt
accept class char prompt 'Введите имя класса для получения информации: '
prompt
prompt :::::::::: Методы класса ::::::::::
select rpad(short_name,16) Метод, rpad(name,50) Наименование
       from methods where class_id=upper('&class');
prompt
prompt :::::::::: Использование типа, ссылки и массива в качестве параметров методов ::::::::::
select rpad(c.id,16) Класс, rpad(c.name,20) Наименование, rpad(m.short_name,16) Метод, rpad(m.name,15) Название, rpad(p.short_name,16) Параметр, rpad(p.class_id,16) Тип, rpad(p.name,20) Имя
       from method_parameters p, methods m, classes c
       where m.id=p.method_id and c.id=m.class_id and
--          p.class_id=upper('&class')
          p.class_id in (select id from classes where id=upper('&class') or target_class_id=upper('&class'))
       order by c.id, m.short_name, p.class_id;
prompt
prompt :::::::::: Использование типа, ссылки и массива в качестве перемееных методов ::::::::::
select rpad(c.id,16) Класс, rpad(c.name,20) Наименование, rpad(m.short_name,16) Метод, rpad(m.name,15) Название, rpad(p.short_name,16) Параметр, rpad(p.class_id,16) Тип, rpad(p.name,20) Имя
       from method_variables p, methods m, classes c
       where m.id=p.method_id and c.id=m.class_id and
--          p.class_id=upper('&class')
          p.class_id in (select id from classes where id=upper('&class') or target_class_id=upper('&class'))
       order by c.id, m.short_name, p.class_id;
prompt
prompt :::::::::: Использование типа, ссылки и массива в качестве реквизитов классов ::::::::::
select rpad(c.id,16) Класс, rpad(c.name,30) Наименование, rpad(a.attr_id,16) Реквизит, rpad(a.self_class_id,16) Тип, rpad(a.name,30) Имя
       from class_attributes a, classes c
       where c.id=a.class_id and
--          a.self_class_id=upper('&class')
          a.self_class_id in (select id from classes where id=upper('&class') or target_class_id=upper('&class'))
       order by c.id, a.attr_id;
prompt
prompt :::::::::: Ссылки на класс ::::::::::
select rpad(id,16) Класс, rpad(name,40) Наименование, rpad(base_class_id,10) Тип
       from classes where target_class_id=upper('&class')
       order by id;
select count(*) Количество_экземпляров_класса from z#&class;

