rem *********************************************************
rem Перекомпиляция инвалидных объектов системы
rem Запускается из-под SQL*Plus
rem *********************************************************
set timi on
spool c_obj1.log

exec sys.utl_recomp.recomp_parallel(least(12,nvl(storage_mgr.get_storage_parameter('GLOBAL','CPU_COUNT')/2,4)),USER)

set timi off
set serveroutput on
exec stdio.enable_buf(1000000)
exec stdio.enable_buf(10000000)
declare
  p dbms_sql.varchar2s;
  n pls_integer;
begin
  select distinct name bulk collect into p
    from user_errors order by 1;
  n := p.count;
  for i in 1 .. n loop
    stdio.put_line_buf(class_utils.package_errors(p(i)));
  end loop;
end;
/

@@plsql_optimize

spool off


