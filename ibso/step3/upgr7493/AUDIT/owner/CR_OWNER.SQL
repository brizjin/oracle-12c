prompt
define MAX_APP = 0

set echo on

insert into settings values (
    '&&OWNER','DIARY','90',
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
    '&&OWNER','VERSION','&&OWN_VER', '������ �� ��������� IBSO');

insert into settings values (
    '&&OWNER','MAX_APP_SRV',nvl('&&MAX_APP','0'), '������������ ���������� ������� ������� ��� ������� ����������');

insert into settings values(
    '&&OWNER','USE_TIME_ZONE',nvl('&&D_USE_TZ','NO'),'������� ������������� ��������� ��� (YES/NO)');

insert into settings values ('&&OWNER','FORCE_PARALLEL',nvl('&&D_PARALLEL','0'),
    '����� ����������������� (0 - NOPARALLEL, 1 - PARALLEL DEFAULT, >1 - PARALLEL DEGREE)');

set echo off
commit;

@@dump_sets

define START_DATE='add_months(sysdate, -6)'
define END_DATE='add_months(sysdate, 6)'

exec utils.create_table('&&OWNER', utils.DIARY1, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DIARY2, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DIARY3, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DIARY4, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DIARY5, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DIARY6, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DIARY7, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.VALSH, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.OSH, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.OCH, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.DP, &&START_DATE, &&END_DATE)
exec utils.create_table('&&OWNER', utils.EDH, &&START_DATE, &&END_DATE)

@@cr_idx

@@grants

@@aud_chk

