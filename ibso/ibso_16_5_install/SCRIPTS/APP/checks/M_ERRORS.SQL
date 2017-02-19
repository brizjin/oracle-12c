rem *********************************************************
rem ¬ывод текстов семантических ошибок в операци€х
rem «апускаетс€ из-под SQL*Plus
rem (условие выборки операций можно модифицировать)
rem *********************************************************
store set defaultenv replace
set newpage 0
set pagesize 0
set echo off
set feedback off
set heading off
set verify off
set serveroutput on size 900000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;

host md log

spool log\&oxxx..err
begin
  for c in (select id,class_id,short_name,status from methods
    where ((status<>'VALID' and flags<>'Z') or (status='INVALID' and flags='Z')) and class_id not in ('CONV_57','CONV_APPL')
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
@defaultenv
host del  defaultenv.sql