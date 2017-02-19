rem *********************************************************
rem Инвалидные и отсутствующие представления представления 
rem *********************************************************

store set defaultenv replace

set linesize 110

host md log
spool log\crit_error.log

set echo off
set termout off

column today noprint new_value curdate format DATE WRAPPED TRUNC
repheader left sql.user right curdate skip center 'Инвалидные представления' skip ' '

column class format A16 WRAPPED TRUNC heading "Класс"
column short_name format A30 WRAPPED TRUNC heading "Короткое_имя"
column name format A60 WRAPPED TRUNC heading "Наименование"
column Дата format DATE heading "Дата"


select s.id class, c.short_name, c.name,
       sysdate today
   from criteria c, classes s 
     where s.id=c.class_id and
	   c.tag <>'EXTENSION' and
   	( exists (select 1 from user_objects
              where OBJECT_TYPE = 'VIEW' and OBJECT_NAME = c.SHORT_NAME
                and status <> 'VALID')
          or
          not exists (select status from user_objects where 
		object_type='VIEW' and 
		object_name=c.short_name and status = 'VALID'))
  order by s.id, c.name;

repheader left sql.user right curdate skip center 'Представления, которые есть на схеме, но нет в словаре ИБСО' skip ' '


-- представления, которые есть на схеме, но нет в словаре ИБСО
-- Рассматриваются только начинающиеся на VW_CRIT_ и VW_RPT_
select object_name name from user_objects uo
where OBJECT_TYPE = 'VIEW'
  and (OBJECT_NAME like 'VW\_RPT\_%' escape '\' or OBJECT_NAME like 'VW\_CRIT\_%' escape '\')
  and not exists (select 1 from criteria c
                  where uo.OBJECT_NAME = c.SHORT_NAME);


spool off

@defaultenv
host del  defaultenv.sql
