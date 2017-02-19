rem **************************************************************************
rem Пересоздание несуществующих прикладных представлений
rem **************************************************************************

store set defaultenv replace

set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set serveroutput on size 1000000
set linesize 250
set arraysize 1
set trimspool on
set trimout on

prompt _Пересоздание представлений ...
prompt _Вывод ведется в файл v_create_invalid.log

set termout on


declare
  r integer;
begin

  dbms_output.put_line('Started Пересоздание невалидных прикладных представлений - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'));

  r:=rtl.open;

end;
/

set termout off
spool v_create_invalid_act.sql

select 
     ' begin ' || 
     '   Data_Views.Create_Vw_Crit(' || c.id || ');' ||
     ' exception when others then ' ||
     '      Dbms_OutPut.New_Line;' || 
     '      Dbms_OutPut.Put_Line(''' || c.class_id || '.' || c.short_name || ''');' ||
     '      Dbms_OutPut.Put_Line(substr(sqlerrm,1,255));' ||
     ' end;' || chr(10) || '/' 
     from criteria c, criteria c2
     where c.src_id=c2.id (+) and 
   	( exists (select 1 from user_objects
              where OBJECT_TYPE = 'VIEW' and OBJECT_NAME = nvl(c2.short_name, c.short_name)
                and status <> 'VALID')
          or
          not exists (select status from user_objects where 
		object_type='VIEW' and 
		object_name=nvl(c2.short_name, c.short_name) and status = 'VALID'))
      order by c.class_id, c.short_name;


spool off
set termout on
select 'Сформирован скрипт v_create_invalid_act.sql' from dual;
set termout off

host md log
spool log\v_create_invalid.log
@v_create_invalid_act.sql
spool off

host del v_create_invalid_act.sql

@defaultenv
host del defaultenv.sql
