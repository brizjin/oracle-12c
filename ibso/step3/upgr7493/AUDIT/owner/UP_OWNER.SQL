set termout off

define max_app='0'
column yyy new_value max_app noprint
select value yyy from audit_settings where owner='&&owner' and name='MAX_APP_SRV';

var s varchar2(2000);
begin
    select value into :s from settings where owner='&&OWNER' and name='DIARY';
    delete from settings where owner='&&OWNER' and name='DIARY';
exception when no_data_found then
    :s:='90';
end;
/
set termout on

prompt
define MAX_APP = &&MAX_APP --accept MAX_APP char format a30 prompt 'IBSO OWNER "&&owner" Max Number of Application Server Accounts [&&MAX_APP]: ' default &&MAX_APP

set echo on

insert into settings values (
    '&&OWNER','DIARY',:s,
    '������ �������� ����������� ������� ���������� �������� (���)');

insert into settings values (
    '&&OWNER','DIARY_UADMIN','90',
    '������ �������� ����������� ������� �������������� ������� (���)');

insert into settings values (
    '&&OWNER','DIARY_EVENTS','90',
    '������ �������� ����������� ������� ��������� ������� (���)');

insert into settings values (
    '&&OWNER','DIARY_ADMIN','UNLIMITED',
    '������ �������� ����������� ������� �������������� ������ (���)');

insert into settings values (
    '&&OWNER','DIARY_SES','UNLIMITED',
    '������ �������� ����������� ������� ���������������� ������ (���)');

insert into settings values (
    '&&OWNER','DIARY_LEVEL','USR|EQU|PRO|RUL|OBJ|CLS|CRI|TRA|MTH|',
    '������� �������������� ��������� ���� �������');

insert into settings values (
    '&&OWNER','METHODS','OPTIONAL',
    '������� �������������� ���������� ��������');

insert into settings values (
    '&&OWNER','OBJECT_STATE_HISTORY','90',
    '������ �������� ����������� ������� ����� ��������� (���)');

insert into settings values (
    '&&OWNER','OBJECT_COLLECTION_HISTORY','90',
    '������ �������� ����������� ������� ����� ��������� (���)');

insert into settings values (
    '&&OWNER','ROWS','100000',
    '����� �������������� �� ���� ��� �������');

insert into settings values (
    '&&OWNER','VALUES_HISTORY','90',
    '������ �������� ����������� ������� ������� ��������� ����������� (���)');

insert into settings values (
    '&&OWNER','BATTLE_PASS','A1B2C3',
    '����������������� ������ ��� �������� �������������');

insert into settings values (
    '&&OWNER','CHECK_USER','Z#USER.C_USERNAME',
    '�������� ������������� ������������ � ���������� ���������� (<T������>.<�������>)');

insert into settings values (
    '&&OWNER','VERSION', '&&OWN_VER', '������ �� ��������� IBSO');

insert into settings (
    select owner,'MAX_APP_SRV',nvl('&&MAX_APP','0'),
            '������������ ���������� ������� ������� ��� ������� ����������'
        from settings where owner='&&OWNER' and name='VERSION' and to_number(value)>=5.4);

insert into settings values(
    '&&OWNER','USE_TIME_ZONE',nvl('&&D_USE_TZ','NO'),'������� ������������� ��������� ��� (YES/NO)');

insert into settings values ('&&OWNER','FORCE_PARALLEL',nvl('&&D_PARALLEL','0'),
    '����� ����������������� (0 - NOPARALLEL, 1 - PARALLEL DEFAULT, >1 - PARALLEL DEGREE)');

update settings set value='&&OWN_VER'
    where owner='&&OWNER' and name='VERSION';

update settings set value=nvl('&&MAX_APP',value)
    where owner='&&OWNER' and name='MAX_APP_SRV';

update settings set value=nvl('&&D_USE_TZ',value)
    where owner='&&OWNER' and name='USE_TIME_ZONE';

update settings set value=nvl('&&D_PARALLEL',value)
    where owner='&&OWNER' and name='FORCE_PARALLEL';

set echo off
commit;

@@dump_sets

@@cnv_data

@@grants

@@fill_note_lic.sql

@@aud_chk

