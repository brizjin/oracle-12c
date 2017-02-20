rem *********************************************************
rem Парсинг всех пакетов ТЯ для актуализации информации о
rem спецификациях всех функций/процедур пакета в таблицах
rem RTL_ENTRIES, RTL_PARAMETERS
rem Запускается из-под SQL*Plus
rem *********************************************************

spool parse_pack.log

set serveroutput on 
column xxx new_value owner noprint
select user xxx from dual;

prompt Выполнение парсинга пакетов ТЯ

begin
  for pack in (select name from PROJECT p where p.type = 'PACKAGE')
  loop
    plib.parse_package(pack.name, '&owner');
  end loop;
end;
/
prompt Парсинг пакетов ТЯ выполнен

spool off