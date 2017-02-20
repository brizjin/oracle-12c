exec utils.reset_package

column yyy new_value dbsize noprint
select value yyy from v$parameter where name='db_block_size';

def cpucnt=2
column yyy new_value cpucnt noprint
select value yyy from v$parameter where name='cpu_count';

prompt updating settings

set echo on

delete from settings where name='CALL_CONSTRUCTOR';
delete from settings where name='CALL_CONSTRUCTOR';
delete from settings where name='CLS_STATIC_EVENT';
delete from settings where name='METHOD_INTERFACE';
delete from settings where name='LOCK_REQUEST';
delete from settings where name='PIPE_TEXT';

insert into settings(name,value,description) values ('CALL_CONSTRUCTOR','1',
  'Новая схема вызова конструкторов (>0), старая схема (=0)');
insert into settings(name,value,description) values ('CLS_STATIC_EVENT','0',
  'Признак рассылки события обновления статического экземпляра в момент изменения');
insert into settings(name,value,description) values ('METHOD_INTERFACE','2',
  'Новая схема генерации интерфейсных пакетов операций (1 - до 180 контролов, 2 - до 16000), старая схема (=0)');
insert into settings(name,value,description) values ('LOCK_REQUEST','1',
  'Новая схема логических блокировок через LOCK_INFO (>0), старая схема (=0)');
insert into settings(name,value,description) values ('PIPE_TEXT','1',
  'Новая схема считывания из PIPE (>0), старая схема (=0)');

insert into settings(name,value,description) values ('DEF_TEXT','UNIX',
  'Умолчательная кодировка пакета STDIO');
insert into settings(name,value,description) values ('DEF_SLASH','/',
  'Разделитель имен каталогов на сервере');
insert into settings(name,value,description) values ('DEF_CR_ADD','DOS,KOI',
  'Кодировки, при записи/чтении которых добавляется/удаляется символ перевода строки - chr(13)');
insert into settings(name,value,description) values ('STDIO_BUFFER_SIZE','300000',
  'Умолчательный размер буфера сессии (в байтах) для STDIO');
insert into settings(name,value,description) values ('STDIO_LINE_SIZE','32767',
  'Умолчательная длина строки для файловых операций STDIO (Oracle 8)');

insert into settings(name,value,description) values ('LOCK_UNLOAD','1',
  'Время задержки (в часах) остановки процесса LOCK_INFO при отсутствии пользователей');
insert into settings(name,value,description) values ('LOCK_ACTIVE','0',
  'Ограничение количества одновременно выполняющихся критических операций');
insert into settings(name,value,description) values ('LOCK_RETRY','20',
  'Количество попыток блокировки объекта');
insert into settings(name,value,description) values ('LOCK_DELAY','0.1',
  'Задержка попыток блокировки объектов (сек.)');
insert into settings(name,value,description) values ('LOCK_DEBUG_SIZE','0',
  'Размер pipe для вывода отладочной информации LOCK_INFO (байты)');
insert into settings(name,value,description) values ('RETRY_PIPE_SIZE','0',
  'Размер pipe для вывода информации о попытках блокировки (байты)');
insert into settings(name,value,description) values ('LOCK_SKIP_WAIT','1',
  'Признак отключения функции поиска информации о физических блокировках (1 или YES - функция отключена, иначе - включена)');

insert into settings(name,value,description) values ('LOCK_TIMEOUT','300',
  'Максимально допустимый период (в сек.) неактивности сессии пользователя, по истечении которого сессия удаляется');
insert into settings(name,value,description) values ('MESSAGE_PERIOD','60',
  'Интервал запуска проверки внешних сообщений в секундах');
insert into settings(name,value,description) values ('RESTRICTED_MODE','NO',
  'Признак ограниченного доступа к системе (YES - вход в систему Навигатором закрыт)');

insert into settings(name,value) values ('USE_TIME_ZONE','NO');
update settings set description =
  'Признак использования временных зон (YES - коррекция времени в журналах аудита, SYS_DIARYS - коррекция времени в представлениях типа SYS_DIARYS, NO - нет коррекции)'
 where name='USE_TIME_ZONE';

insert into settings(name,value,description) values ('STORAGE_FORCE_DEFERRABLE','NO',
  'Признак использования опции DEFERRABLE при создании ограничений целостности (YES/NO)');
insert into settings(name,value,description) values ('STORAGE_FORCE_NOLOGGING','NO',
  'Признак использования опции NOLOGGING при модификации и перестроении объектов хранения (YES/NO)');
insert into settings(name,value,description) values ('STORAGE_FORCE_NOVALIDATE','NO',
  'Признак использования опции NOVALIDATE при создании ограничений целостности (YES/NO)');
insert into settings(name,value,description) values ('STORAGE_FORCE_ONLINE','NO',
  'Признак использования опции ONLINE при модификации и перестроении объектов хранения (YES/NO)');
insert into settings(name,value,description) values ('STORAGE_FORCE_PARALLEL','0',
  'Признак использования опции PARALLEL при перестроении объектов хранения (0 - NOPARALLEL, 1 - PARALLEL DEFAULT, >1 - PARALLEL DEGREE)');
insert into settings(name,value,description) values ('STORAGE_INSERT_HINT','APPEND',
  'Умолчательный хинт для переноса данных таблиц при перестроении (значение NOHINT - хинт отсутствует)');


