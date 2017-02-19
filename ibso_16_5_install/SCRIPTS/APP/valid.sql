-- 1. Вывод операций, имеющих проблемы с "Валидностью" (с пользователями)
 select count(m.ID) as Колво_Не_Валидных_Meth -- Кол-во
-- select m.ID, m.CLASS_ID, m.SHORT_NAME, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), m.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS-- Операции
 from methods m
 where  m.FLAGS <> 'Z' and m.KERNEL='0' -- исключаем фильтры вьюх
    and m.STATUS <> 'VALID' 
 order by m.class_id, m.short_name
/
-- 2. Вывод операций, пакет которых имеет статус "INVALID"
 select count(1) as Колво_Inv_Pack_Meth -- Кол-во
-- select m.ID, m.CLASS_ID, m.SHORT_NAME, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), o.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS-- Операции
 from methods m, user_objects o 
 where o.STATUS !=  'VALID' and o.object_name = m.package_name
 order by m.class_id, m.short_name
/
-- 3. Вывод представлений, имеющих проблемы с "Валидностью", но существующих в all_object
 select count(1) as Колво_Не_Валидных_Crit
-- select c.class_id, a.object_name, a.STATUS
 from all_objects a, criteria c
 where SUBSTR(a.object_name,1,8) = 'VW_CRIT_' and a.status <> 'VALID' and a.object_type = 'VIEW'
   and c.short_name = a.object_name
 order by c.class_id, c.short_name
/
-- 4. Вывод представлений для отчетов, имеющих проблемы с "Валидностью", но существующих в all_object
 select count(1) as Колво_Не_Валидных_RPT
-- select a.owner, c.class_id, a.object_name, a.STATUS
 from all_objects a, criteria c
 where SUBSTR(a.object_name,1,7) = 'VW_RPT_' and a.status <> 'VALID' and a.object_type = 'VIEW'
   and c.short_name = a.object_name
 order by c.class_id, c.short_name;
 /
-- 5. Вывод представлений, не существующих в user_object ("NOT EXIST")
 select count(1) as Колво_Не_Существующ_Crit
-- select c.class_id, c.short_name, c.tag
       from criteria c, (select * from user_objects where object_type = 'VIEW') a
       where c.short_name = a.object_name (+)
          and a.object_name is null
          and (c.tag is Null
            or c.tag <> 'EXTENSION')
 order by c.class_id, c.short_name
/
-- 6. Вывод фильтров представлений, имеющих проблемы с "Валидностью" (с пользователями)
 select count(m.ID) as Колво_Inv_Filter_Views -- Кол-во
-- select m.ID, m.CLASS_ID, m.SHORT_NAME as METHOD_SHORT_NAME, c.SHORT_NAME as VIEW_SHORT_NAME, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), m.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS-- Операции
 from methods m, criteria c
 where  m.FLAGS = 'Z' and m.KERNEL='0' -- фильтры вьюх
    and m.id = c.id
    and m.STATUS <> 'VALID' 
 order by m.class_id, c.short_name, m.short_name
/
-- 7. Вывод индексов, не существующих в all_indexes ("NOT EXIST")
select count(1) as Колво_Не_Существующ_IDX
-- select c.class_id, c.name
       from class_indexes c, all_indexes a
       where c.name = a.index_name (+)
          and a.index_name is null
order by c.class_id, c.name
/
-- 8. Вывод операций с признаком "Может быть активизирована пользователем" и "Абсолютно доступна"
--    При обнаружении таких методов, требовать от разработки исправления данных операций и снятии признака "Абсолютно доступна"
 select count(1) as Колво_Доступных_Методов
-- select m.ID, m.CLASS_ID, m.SHORT_NAME, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), m.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS-- Операции
 from methods m
 where m.USER_DRIVEN = '1' 
   and m.ACCESSIBILITY = '2'
 order by m.class_id, m.short_name
/

/*
-- JAVA --

-- 9. Вывод операций, имеющих проблемы с "Валидностью" в JAVA (с пользователями)
--select count(m.id) as Колво_Не_Валидных_Meth_Java -- Кол-во
select m.id, m.class_id, m.short_name, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), hs.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS
from methods m, host_sources hs
where m.id = hs.id
  and hs.status <> 'VALID'
  and m.FLAGS <> 'Z' and m.KERNEL='0' -- исключаем фильтры вьюх
order by hs.status, m.class_id, m.short_name
/
-- 10. Вывод фильтров представлений, имеющих проблемы с "Валидностью" в JAVA (с пользователями)
--select count(m.id) as Колво_Inv_Filter_Views_Java -- Кол-во
select m.id, m.class_id, m.short_name, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), hs.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS
from methods m, host_sources hs
where m.id = hs.id
  and hs.status <> 'VALID'
  and m.FLAGS = 'Z' and m.KERNEL='0' -- только фильтры вьюх
order by hs.status, m.class_id, m.short_name
/
-- 11. Вывод методов без пакета Java (с пользователями)
--select count(m.id) as Колво_Meth_Java_NoPack -- Кол-во
select m.id, m.class_id, m.short_name, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), m.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS
from methods m 
where not exists (select 1 from host_sources hs where m.id = hs.id)
order by m.class_id, m.short_name
/
-- Ошибки JAVA
select m.id, m.class_id, m.short_name, he.line, he.pos, he.len, he.text, To_Char(m.modified, 'DD/MM/YYYY HH:MM:SS'), m.STATUS, m.USER_CREATED, m.USER_MODIFIED, m.FLAGS
from host_errors he, methods m
where m.id = he.method_id
  and m.KERNEL='0'
order by m.class_id, m.short_name
/

-- JAVA --
*/
