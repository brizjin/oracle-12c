rem *********************************************************
rem Вывод текстов предупреждений в операциях
rem Запускается из-под SQL*Plus
rem (условие выборки операций можно модифицировать)
rem *********************************************************
set newpage 0
set pagesize 0
set echo off
set feedback off
set heading off
set verify off
set serveroutput on size 1000000
set serveroutput on size unlimited
set linesize 4000
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;

exec stdio.enable_buf(1000000)
exec stdio.enable_buf(10000000)

spool &oxxx..wrn

declare
  str varchar2(32767);
begin
  for c in (select id,class_id,short_name from methods
    where status='VALID' and kernel='0'
    order by class_id,short_name)
  loop
    str := method.meth_errors(c.id,true,false);
    if not str is null then
        stdio.put_line_buf('---- '||c.class_id||' - '||c.short_name||' ( '||c.id||' )');
        stdio.put_line_buf(str);
    end if;
  end loop;
end;
/

spool off

set feedback on
set heading on

