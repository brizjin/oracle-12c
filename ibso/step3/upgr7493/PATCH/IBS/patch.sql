set serveroutput on size 1000000

var constr varchar2(200)
exec :constr:='&1'
undef 1

@@../settings
@@UTILS/patch_settings

SET TERMOUT OFF

column xxx new_value ConnStr noprint
select :constr xxx from dual;

column yyy new_value log_file_name noprint
select 'LOG\ibs_'||to_char(sysdate,'YYYYMMDD_hh24mi')||'.log' yyy from dual;

def TSTAB='&&UP_TSTAB'
def TSIDX='&&UP_TSIDX'
def TSLOB='&&UP_TSLOB'
def TPART='&&UP_TPART'
def TPARTI='&&UP_TPARTI'
def TUSERS='&&UP_TUSERS'
def TSPACEI='&&UP_TSPACEI'
def DBSIZE='8192'

column xxx new_value owner noprint
select user xxx from dual;

def gowner='&&owner'
def downer1='&&owner'
def downer2='&&owner'

column xxx new_value ask noprint
select decode('&&2','quiet','..\UTILS\dummy','IBS\ask_pars') xxx from dual;

SET TERMOUT ON

spool &log_file_name

prompt  
prompt -------------------------------------------------------------------------------- 

prompt �������� ����������� ��������� �����
prompt 

@@check_install_ibs
print mess
@@../UTILS/exit_when ':can_run_patch = 0'

prompt  
prompt -------------------------------------------------------------------------------- 

prompt ������ ��������� �����
prompt 

@@&&ask

set timi on

@@../UTILS/alt_sys_enable_restricted_session

prompt Stopping lock_info
exec executor.lock_stop


prompt  
prompt -------------------------------------------------------------------------------- 

spool off

spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ����������� �������� � ��������� INVALID
prompt 

var invalid_objects_before varchar2(4000);
var cntInvBefore number;

declare 
tab dbms_utility.lname_array;
begin
select object_name BULK COLLECT INTO tab from user_objects 
	where status='INVALID' and object_type='PACKAGE BODY' 
	and object_name not like 'Z$%' and object_name not like 'Z#%' and object_name not like 'ZZ$%' 
	order by object_name;

dbms_utility.table_to_comma(tab, :cntInvBefore, :invalid_objects_before);
end;
/

print invalid_objects_before

spool off



spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt �������� �������� �����������
prompt 

@@../UTILS/alt_sys_disable_restricted_session

spool off


host tblload_ibs.bat &&ConnStr


spool &log_file_name append
prompt �������� �������� ����������� ���������, log-����� � ����� SQLLDR

@@../UTILS/alt_sys_enable_restricted_session

spool off

spool &log_file_name append

prompt
prompt --------------------------------------------------------------------------------

prompt ������ BeforeInstall �������� �� ������� UPDATE_JOURNAL. ������ LOG\ibs_before_install_pkg.log
prompt 
spool off

@@../PACKAGES/opt/before_install_pkg



spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ���������� ������� 
prompt 

prompt EDOC
@../Packages/opt/edoc1.SQL
prompt SC_MGR
@../Packages/opt/sc1.SQL
prompt PLP2JAVA
@../Packages/opt/2jc1.SQL

set timing on

prompt SC_MGR
@../Packages/opt/sc2.sql

prompt PLP2JAVA
@../Packages/opt/2jc2

prompt EDOC
@../Packages/opt/edoc2.sql


prompt install ..\PACKAGES\INIT1.SQL
@@../PACKAGES/INIT1.SQL

prompt install ..\PACKAGES\INIT2.SQL
@@../PACKAGES/INIT2.SQL

prompt install ..\PACKAGES\2PLSQL1.SQL
@@../PACKAGES/2PLSQL1.SQL

prompt install ..\PACKAGES\ATR_MGR1.SQL
@@../PACKAGES/ATR_MGR1.SQL

prompt install ..\PACKAGES\CACHE_MGR1.SQL
@@../PACKAGES/CACHE_MGR1.SQL

prompt install ..\PACKAGES\CONSTNT_EXT1.SQL
@@../PACKAGES/CONSTNT_EXT1.SQL

prompt install ..\PACKAGES\EXECUTOR\EXECUTR1.SQL
@@../PACKAGES/EXECUTOR/EXECUTR1.SQL

prompt install ..\PACKAGES\FRM_MGR1.SQL
@@../PACKAGES/FRM_MGR1.SQL

prompt install ..\PACKAGES\IDX_MGR1.SQL
@@../PACKAGES/IDX_MGR1.SQL

