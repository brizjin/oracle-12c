prompt
accept MAX_APP char format a30 prompt 'IBSO OWNER "&&OWNER" Max Number of Application Server Accounts [0]: ' default 0

set echo on

insert into settings values (
    '&&OWNER','DIARY','90',
    'Период хранения содержимого журнала выполнения операций (дни)');

insert into settings values (
    '&&OWNER','DIARY_UADMIN','90',
    'Период хранения содержимого журнала Администратора доступа (дни)');

insert into settings values (
    '&&OWNER','DIARY_EVENTS','90',
    'Период хранения содержимого журнала системных событий (дни)');

insert into settings values (
    '&&OWNER','DIARY_ADMIN','UNLIMITED',
    'Период хранения содержимого журнала Администратора модели (дни)');

insert into settings values (
    '&&OWNER','DIARY_SES','UNLIMITED',
    'Период хранения содержимого журнала пользовательских сессий (дни)');

insert into settings values (
    '&&OWNER','DIARY_LEVEL','USR|EQU|PRO|RUL|OBJ|CLS|CRI|TRA|MTH|',
    'Уровень журналирования изменений прав доступа');

insert into settings values (
    '&&OWNER','METHODS','OPTIONAL',
    'Уровень журналирования параметров операций');

insert into settings values (
    '&&OWNER','OBJECT_STATE_HISTORY','90',
    'Период хранения содержимого журнала смены состояний (дни)');

insert into settings values (
    '&&OWNER','OBJECT_COLLECTION_HISTORY','90',
    'Период хранения содержимого журнала смены коллекций (дни)');

insert into settings values (
    '&&OWNER','ROWS','100000',
    'Число обрабатываемых за один раз записей');

insert into settings values (
    '&&OWNER','VALUES_HISTORY','90',
    'Период хранения содержимого журнала истории изменения экземпляров (дни)');

insert into settings values (
    '&&OWNER','BATTLE_PASS','A1B2C3',
    'Инициализационный пароль для создания пользователей');

insert into settings values (
    '&&OWNER','CHECK_USER','Z#USER.C_USERNAME',
    'Проверка существования пользователя в прикладной подсистеме (<Tаблица>.<Колонка>)');

insert into settings values (
    '&&OWNER','VERSION','&&OWN_VER', 'Версия ТЯ владельца IBSO');

insert into settings values (
    '&&OWNER','MAX_APP_SRV',nvl('&&MAX_APP','0'), 'Максимальное количество учетных записей для сервера приложений');

insert into settings values(
    '&&OWNER','USE_TIME_ZONE',nvl('&&D_USE_TZ','NO'),'Признак использования временных зон (YES/NO)');

insert into settings values ('&&OWNER','FORCE_PARALLEL',nvl('&&D_PARALLEL','0'),
    'Опция распараллеливания (0 - NOPARALLEL, 1 - PARALLEL DEFAULT, >1 - PARALLEL DEGREE)');

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

