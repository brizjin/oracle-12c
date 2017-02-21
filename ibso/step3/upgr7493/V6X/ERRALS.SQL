rem *********************************************************
rem Анализ алиасов колонок представлений и вывод найденных ошибок
rem Запускается из-под SQL*Plus
rem (некритические ошибки исправляются)
rem *********************************************************
exec stdio.enable_buf
set serveroutput on size 1000000
declare
  s varchar2(30000);
begin
  for c in (
        select class_id||'.'||short_name nam,name,id from criteria
         order by 1
           )
  loop
    s:=data_views.check_aliases(c.id,null);
    if s is not null then
      stdio.put_line_buf('*** '||c.name||' ('||c.nam||' - '||c.id||')'||chr(10)||s);
    end if;
  end loop;
end;
/