insert into settings(name,value,description) values ('ADMIN_READ_ONLY','NO',
  'Признак работы Администратора модели в режиме "Только чтение" (YES)');
insert into settings(name,value,description) values ('UADMIN_READ_ONLY','NO',
  'Признак работы Администратора доступа в режиме "Только чтение" (YES)');

insert into settings(name,value,description) values ('CLS_NO_CACHE_PIPES','BRANCH,CL_PART,DEPART',
  'Список ТБП для безусловной рассылки событий обновления кэша экземпляров');
insert into settings(name,value,description) values ('CLS_USE_CACHE_PIPES','YES',
  'Признак адресной рассылки события обновления кэша экземпляров (YES)');

insert into settings(name,value,description) values ('JOBS_DEFAULT_QUEUE','ORACLE',
  'Используемая очередь заданий (ORACLE - по умолчанию, или RUNPROC)');
insert into settings(name,value,description) values ('JOBS_MAX_FAILURES','10',
  'Максимальное количество попыток перезапуска заданий при возникновении ошибок');
insert into settings(name,value,description) values ('JOBS_RUNPROC_INI','runproc.ini',
  'Путь к файлу инициализации агента RUNPROC');
insert into settings(name,value,description) values ('JOBS_RUNPROC_USER','RUNPROC',
  'Имя пользователя агента RUNPROC очереди заданий');

insert into settings(name,value,description) values ('PLP_CACHE_CLASS','YES',
  'Признак использования переменной plp$class$ для вычисления this%class в операциях');
insert into settings(name,value,description) values ('PLP_CACHE_OPTION','YES',
  'Признак кэширования объекта THIS в операциях');
insert into settings(name,value,description) values ('PLP_COMPATIBILITY','PL/SQL',
  'Режим семантических проверок PL/Plus (PL/SQL, JAVA_BASE)');
insert into settings(name,value,description) values ('PLP_DEF_TARGET','0',
  'Целевая платформа генерации кода PL/Plus (0 - PL/SQL, 1 - PL/SQL+JAVA, 2 - JAVA)');
insert into settings(name,value,description) values ('PLP_ERROR_MESSAGE_LENGTH','2048',
  'Максимальная длина сообщений об ошибках (в байтах)');

insert into settings(name,value,description) values ('PLP_JAVA_CONST_THRESHOLD','2',
  'Порог к-ва повторяемых значений для генерации локальных констант в java коде (0 отключает генерацию)');
insert into settings(name,value,description) values ('PLP_JAVA_GEN_AUTO_TRANS','NO',
  'Генерация кода выполнения автономных транзакций в отдельной сессии');
insert into settings(name,value,description) values ('PLP_JAVA_GEN_ROWTYPE','YES',
  'Признак генерации описаний структур для используемых таблиц и типов Oracle');
insert into settings(name,value,description) values ('PLP_JAVA_GEN_VARRAY','YES',
  'Признак генерации java-типов для пользовательских nested/varray массивов');

insert into settings(name,value,description) values ('PLP_OVERLAPPING','YES',
  'Признак обработки вызовов перекрытых процедур и функций без режима расширенного синтаксиса');
insert into settings(name,value,description) values ('PLP_PARSE_PACK_DEPS','YES',
  'Признак расширения разбора зависимостей PL/SQL пакетов за пределы собственной схемы (YES/NO)');
insert into settings(name,value,description) values ('PLP_STANDALONE_EXTENSION','YES',
  'Признак создания единого пакета для расширения и базовой операции (YES/NO)');

exec sysinfo.setvalue('NOVO_LIGHT_WEIGHT','1',message.gettext('ADMIN', 'NOVO_LIGHT_WEIGHT'));

commit;

prompt updating storage_parameters

exec storage_mgr.set_storage_parameter('GLOBAL','DB_BLOCK_SIZE','&&DBSIZE');
exec storage_mgr.set_storage_parameter('GLOBAL','CPU_COUNT','&&CPUCNT');
exec storage_mgr.set_storage_parameter('GLOBAL','TAB_TABLESPACE', upper('&&TSTAB'));
exec storage_mgr.set_storage_parameter('GLOBAL','IDX_TABLESPACE', upper('&&TSIDX'));
exec storage_mgr.set_storage_parameter('GLOBAL','PART_TABLESPACE',upper('&&TPART'));
exec storage_mgr.set_storage_parameter('GLOBAL','IDXPART_TABLESPACE',upper('&&TPARTI'));
exec storage_mgr.set_storage_parameter('GLOBAL','LOB_TABLESPACE', upper('&&TSLOB'));
exec storage_mgr.set_storage_parameter('GLOBAL','DICT_TABLESPACE',upper('&&TUSERS'));
exec storage_mgr.set_storage_parameter('GLOBAL','IDXDICT_TABLESPACE',upper('&&TSPACEI'));
exec storage_mgr.set_storage_parameter('GLOBAL','KEEP_REPORTS','&&RPTKEEP');

exec storage_mgr.set_storage_parameter('LOB_STORAGE', 'STORAGE_IN_ROW', 'ENABLE');
exec storage_mgr.set_storage_parameter('LOB_STORAGE', 'CHUNK', '8192');

set echo off

