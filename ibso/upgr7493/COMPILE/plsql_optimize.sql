prompt Перекомпиляция пакетов с PLSQL_OPTIMIZE_LEVEL

begin
  
  for c in (
   select upos.name, 'alter package ' || upos.name || ' compile body PLSQL_OPTIMIZE_LEVEL=0' recompile_command
   from user_plsql_object_settings upos, user_objects uo
   where upos.type='PACKAGE BODY'
     and upos.name in ('PLP$PARSER','PLIB','PLP2PLSQL','PLP2JAVA','DICT_MGR')
     and upos.name=uo.object_name and  upos.type=uo.object_type
     and (uo.status<>'VALID' or  upos.plsql_optimize_level<>0)
     )
   loop
     stdio.put_line_buf(c.name);
     begin
       execute immediate c.recompile_command;
       stdio.put_line_buf('No errors');
     exception when others then
       stdio.put_line_buf(sqlerrm);  
       stdio.put_line_buf(class_utils.package_errors(c.name));
     end;
   end loop;
   
end;
/