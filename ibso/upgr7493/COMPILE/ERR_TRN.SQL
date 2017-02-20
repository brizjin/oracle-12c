rem *********************************************************
rem Анализ форм операций и вывод найденных ошибок
rem Запускается из-под SQL*Plus
rem *********************************************************
set serveroutput on
spool err_trn.log
exec stdio.enable_buf(1000000)
exec stdio.enable_buf(10000000)
declare
  s varchar2(32000);
begin
  for c in (
        select id,name from classes
         where kernel='0' and init_state_id is not null
         order by 1
           )
  loop
    s:=method.check_transitions(c.id);
    if s is not null then
      stdio.put_line_buf('*** '||c.id||': '||c.name||chr(10)||s);
    end if;
  end loop;
end;
/
spool off

