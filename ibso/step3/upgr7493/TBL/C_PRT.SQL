rem *********************************************************
rem ������������ ������ �����
rem ����������� ��-��� SQL*Plus
rem *********************************************************
set termout on
def pipe_name='DEBUG'
def usertables='user_tables'
def whereclause=''
--define PIPE_NAME = &&pipe_name --ACCEPT PIPE_NAME PROMPT 'Pipe Name (&&pipe_name) :' default &&pipe_name
--define V_VERSION = &&v_version --ACCEPT V_VERSION PROMPT 'IBSO version (&&v_version) :' default &&v_version
--define PATH = &&PATH --ACCEPT PATH  PROMPT 'Catalog for generating scripts (&&PATH) :' default &&PATH
--ACCEPT TSTAB PROMPT 'USER  tablespace (USERS):' default USERS
--ACCEPT TSIDX PROMPT 'Index tablespace (IDX):' default IDX
--ACCEPT IDXDROP PROMPT 'Dropping indexes (N):' default N
--ACCEPT DBSIZE  PROMPT 'Database block size (8192):' default 8192
set termout off
set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set verify off
set linesize 350
set arraysize 1
set trimspool on
set trimout on
set serveroutput on size 1000000
var v_ver number
column xxx new_value usertables noprint
select 'dba_tables' xxx from user_tab_columns where table_name='CLASS_TABLES' and column_name='OWNER';
column xxx new_value whereclause noprint
select 'and ut.owner=nvl(ct.owner,''&&gowner'')' xxx from user_tab_columns where table_name='CLASS_TABLES' and column_name='OWNER';
exec executor.setnlsparameters
exec stdio.enable_buf(1000000)
exec stdio.enable_buf(1000000)
exec :v_ver:=nvl(to_number('&&v_version','999.9'),1.0);
declare
  procedure ins(n number) is
  begin
    for c in (
      select ut.blocks, ct.class_id
        from &&usertables ut, class_tables ct
       where ut.table_name=ct.table_name &&whereclause
         and ct.table_name like 'Z#%'
         and not exists
       ( select 1 from project p where p.type='UPGRADE' and (p.build=n or p.name=ct.class_id))
       order by 1 desc
    ) loop
      insert into project (name,type,crt_user,mod_user,build,ord)
             values(c.class_id,'UPGRADE','&&tstab','&&tsidx', n, 1);
      exit;
    end loop;
  end;
begin
  if :v_ver<5.0 then
    ins(1);
    ins(2);
    ins(3);
    commit;
  end if;
end;
/
column xxx new_value oxxx noprint
select user xxx from dual;
spool &&path\&oxxx.-1.tbl
@@u_prt 1
spool off
spool &&path\&oxxx.-2.tbl
@@u_prt 2
spool off
spool &&path\&oxxx.-3.tbl
@@u_prt 3
spool off
spool &&path\&oxxx..tbl
@@u_prt 0
spool off
spool &&path\&oxxx.-X.tbl
select 'prompt Updating Storage for Dependent Classes' from dual;
select 'exec executor.setnlsparameters;' from dual where :v_ver>=5.0;
select 'exec stdio.put_line_buf(executor.lock_open);' from dual where :v_ver>=5.0;
select 'exec storage_mgr.create_dependent_classes(null,''&&pipe_name'');' from dual where :v_ver>=5.0;
spool off
set termout on
set feedback on
set heading on
set newpage 1
set pagesize 1000