prompt install ..\PACKAGES\LIB1.SQL
@@../PACKAGES/LIB1.SQL

prompt install ..\PACKAGES\METHOD1.SQL
@@../PACKAGES/METHOD1.SQL

prompt install ..\PACKAGES\NAV1.SQL
@@../PACKAGES/NAV1.SQL

prompt install ..\PACKAGES\PLIB1.SQL
@@../PACKAGES/PLIB1.SQL

prompt install ..\PACKAGES\RUNPROC1.SQL
@@../PACKAGES/RUNPROC1.SQL

prompt install ..\PACKAGES\SVIEWS1.SQL
@@../PACKAGES/SVIEWS1.SQL

prompt install ..\PACKAGES\SYSINFO1.SQL
@@../PACKAGES/SYSINFO1.SQL

prompt install ..\PACKAGES\ADM_MGR1.SQL
@@../PACKAGES/ADM_MGR1.SQL

prompt install ..\PACKAGES\AI1.SQL
@@../PACKAGES/AI1.SQL

prompt install ..\PACKAGES\CACHE_SERVICE1.SQL
@@../PACKAGES/CACHE_SERVICE1.SQL

prompt install ..\PACKAGES\CALEN_MGR1.SQL
@@../PACKAGES/CALEN_MGR1.SQL

prompt install ..\PACKAGES\CLASS1.SQL
@@../PACKAGES/CLASS1.SQL

prompt install ..\PACKAGES\CLS_UT1.SQL
@@../PACKAGES/CLS_UT1.SQL

prompt install ..\PACKAGES\CONTEXT_INFORMATION1.SQL
@@../PACKAGES/CONTEXT_INFORMATION1.SQL

prompt install ..\PACKAGES\CRITICAL_LOCK_SERVICE1.SQL
@@../PACKAGES/CRITICAL_LOCK_SERVICE1.SQL

prompt install ..\PACKAGES\DATA1.SQL
@@../PACKAGES/DATA1.SQL

prompt install ..\PACKAGES\DELAYED_ACTION_MGR1.SQL
@@../PACKAGES/DELAYED_ACTION_MGR1.SQL

prompt install ..\PACKAGES\DICT_MG1.SQL
@@../PACKAGES/DICT_MG1.SQL

prompt install ..\PACKAGES\MET_MGR1.SQL
@@../PACKAGES/MET_MGR1.SQL

prompt install ..\PACKAGES\OPT_MGR1.SQL
@@../PACKAGES/OPT_MGR1.SQL

prompt install ..\PACKAGES\PARSER1.SQL
@@../PACKAGES/PARSER1.SQL

prompt install ..\PACKAGES\PART1.SQL
@@../PACKAGES/PART1.SQL

prompt install ..\PACKAGES\PARTITIONING_MGR1.SQL
@@../PACKAGES/PARTITIONING_MGR1.SQL

prompt install ..\PACKAGES\PARTITIONING_UTILS1.SQL
@@../PACKAGES/PARTITIONING_UTILS1.SQL

prompt install ..\PACKAGES\PARTITIONING_VIEW1.SQL
@@../PACKAGES/PARTITIONING_VIEW1.SQL

prompt install ..\PACKAGES\REPL_UT1.SQL
@@../PACKAGES/REPL_UT1.SQL

prompt install ..\PACKAGES\RTL_TYPES1.SQL
@@../PACKAGES/RTL_TYPES1.SQL

prompt install ..\PACKAGES\RTL_UTILS1.SQL
@@../PACKAGES/RTL_UTILS1.SQL

prompt install ..\PACKAGES\SA1.SQL
@@../PACKAGES/SA1.SQL

prompt install ..\PACKAGES\SEC1.SQL
@@../PACKAGES/SEC1.SQL

prompt install ..\PACKAGES\SESSION_INITIALIZATION_SERVICE1.SQL
@@../PACKAGES/SESSION_INITIALIZATION_SERVICE1.SQL

prompt install ..\PACKAGES\SESSION_SERVICE1.SQL
@@../PACKAGES/SESSION_SERVICE1.SQL

prompt install ..\PACKAGES\STOR_UT1.SQL
@@../PACKAGES/STOR_UT1.SQL

prompt install ..\PACKAGES\STORAGE1.SQL
@@../PACKAGES/STORAGE1.SQL

prompt install ..\PACKAGES\UTILS1.SQL
@@../PACKAGES/UTILS1.SQL

