prompt Correcting settings

exec sysinfo.setvalue('CLS_STATIC_EVENT','0','Признак рассылки события обновления статического экземпляра в момент изменения');

insert into settings(name,value,description) values('LOCK_START','LIB',
  'Путь к исполняемому модулю LOCK_INFO (значение LIB - запуск через библиотеку)');

insert into settings(name,value,description) values('PLP_CACHE_CLASS','YES',
  'Признак использования переменной plp$class$ для вычисления this%class в операциях');

commit;

@@ses_user

column xxx new_value oxxx noprint
select user xxx from dual;

prompt Grant on stat_lib
grant execute on stat_lib to &&oxxx._USER;

commit;

