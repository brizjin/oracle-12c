rem **************************************************************************
rem ������������ ���������� �������������
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

prompt _������������ ���������� ������������� ...
prompt _�������� ������������ � ����� DEBUG$100 ...
prompt _����� ������� � ���� v_create.log ...


set termout on
spool v_create.log

declare
 r integer;
 pipe_name   varchar2(100) := 'DEBUG$100';
begin
 r:=rtl.open;
    stdio.put_line_pipe('**********************************************************',pipe_name);
    stdio.put_line_pipe('Started ������������ ���������� ������������� - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'),pipe_name);
    stdio.put_line_pipe('**********************************************************',pipe_name);

    dbms_output.put_line('Started ������������ ���������� ������������� - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'));

 storage_utils.verbose := true;
 storage_utils.pipe_name := pipe_name;

 after_install.recreate_vw_crit('1');

    stdio.put_line_pipe('**********************************************************',pipe_name);
    stdio.put_line_pipe('Finished ������������ ���������� ������������� - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'),pipe_name);
    stdio.put_line_pipe('**********************************************************',pipe_name);

    dbms_output.put_line('Finished ������������ ���������� ������������� - '||TO_CHAR(SYSDATE,'DD/MM/YY HH24:MI:SS'));

 storage_utils.verbose := false;

 rtl.close(r);
end;
/

spool off
set feedback on
set heading on

