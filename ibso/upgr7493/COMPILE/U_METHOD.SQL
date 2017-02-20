exec executor.setnlsparameters
declare
/*
    $Author: Alexey $
    Дополнительный скрипт, используется в C_METHOD.SQL
   (в нем можно модифицировать условие выборки операций - m_cursor)
*/
m_cursor method.methods_cursor_t;
n   pls_integer;
pipe   varchar2(100);
v_plsql boolean := true;
    procedure upd_rtl(p_pack varchar2, p_retry boolean) is
        v_pack varchar2(30) := p_pack||'.%';
    begin
        select count(1) into n from rtl_entries
         where method_id='PL_SQL' and name like v_pack and rownum<2 and id>0;
        if n>0 then
            delete rtl_parameters where rtl_id in
              (select id from rtl_entries where method_id=p_pack and id>0);
            delete rtl_entries where method_id=p_pack and id>0;
            update rtl_entries set
                method_id = p_pack,
                name = substr(name,instr(name,'.')+1)
             where method_id='PL_SQL' and name like v_pack and id>0;
            commit;
        elsif p_retry then
            plib.parse_package(p_pack);
            upd_rtl(p_pack,false);
        end if;
    end;
begin
    pipe := nvl('&&pipe_name','COMPILE$'||USER);
    n:=rtl.open;
    rtl.set_debug(0,rtl.DEBUG2BUF,1000000);
    if v_plsql then
        method.process_plsql(pipe);
        upd_rtl('CALENDAR',true);
        upd_rtl('RC$INTER',true);
        upd_rtl('STDIO',true);
        upd_rtl('UTILS',true);
    end if;
    open m_cursor for
    select id,class_id,short_name from methods m
        where kernel='0' and ( flags<>'Z'
           or flags ='Z' and ( nvl(m.status,'NOT COMPILED')<>'NOT COMPILED'
              or m.package_name is not null ) ) /*and
        --(m.status='UPDATED' or m.status='NOT COMPILED') and
       (m.status<>'VALID'
        or not exists
        (select * from user_objects o
          where o.object_name = m.package_name
            and o.object_type = 'PACKAGE BODY')
        or exists
        (select * from user_objects o
          where o.object_name = m.package_name
            and o.object_type = 'PACKAGE BODY'
            and o.status!='VALID')
        and exists
        (select * from user_errors e where e.name = m.package_name)
       )*/
    ;
    method.compile_methods(m_cursor,pipe,true);
end;
/
