rem *********************************************************
rem �������������� �������� � ����������� �� PL/Plus � PL/SQL
rem ����������� ��-��� SQL*Plus
rem ����������� ��� PIPE ��� ������ ����������
rem ���������� �������������� ������ U_MTD.SQL
rem (� ��� ����� �������������� ������� ������� ��������)
rem *********************************************************
set feedback off
set heading off

def pipe_name=DEBUG
rem define pipe_name = &&pipe_name --accept pipe_name char format a30 prompt 'Pipe Name [&&pipe_name]: ' default &&pipe_name

var mtd_cnt number
exec :mtd_cnt := &1

set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set serveroutput on size 300000
set linesize 250
set arraysize 1
set trimspool on
set trimout on
column xxx new_value oxxx noprint
select user xxx from dual;
alter system flush shared_pool;
alter session set session_cached_cursors=0;

column xxxx new_value params noprint
select ':pip'||decode(:mtd_cnt,
        2,',p_mode=>null',3,',p_mode=>null',
        10,',false,true,null',11,',false,false') xxxx
  from dual;

column xxxx new_value target_text noprint
select decode(:mtd_cnt,6,'2',7,'2',8,'2',9,'2',-1,'1','0') xxxx
  from dual;

column xxxx new_value mtd_cnt noprint
select 'u_mth'||:mtd_cnt xxxx from dual;

var pip varchar2(100)

spool &mtd_cnt..log
@@u_mth
exec :pip := 'BUFFER$'||dbms_session.unique_session_id
print pip
spool off

column xxxx new_value pip noprint
select :pip xxxx from dual;

column xxxx new_value mtd_cnt noprint
select :mtd_cnt xxxx from dual;


spool &oxxx..sql
prompt var pip varchar2(100)
prompt var dbg varchar2(100)
prompt exec :pip := '&&pip'
prompt exec :dbg := '&&pipe_name'
set define off
prompt exec :dbg := rtrim(:dbg||'&1','0')
set define on
prompt alter session set session_cached_cursors=0;;
prompt exec dbms_session.reset_package;
prompt exec executor.setnlsparameters
prompt exec stdio.put_line_buf('Session id: '||executor.lock_open)
prompt exec rtl.set_debug(0,rtl.DEBUG2BUF,100000)
prompt exec executor.lock_read
prompt exec executor.set_context('PLP_MAX_COUNTERS','1000')
prompt exec executor.set_context('PLP_DUMP_PIPE',:dbg)
prompt exec executor.set_context('METHOD_DEF_TARGET','&&target_text');
prompt exec storage_mgr.verbose := true
prompt exec storage_utils.verbose := true
prompt exec storage_mgr.pipe_name := :dbg
prompt exec storage_utils.pipe_name := :dbg
prompt print pip
prompt
prompt prompt Found &&mtd_cnt entries, satisfying required condition
prompt
prompt exec stdio.put_line_pipe('++ Compilation started',:dbg)
prompt
select 'exec method.process_pipe(&&params)'||chr(10) from methods where rownum <= :mtd_cnt;
prompt
prompt exec stdio.put_line_pipe('++ Compilation finished',:dbg)
prompt
spool off

set feedback on
set heading on

alter system flush shared_pool;

rem exit