prompt install ..\PACKAGES\VALMGR1.SQL
@@../PACKAGES/VALMGR1.SQL

prompt install ..\PACKAGES\2PLSQL2.SQL
@@../PACKAGES/2PLSQL2.SQL

prompt install ..\PACKAGES\CACHE_MGR2.SQL
@@../PACKAGES/CACHE_MGR2.SQL

prompt install ..\PACKAGES\EXECUTOR\EXECUTR2.PLB
@@../PACKAGES/EXECUTOR/EXECUTR2.PLB

prompt install ..\PACKAGES\FRM_MGR2.PLB
@@../PACKAGES/FRM_MGR2.PLB

prompt install ..\PACKAGES\METHOD2.PLB
@@../PACKAGES/METHOD2.PLB

prompt install ..\PACKAGES\NAV2.SQL
@@../PACKAGES/NAV2.SQL

prompt install ..\PACKAGES\PLIB2.PLB
@@../PACKAGES/PLIB2.PLB

prompt install ..\PACKAGES\RUNPROC2.SQL
@@../PACKAGES/RUNPROC2.SQL

prompt install ..\PACKAGES\SVIEWS2.PLB
@@../PACKAGES/SVIEWS2.PLB

prompt install ..\PACKAGES\SYSINFO2.SQL
@@../PACKAGES/SYSINFO2.SQL

prompt install ..\PACKAGES\ADM_MGR2.PLB
@@../PACKAGES/ADM_MGR2.PLB

prompt install ..\PACKAGES\AI2.PLB
@@../PACKAGES/AI2.PLB

prompt install ..\PACKAGES\ATR_MGR2.PLB
@@../PACKAGES/ATR_MGR2.PLB

prompt install ..\PACKAGES\BINDING2.SQL
@@../PACKAGES/BINDING2.SQL

prompt install ..\PACKAGES\CACHE_SERVICE2.SQL
@@../PACKAGES/CACHE_SERVICE2.SQL

prompt install ..\PACKAGES\CALEN_MGR2.PLB
@@../PACKAGES/CALEN_MGR2.PLB

prompt install ..\PACKAGES\CLASS2.PLB
@@../PACKAGES/CLASS2.PLB

prompt install ..\PACKAGES\CLS_UT2.PLB
@@../PACKAGES/CLS_UT2.PLB

prompt install ..\PACKAGES\CONTEXT_INFORMATION2.PLB
@@../PACKAGES/CONTEXT_INFORMATION2.PLB

prompt install ..\PACKAGES\CRITICAL_LOCK_SERVICE2.PLB
@@../PACKAGES/CRITICAL_LOCK_SERVICE2.PLB

prompt install ..\PACKAGES\DATA2.PLB
@@../PACKAGES/DATA2.PLB

prompt install ..\PACKAGES\DELAYED_ACTION_MGR2.SQL
@@../PACKAGES/DELAYED_ACTION_MGR2.SQL

prompt install ..\PACKAGES\DICT_MG2.PLB
@@../PACKAGES/DICT_MG2.PLB

prompt install ..\PACKAGES\IDX_MGR2.SQL
@@../PACKAGES/IDX_MGR2.SQL

prompt install ..\PACKAGES\JOB_WRAPPER2.PLB
@@../PACKAGES/JOB_WRAPPER2.PLB

prompt install ..\PACKAGES\LCONV2.SQL
@@../PACKAGES/LCONV2.SQL

prompt install ..\PACKAGES\LIB2.SQL
@@../PACKAGES/LIB2.SQL

prompt install ..\PACKAGES\MAP_MGR2.SQL
@@../PACKAGES/MAP_MGR2.SQL

prompt install ..\PACKAGES\MET_MGR2.SQL
@@../PACKAGES/MET_MGR2.SQL

prompt install ..\PACKAGES\OPT_MGR2.PLB
@@../PACKAGES/OPT_MGR2.PLB

prompt install ..\PACKAGES\PARSER2.SQL
@@../PACKAGES/PARSER2.SQL

prompt install ..\PACKAGES\PART2.PLB
@@../PACKAGES/PART2.PLB

prompt install ..\PACKAGES\PARTITIONING_MGR2.PLB
@@../PACKAGES/PARTITIONING_MGR2.PLB

prompt install ..\PACKAGES\PARTITIONING_UTILS2.PLB
@@../PACKAGES/PARTITIONING_UTILS2.PLB

prompt install ..\PACKAGES\PARTITIONING_VIEW2.PLB
@@../PACKAGES/PARTITIONING_VIEW2.PLB

