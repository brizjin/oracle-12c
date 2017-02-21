rem *********************************************************
rem �������������� �������� � ����������� �� PL/Plus � PL/SQL
rem ����������� ��-��� SQL*Plus
rem ����������� ��� PIPE ��� ������ ����������
rem ���������� �������������� ������ U_METHOD.SQL
rem (� ��� ����� �������������� ������� ������� ��������)
rem *********************************************************
rem define pipe_name = &&pipe_name --accept pipe_name char format a30 prompt 'Pipe Name [&&pipe_name]: ' default &&pipe_name
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set verify off
set serveroutput on size 500000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;
alter system flush shared_pool;
spool &oxxx..out
prompt �������� ���������� ��������
select 'Started  compiling methods - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@@u_method
select 'Finished compiling methods - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
set termout on
set feedback on
set heading on
