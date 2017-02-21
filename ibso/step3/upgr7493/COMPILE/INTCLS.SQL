exec dbms_session.reset_package
exec executor.setnlsparameters
exec stdio.put_line_buf(rtl.open)

declare
/*
    $Author: Alexey $
    Создание интерфейсных пакетов классов.
    Запускается из-под SQL*Plus,
    запрашивает имя PIPE для вывода информации.
*/
c_cursor class_mgr.class_cursor_t;
begin
    stdio.enable_buf(500000);
    open c_cursor for
    select id,name,base_class_id,target_class_id,parent_id from classes
     where id<>'RUNTIME'
    ;
    stdio.put_line_buf('Started  creating class interfaces - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)'));
    class_mgr.compile_classes(c_cursor,nvl('&&pipe_name','classes$'||user),true);
    stdio.put_line_buf(chr(10)||'Finished creating class interfaces - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)'));
end;
/

prompt clearing dependencies
delete dependencies where referencing_type='C' and referenced_type='C';
commit;