prompt install ..\PACKAGES\PATCH_TOOL2.PLB
@@../PACKAGES/PATCH_TOOL2.PLB

prompt install ..\PACKAGES\REPL2.SQL
@@../PACKAGES/REPL2.SQL

prompt install ..\PACKAGES\REPL_UT2.SQL
@@../PACKAGES/REPL_UT2.SQL

prompt install ..\PACKAGES\REPORT2.PLB
@@../PACKAGES/REPORT2.PLB

prompt install ..\PACKAGES\RTL1_2.PLB
@@../PACKAGES/RTL1_2.PLB

prompt install ..\PACKAGES\RTL_TYPES2.SQL
@@../PACKAGES/RTL_TYPES2.SQL

prompt install ..\PACKAGES\RTL_UTILS2.PLB
@@../PACKAGES/RTL_UTILS2.PLB

prompt install ..\PACKAGES\RULE2.PLB
@@../PACKAGES/RULE2.PLB

prompt install ..\PACKAGES\SA2.PLB
@@../PACKAGES/SA2.PLB

prompt install ..\PACKAGES\SEC2.PLB
@@../PACKAGES/SEC2.PLB

prompt install ..\PACKAGES\SESSION_INITIALIZATION_SERVICE2.PLB
@@../PACKAGES/SESSION_INITIALIZATION_SERVICE2.PLB

prompt install ..\PACKAGES\SESSION_SERVICE2.PLB
@@../PACKAGES/SESSION_SERVICE2.PLB

prompt install ..\PACKAGES\STOR_UT2.SQL
@@../PACKAGES/STOR_UT2.SQL

prompt install ..\PACKAGES\STORAGE2.PLB
@@../PACKAGES/STORAGE2.PLB

prompt install ..\PACKAGES\UTILS2.SQL
@@../PACKAGES/UTILS2.SQL

prompt install ..\PACKAGES\VALMGR2.PLB
@@../PACKAGES/VALMGR2.PLB

prompt install ..\PACKAGES\PROC.SQL
@@../PACKAGES/PROC.SQL

spool off

spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt �������������� ���������� �������� �������. 
prompt 

spool off
alter system flush shared_pool;

set timi off
@@../COMPILE/c_pack
set timi on

@@../COMPILE/c_obj1

-- ������� �������
@@../COMPILE/parse_pack

alter system flush shared_pool;


spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ������ AfterInstall �������� �� ������� UPDATE_JOURNAL. ������ LOG\ibs_after_install_log
prompt 
spool off

@@../PACKAGES/opt/after_install_pkg


spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt �������� ��������� �����
prompt 

var invalid_objects_after varchar2(4000);
var cntInvAfter number;

declare 
tab dbms_utility.lname_array;
i number;
begin

select object_name BULK COLLECT INTO tab from user_objects 
	where status='INVALID' and object_type='PACKAGE BODY' 
	and object_name not like 'Z$%' and object_name not like 'Z#%' and object_name not like 'ZZ$%' 
	order by object_name;

i:= tab.first;
:invalid_objects_after := '';

while (i is not null) loop
  if instr(:invalid_objects_before, tab(i)) = 0 then
	:invalid_objects_after := :invalid_objects_after||chr(10)|| tab(i);
  end if;
  i := tab.next(i);
end loop;

if :invalid_objects_after is not null then
  :invalid_objects_after := chr(10)||chr(10)||'--------------------------------------------------------------------------------'
		||chr(10)||'!!!WARNING!!!'||chr(10)||'����� ������ ���������� ��������� ������ ������������� � ��������:'
		||:invalid_objects_after;
else
  :invalid_objects_after := chr(10)||'���� ���������� �������!';
end if;

end;
/

print invalid_objects_after


spool off



spool &log_file_name append

prompt  
prompt --------------------------------------------------------------------------------

prompt ���������� project

@@../utils/proj

prompt  
prompt --------------------------------------------------------------------------------

prompt ���������� ������� ���������� ��������

begin
execute immediate 'update update_journal set run_date= sysdate, version = inst_info.get_version where status = ''1'' and run_date is null';
commit;
exception when others then null;
end;
/

@@../UTILS/alt_sys_disable_restricted_session

prompt Running lock_info
exec stdio.put_line_buf(executor.lock_open)
exec lock_info.run


set timi off

prompt ���������� � packages/indexes/constraints
@@../compile/revis
@@../compile/get_sys

spool &log_file_name append
prompt  
prompt ����������� ������ ��
select inst_info.get_version version from dual;

spool off

exit
