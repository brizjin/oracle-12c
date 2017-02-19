rem **************************************************************************
rem Отсутствующие представления, Лагута О.Н., 27.10.1999
rem **************************************************************************

prompt Список отсутствующих представлений записывается
prompt в файл v_absent.txt ...
spool v_absent.txt

set echo off
set termout off
set newpage 1
set pagesize 9999
set linesize 120
set trimspool on
set serveroutput on size 500000

column today noprint new_value curdate
repheader left sql.user right curdate skip center 'Отсутствующие представления' skip ' '

break on class

select rpad(s.id,16)||' '||substr(s.name,1,36) Class, c.short_name Короткое_имя, substr(c.name,1,35) Представление,
--       substr(m.user_created,1,10) Создал,
--       substr(m.user_modified,1,10) Изменил, substr(to_char(m.modified,'dd.mm.yy'),1,8) Дата,
       to_char(sysdate,'dd.mm.yyyy hh24:mi') today
   from criteria c, classes s --, methods m
   where s.id=c.class_id and/* m.id=c.id and*/ not exists
         (select status from user_objects where object_type='VIEW' and object_name=c.short_name)
   order by s.id, c.name;
spool off
host notepad v_absent.txt
exit