exec dbms_session.reset_package
exec executor.setnlsparameters
exec stdio.enable_buf(1000000);
declare
/*
    $Author: Alexey $
    Создание интерфейсных пакетов операций.
    Запускается из-под SQL*Plus,
    запрашивает имя PIPE для вывода информации
*/
  pipe varchar2(100);
begin
  stdio.enable_buf(1000000);
  pipe := nvl('&&pipe_name','methods$'||user);
  method_mgr.rebuild_method_interfaces(pipe);
end;
/
