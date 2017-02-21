rem *********************************************************
rem Анализ форм операций и вывод найденных ошибок
rem Запускается из-под SQL*Plus
rem *********************************************************
set serveroutput on
spool err_ctl.log
exec stdio.enable_buf(1000000)
exec stdio.enable_buf(10000000)
declare
  s varchar2(32000);
begin
  for c in (
        select class_id||'.'||short_name nam,id from methods m
         where kernel='0' and flags <> constant.METHOD_LIBRARY
           and exists (select * from controls where meth_id = m.id)
         order by 1
           )
  loop
    s:=forms_mgr.check_controls(c.id,false);
    if s is not null then
      stdio.put_line_buf('*** '||c.nam||'('||c.id||')'||chr(10)||s);
    end if;
  end loop;
end;
/
spool off

