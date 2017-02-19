rem **************************************************************************
rem Один поток компиляции
rem **************************************************************************
declare
i pls_integer;
s varchar2(32767);
n pls_integer;
msg1 varchar2(10000);
msg2 varchar2(10000);
w_d boolean;
b_i boolean;
c_m boolean;
v_meth_id varchar2(256);
s2pipe varchar2(32767);
s_comp integer;
lCompile boolean;
pipe_name varchar2(128);
begin
  stdio.setup_pipes(null,null,null,300000);
  DBMS_APPLICATION_INFO.SET_MODULE(module_name=>'COMPILE$THREAD',action_name=>'BEGIN');
  i:=rtl.open;
  lCompile:= false;
  pipe_name:= stdio.STDIOPIPENAME || rtl.session_id;  -- Имя приватного канала для каждой сессии
  while true loop
      n:= stdio.get_line_pipe(s, pipe_name);

      if lCompile then 
         if n=0 then 
             if s is not null then
                 v_meth_id:= rtrim(s, constant.LF);
                 begin
                    select class_id||'.'||short_name into s2pipe from methods where id=v_meth_id;
                    if c_m then
                        msg1 := null;
                        begin
                          s_comp := method.recompile(v_meth_id, w_d); 
                        exception when others then
                          msg1 := 'Ошибка при recompile: ' || sqlerrm;
                          s_comp := -9;
                        end;
                    end if;
                    if b_i  then
                       msg2 := method_mgr.build_interface(v_meth_id);
                    end if;
                    s2pipe:= to_char(s_comp) || ' ' || s2pipe;
                    if msg1 is not null then
                      s2pipe:= s2pipe || chr(10) || '        ' || msg1;
                    end if;
                    if instr(msg2, constant.METH_ERROR||'-'||'NO_INTERFACE:') > 0 then
                      null; -- если просто отсутствует экранная форма, то ничего не выводим
                    elsif msg2 is not null then
                      s2pipe:= s2pipe || chr(10) || '        ' || msg2;
                    end if;
                 exception when no_data_found then 
                        s2Pipe:= 'Не найден метод с ID=' || v_meth_id;
                 end;
                 stdio.put_line_pipe('COMPILE;' || s2pipe, 'DEBUG$COMPILE$SERV$' || rtl.session_id);
             end if;
         else
             pipe_name:= stdio.STDIOPIPENAME || rtl.session_id;
             lCompile:= false;
             DBMS_APPLICATION_INFO.SET_ACTION('SLEEP');
             stdio.put_line_pipe('SLEEP', 'DEBUG$COMPILE$SERV$' || rtl.session_id);
         end if;
      else
         if n=0 then 
             if s='INIT' then
                stdio.put_line_pipe('READY', 'DEBUG$COMPILE$SERV$' || rtl.session_id);
             elsif s='END$COMPILE' then
                exit;
             elsif s like 'BEGIN$COMPILE;%' then 
                w_d:= instr(s, '$$$WITH_DEPENDENCIES$$$') > 0;
                b_i:= instr(s, '$$$BUILD_INTERFACE$$$') > 0;
                c_m:= instr(s, '$$$COMPILE_METHODS$$$') > 0;
                DBMS_APPLICATION_INFO.SET_ACTION('COMPILE');
                lCompile:= true;
                pipe_name:= 'DEBUG$COMPILE';
             end if;
         else
            -- utils.sleep(3);
            null;
         end if;
      end if;

  end loop;
  rtl.close(i);
exception when others then
  stdio.put_line_pipe('COMPILE; ' || s2pipe || sqlerrm, 'DEBUG$COMPILE$SERV$' || rtl.session_id);
  rtl.close(i);
end;
/
quit