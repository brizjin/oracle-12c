rem *********************************************************
rem �������������� �������� � ����������� �� PL/Plus � PL/SQL
rem ����������� ��-��� SQL*Plus
rem ����������� ��� PIPE ��� ������ ����������
rem ���������� �������������� ������ U_METH.SQL
rem (� ��� ����� �������������� ������� ������� ��������)
rem *********************************************************
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set verify off
set serveroutput on size 300000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
def updcrit='null'
column xxx new_value updcrit noprint
select 'data_views.set_usercontext_used'  xxx from dual where '&2'='0' and '&1' in ('4','5');
column xxx new_value oxxx noprint
select user xxx from dual;
set termout on
spool &oxxx.&1-&2..out
prompt �������� ����������
select 'Started  compilation - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@&oxxx. &2
select 'Finished compilation - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
exec &&updcrit
spool off

set feedback on
set heading on

exit

