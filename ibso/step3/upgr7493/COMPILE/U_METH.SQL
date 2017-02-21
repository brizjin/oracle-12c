exec dbms_session.reset_package;
exec executor.dummy;
exec stdio.enable_buf(null,true);
exec stdio.enable_buf(null,true);
exec stdio.disable_buf;
exec executor.setnlsparameters
var n number
exec :n:=executor.lock_open;
exec executor.lock_read;

declare
    v_plsql boolean := true;
    procedure upd_rtl(p_pack varchar2, p_retry boolean) is
        v_pack varchar2(30) := p_pack||'.%';
        n   pls_integer;
    begin
        select count(1) into n from rtl_entries
         where method_id='PL_SQL' and name like v_pack and rownum<2 and id>0;
        if n>0 then
          begin
            delete rtl_parameters where rtl_id in
              (select id from rtl_entries where method_id=p_pack and id>0);
            delete rtl_entries where method_id=p_pack and id>0;
            update rtl_entries set
                method_id = p_pack,
                name = substr(name,instr(name,'.')+1)
             where method_id='PL_SQL' and name like v_pack and id>0;
            commit;
          exception when others then
            rollback;
          end;
        elsif p_retry then
            plib.parse_package(p_pack);
            upd_rtl(p_pack,false);
        end if;
    end;
begin
    if v_plsql then
        method.process_plsql(nvl('&&pipe_name','COMPILE$'||USER));
        upd_rtl('MESSAGE',true);
        upd_rtl('RC$INTER',true);
        upd_rtl('STDIO',true);
        upd_rtl('UTILS',true);
        upd_rtl('DBF',true);
    end if;
    stdio.disable_buf;
end;
/

declare
/*
    $Author: Alexey $
    Дополнительный скрипт, используется в C_METH.SQL
   (в нем можно модифицировать условие выборки операций - m_cursor)
*/
m_cursor method.methods_cursor_t;
mtd class_utils.id_tab;
n   pls_integer;
j   pls_integer;
cnt pls_integer;
str varchar2(2000);
pipe   varchar2(100);
begin
    pipe := nvl('&&pipe_name','COMPILE$'||USER);
    stdio.disable_buf;
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
    method.compile_methods(m_cursor,pipe,null);
    stdio.disable_buf;
    pipe := 'BUFFER$'||dbms_session.unique_session_id||'$'||USER;
    n := dbms_pipe.remove_pipe(pipe);
    n := dbms_pipe.remove_pipe(pipe||'$');
    dbms_pipe.reset_buffer;
    method.get_method_buf(mtd);
    n := mtd.first; cnt := 0;
    while n is not null loop
      cnt := cnt+1;
      str := 'prompt '||mtd(n).name||' ('||mtd(n).id||' - '||cnt||')'||constant.LF
          || 'EXEC Method.Recompile('''||mtd(n).id||''',false)';
      dbms_pipe.pack_message(str);
      j := dbms_pipe.send_message(pipe,1,5000000);
      if j<>0 then
        dbms_pipe.reset_buffer;
        dbms_pipe.pack_message(str);
        j := dbms_pipe.send_message(pipe,1,5000000);
      end if;
      n := mtd.next(n);
    end loop;
    stdio.disable_buf;
    rtl.set_debug(0,rtl.DEBUG2BUF,1000000);
    stdio.put_line_pipe('exec dbms_session.reset_package;'||constant.LF||
                        'exec executor.setnlsparameters;'||constant.LF||
                        'exec rtl.set_debug(0,rtl.DEBUG2BUF,100000)'||constant.LF||
                        'exec stdio.put_line_buf(executor.lock_open);'||constant.LF||
                        'exec executor.lock_read;'||constant.LF||constant.LF||
                        'prompt Found '||cnt||' methods, satisfying required condition'||constant.LF||
                        'prompt --- '||pipe||constant.LF,pipe||'$',1,10000,false);
    if j<>0 then
        stdio.put_line_pipe('prompt Error: Cannot make full compilation list'||constant.LF||
                            'prompt ----'||constant.LF,pipe,1,5000000);
    end if;
end;
/

exec stdio.enable_buf(1000000);
exec stdio.enable_buf(1000000);

