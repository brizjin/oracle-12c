rem **************************************************************************
rem Ќесоответстви€ имен колонок таблиц именам реквизитов классов
rem **************************************************************************

store set defaultenv replace

prompt _ѕоиск несоответствий имен колонок именам реквизитов
prompt _ѕротокол записываетс€ в файл cl_edit_columns.log

set termout off
set feedback off
set pagesize 0
set verify off
set linesize 1000

set serveroutput on size 1000000
exec stdio.enable_buf(1000000)
spool log\cl_edit_columns.log


exec stdio.put_line_buf('************************************************************')
exec stdio.put_line_buf('ѕоиск несоответствий имен колонок именам реквизитов')
exec stdio.put_line_buf('************************************************************')

declare
i pls_integer;
s varchar2(32767);
n pls_integer;
begin
  i:=rtl.open;
  -- —начала на вс€кий случай вычитаем канал
  while true loop
  	n:= stdio.get_line_pipe(s, 'DEBUG$CL_EDIT_COLUMNS');
  	if s is null then
            exit;
  	end if;
  end loop;
  storage_mgr.uncoord('SHOW',true,'DEBUG$CL_EDIT_COLUMNS');
  while true loop
  	n:= stdio.get_line_pipe(s, 'DEBUG$CL_EDIT_COLUMNS');

  	if n<>0 then
            exit;
  	end if;

  	if s like '__:__:%' then
         s:= '   ' || substr(s, 9);
  	end if;
  	if ltrim(s) is not null then 
          stdio.put_line_buf(s);
  	end if;
  end loop;

  rtl.close(i);
end;
/
spool off

@defaultenv

host del  defaultenv.sql