rem *********************************************************
rem Вывод текстов ошибок в интерфейсах классов
rem Запускается из-под SQL*Plus
rem (условие выборки операций можно модифицировать)
rem *********************************************************
set newpage 0
set pagesize 0
set echo off
set feedback off
set heading off
set verify off
set serveroutput on size 500000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;
spool &oxxx..ecr
declare
  s varchar2(32767);
  ok boolean := true;
begin
  for c in (select id,class_id,short_name,name from criteria order by class_id,short_name)
  loop
    s:=method.meth_errors(c.id,false,false);
    if s is not null then
      stdio.put_line_buf('---- '||c.class_id||' - '||c.name||' ('||c.id||' - '||c.short_name||')');
      stdio.put_line_buf(s);
      ok:=false;
    end if;
  end loop;
  if ok then
    stdio.put_line_buf('No errors.');
  end if;
end;
/
spool off
set feedback on
set heading on
