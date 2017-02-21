set termout off

column xxx new_value AUDITOR noprint;
select USER xxx from dual;

column xxx new_value PARTITIONS noprint
select '&&USEPARTITIONS' xxx from dual;
select value xxx from settings where owner='&&AUDITOR' and name='PARTITIONS';

column xxx new_value TIME noprint
select to_char(sysdate, 'HH24_MI_SS') xxx from dual;
set termout on

spool upgrade_&&TIME..log

prompt
prompt Actual Partition Option: &&USEPARTITIONS
define PARTITIONS = &&PARTITIONS --accept PARTITIONS char format a30 prompt 'Using Partitions for Diarys [&&PARTITIONS]: ' default &&PARTITIONS
prompt
define TUSER = &&AUD_SERVICE_TUSERS --accept TUSER   char format a30 prompt 'Tablespace for TABLES [&&AUD_SERVICE_TUSERS]: ' default &&AUD_SERVICE_TUSERS
define TSPACEI = &&AUD_SERVICE_TSPACEI --accept TSPACEI char format a30 prompt 'Tablespace for INDEXES [&&AUD_SERVICE_TSPACEI]: ' default &&AUD_SERVICE_TSPACEI

@../UTILS/chk_sets
@../UTILS/chk_tsps '&&TUSER, &&TSPACEI'

prompt
prompt Stop all background processes and press ENTER to continue...
--pause

set echo on
echo 'aud_set'
@@aud_set
@@aud_prt
@@aud_mes
@@aud_lic

set echo off
@settings/defaults
set echo on

insert into diary_tables
  select
    '_AUD', &&DIARY, 'DIARY', null, null, null, null, tablespace_name, null, null, freelists
  from
    user_indexes where index_name='PK_DIARY_ID';
insert into diary_indexes
  select
    '_AUD', &&DIARY, 'PK_DIARY_ID', 'T', 'ID', initial_extent, next_extent
  from
    user_indexes where index_name='PK_DIARY_ID';

insert into diary_tables
  select
    '_AUD', &&DIARY_PARAM, 'DIARY_PARAM', null, null, null, null, tablespace_name, null, null, freelists
  from
    user_indexes where index_name='IDX_DIARY_PARAM_DIARY_ID';
insert into diary_indexes
  select
    '_AUD', &&DIARY_PARAM, 'IDX_DIARY_PARAM_DIARY_ID', 'F', 'DIARY_ID', initial_extent, next_extent
  from
    user_indexes where index_name='IDX_DIARY_PARAM_DIARY_ID';

insert into diary_tables
  select
    '_AUD', &&VALUES_HISTORY, 'VALUES_HISTORY', null, null, null, null, tablespace_name, null, null, freelists
  from
    user_indexes where index_name='IDX_VALUES_HISTORY_OBJ_ID';
insert into diary_indexes
  select
    '_AUD', &&VALUES_HISTORY, 'IDX_VALUES_HISTORY_OBJ_ID', 'F', 'OBJ_ID', initial_extent, next_extent
  from
    user_indexes where index_name='IDX_VALUES_HISTORY_OBJ_ID';

insert into diary_tables
  select
    '_AUD', &&OBJECT_STATE_HISTORY, 'OBJECT_STATE_HISTORY', null, null, null, null, tablespace_name, null, null, freelists
  from
    user_indexes where index_name='IDX_OSH_OBJ_ID';
insert into diary_indexes
  select
    '_AUD', &&OBJECT_STATE_HISTORY, 'IDX_OSH_OBJ_ID', 'F', 'OBJ_ID', initial_extent, next_extent
  from
    user_indexes where index_name='IDX_OSH_OBJ_ID';

set echo off
commit;

@packages/util1
@packages/clear1
@packages/mail1
@packages/conv1
@packages/lic1
@packages/iefile1
@packages/iedb34_1
@packages/iedb54_1
@packages/iedb61_1
@packages/util2
@packages/clear2
@packages/mail2
@packages/conv2
@packages/lic2.plb
@packages/iefile2
@packages/iedb34_2
@packages/iedb54_2
@packages/iedb61_2

exec dbms_session.reset_package

prompt Loading Data Into Messages table...

exec utils.set_value('&&AUDITOR','PARTITIONS','&&PARTITIONS','Partitioning Option')
delete messages where topic not in ('SUBJ','BODY') or code like 'LOG%' or code like 'EDOC%';
delete messages where topic not in ('SUBJ','BODY') or code like 'LOG%' or code like 'EDOC%';
commit;

-- �������� �������� �����������
set termout off
column xxx new_value ConnStr noprint
select :constr xxx from dual;
host &&SqlLoader &&ConnStr 
undef ConnStr
set termout on

exec utils.set_value('&&AUDITOR','PARTITIONS','&&PARTITIONS','Partitioning Option')
commit;

prompt ������ ���� AUDIT_ADMIN ���� ��� ����
@upgrade/drop_role_audit_admin 0

exec utils.roles

spool off

