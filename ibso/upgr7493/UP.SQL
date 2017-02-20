def APPSRV='NO'
def SIMPLE='NO'
def REPROLES='YES'
def CRSYN='YES'
def RPTKEEP='90'
def CRROLES='YES'

@@settings

SET TERMOUT OFF

def TSTAB='&&UP_TSTAB'
def TSIDX='&&UP_TSIDX'
def TSLOB='&&UP_TSLOB'
def TPART='&&UP_TPART'
def TPARTI='&&UP_TPARTI'
def TUSERS='&&UP_TUSERS'
def TSPACEI='&&UP_TSPACEI'
def DBSIZE='8192'
def RIGHTS='1'

var s varchar2(2000)
exec :s:='1.0'
exec :s:=inst_info.Version
column xxx new_value v_version noprint
select :s xxx from dual;
select owner xxx from project where name='V_VERSION' and type='SETTINGS';
exec :s:=inst_info.Get_Version
exec :s:=nvl(:s,inst_info.Version)

column xxx new_value crsyn noprint
select decode(substr(upper(value),1,1),'Y','YES','N','NO','&crsyn') xxx from profiles
 where profile='DEFAULT' and resource_name='CREATE_SYNONYMS' and substr(upper('&crsyn'),1,1) in ('Y','N');
column xxx new_value reproles noprint
select decode(param_value,'0','NO','140','YES',param_value) xxx from storage_parameters
 where param_group='GLOBAL' and param_name='MAX_REPORT_ROLES';
column xxx new_value dbsize noprint
select value xxx from v$parameter where name='db_block_size';
column xxx new_value rights noprint
select value xxx from settings where name='RIGHTS_CONTEXT';
column xxx new_value owner noprint
select user xxx from dual;

def IDXDROP='NO'
def AUDITOR='AUD'
def CHKPLS='NO'
def gowner='&&owner'
def downer1='&&owner'
def downer2='&&owner'

column xxx new_value ask noprint
select decode('&5','quiet','dummy','ask_pars') xxx from dual;

spool LOG\up.log

SET TERMOUT ON

Prompt * Upgrading of IB System Object to Version 7.4 Release (owner - &&owner)
Prompt * Log-files of Upgrade in catalogs: LOG, COMPILE, SQLLDR, U_SOURCE, AUDIT, AUDMGR

@utils/&&ask


SET TERMOUT OFF

alter session set nls_numeric_characters='.,' nls_sort=binary;
alter session set session_cached_cursors=0;

var db_version number
var db_release varchar2(100)

declare
  s1 varchar2(100);
  s2 varchar2(100);
begin
  dbms_utility.db_version(s1,s2);
  :db_release := s1;
  :db_version := substr(s1,1,instr(s1,'.')-1);
end;
/

column xxx new_value simple noprint
select decode('&&simple',
              'YES', decode(substr('&&v_version', 1, 1), '6', '3', decode('&&v_version', '7.1', '2', '7.0', '2', '1')),
              'NO', decode(substr('&&v_version', 1, 1), '6', '0', decode('&&v_version', '7.1', '3', '7.0', '3', '2')),
              decode(substr('&&v_version', 1, 1), '6', '3', decode('&&v_version', '7.1', '2', '7.0', '2', '2'))) xxx
  from dual;

column xxx new_value D_DROPINDEX noprint
select decode(sign(:db_version-9), 1, 'DROP INDEX', '') xxx from dual;

def ARGS=''
column xxx new_value ARGS noprint
select decode('&1', 'strict', '&&TSTAB, &&TSIDX, &&TSLOB, &&TPART, &&TPARTI, &&TUSERS, &&TSPACEI', '&&TUSERS, &&TSPACEI') xxx from dual;
SET TERMOUT ON
SET TIME ON

var constr varchar2(200)
exec :constr:='&2'
undef 2

column xxx new_value Oramon noprint
select decode('&4','pause',nvl('&&Oramon','pause'),'&4') xxx from dual;

column xxx new_value ask noprint
select decode('&5','quiet','put_sets','chk_sets') xxx from dual;

@UTILS/&&ask
@UTILS/chk_tsps '&&ARGS'

exec rtl.put_setting('RIGHTS_CONTEXT', '&&RIGHTS');

prompt Oracle Database Version
print db_version
print db_release

prompt IBSO kernel Version
print s

prompt Saving v_version for upgrade
delete project where type='SETTINGS' and name in ('V_VERSION','SIMPLE');
insert into project (name,type,owner)
  values ('V_VERSION','SETTINGS','&&v_version');
insert into project (name,type,owner)
  values ('SIMPLE','SETTINGS','&&simple');
commit;

@UTILS/alt_sys_enable_restricted_session
alter session set sort_area_size=83886080;

PROMPT Stopping background jobs...
exec lock_info.stop;

@compile/show_status

@UTILS/chk_trig

spool off

@compile/c_delses

-- ��������� ��������� ��
column xxx new_value up noprint
select decode('&&simple','1','dummy','2','up1_2','3','up1_3','up1_all') xxx from dual;

exec dbms_session.reset_package

@utils/&&up

-- C�������� �������������� �������� (��������� ��������� ��������, ������ ������ restricted session)
spool LOG\up_add.log
@utils/temp_lic
@UTILS/alt_sys_disable_restricted_session
exec dbms_session.free_unused_user_memory;
alter system flush shared_pool;
spool off

-- Check kernel packages
@utils/chk_pkg

-- ����� ����� ��������� �������� ���������������� �������
column xxx new_value ConnStr noprint
select :constr xxx from dual;
host oramons.bat &&Oramon &&ConnStr &&owner &3
undef ConnStr
host title STEP 1.1. Change dictionary objects...

exec dbms_session.reset_package

-- Gather errors before compilation
@compile/show_err

-- ������������� ��������� ��
column xxx new_value up noprint
select decode('&&simple','1','dummy','2','up2_2','3','up2_3','up2_all') xxx from dual;

exec dbms_session.reset_package
exec dbms_session.free_unused_user_memory;
alter system flush shared_pool;

@utils/&&up

-- ������������ ����� ��� ������������ �������
@utils/c_syn.sql

-- Kernel classes/methods/synonyms
spool log\krnlobj.log
prompt methods with possibly incorrect use of %class
@utils/meta_err.sql
prompt classes with too many fields/columns, that can cause errors in class interfaces
@utils/chk_cols.sql
@utils/proj.sql
exec stdio.put_line_buf(executor.lock_open)
exec lock_info.run
prompt disable trigger on classes
alter trigger CLASSES_AFTER_INS_TAB disable;
exec patch_tool.update_kern_cls_and_meth;
alter trigger CLASSES_AFTER_INS_TAB enable;
select inst_info.get_version from dual;
spool off

-- Information about packages/indexes/constraints
@compile/revis
@compile/get_sys

exit

