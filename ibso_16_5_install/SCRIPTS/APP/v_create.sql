rem **************************************************************************
rem Пересоздание прикладных представлений
rem **************************************************************************

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

prompt _Пересоздание прикладных представлений ...
prompt _Протокол записывается в канал DEBUG$100 ...
prompt _Вывод ведется в файл v_create.log ...


set termout on
spool v_create.log

declare
 r integer;
 pipe_name   varchar2(100) := 'DEBUG$100';
begin
 r:=rtl.open;
    stdio.put_line_pipe('**********************************************************',pipe_name);
    stdio.put_line_pipe('Started Пересоздание прикладных представлений - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'),pipe_name);
    stdio.put_line_pipe('**********************************************************',pipe_name);

    dbms_output.put_line('Started Пересоздание прикладных представлений - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'));

 storage_utils.verbose := true;
 storage_utils.pipe_name := pipe_name;

 after_install.recreate_vw_crit('1');

    stdio.put_line_pipe('**********************************************************',pipe_name);
    stdio.put_line_pipe('Finished Пересоздание прикладных представлений - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'),pipe_name);
    stdio.put_line_pipe('**********************************************************',pipe_name);

    dbms_output.put_line('Finished Пересоздание прикладных представлений - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'));

 storage_utils.verbose := false;

 rtl.close(r);
end;
/

spool off
set feedback on
set heading on

