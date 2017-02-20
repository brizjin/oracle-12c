rem *********************************************************
rem ¬ывод текстов семантических ошибок в операци€х
rem «апускаетс€ из-под SQL*Plus
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

spool &oxxx..err

begin
  for c in (select id,class_id,short_name,status from methods
    where status<>'VALID' and flags<>'Z' or status='INVALID' and flags='Z'
    order by class_id,short_name)
  loop
    stdio.put_line_buf('---- '||c.class_id||' - '||c.short_name||' ('||c.id||' - '||c.status||')');
    stdio.put_line_buf(method.meth_errors(c.id,false,false));
  end loop;
end;
/

spool off

set feedback on
set heading on

