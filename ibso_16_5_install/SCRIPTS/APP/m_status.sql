rem **************************************************************************
rem Информация о состояниях и количестве методов, Лагута О.Н., 25.01.2001
rem **************************************************************************

set newpage 1
set pagesize 9999
set linesize 80

rem select class_id Класс, count(*) Колич_методов from methods where flags not in ('Z','R') and status!='VALID' group by class_id;
select status Статус, count(*) Колич_методов from methods where flags not in ('Z','R') group by status;
