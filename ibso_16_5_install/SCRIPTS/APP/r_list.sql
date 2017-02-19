rem **************************************************************************
rem Список шаблонов отчетов, Лагута О.Н., 20.10.2000
rem **************************************************************************

prompt Список шаблонов отчетов записывается в файл r_list.txt ...
spool r_list.txt

set termout off
set echo off
set newpage 1
set pagesize 9999
set linesize 64
set trimspool on

column today noprint new_value curdate
repheader left sql.user right curdate skip center 'Список шаблонов отчетов' skip ' '

break on label skip page
select report Шаблон,
       to_char(sysdate,'dd.mm.yyyy hh24:mi') today
   from methods where flags = 'R' order by 1;
spool off
host notepad r_list.txt;
exit