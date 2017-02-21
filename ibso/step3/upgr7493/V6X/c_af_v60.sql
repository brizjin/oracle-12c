
var s varchar2(2000)
declare
  s varchar2(2000);
  x varchar2(1);
begin
  for c in (select file_spec from user_libraries where library_name='LIBLOCK')
  loop
    s := c.file_spec;
  end loop;
  s := nvl(s,'/u/tools/lock/liblock.so');
  if instr(s,'\')>0 then
    x := '\';
  else
    x := '/';
  end if;
  :s := substr(s,1,instr(s,x,-1))||'lock.ini';
end;
/

prompt SHOW_SYSTEM_MENU
insert into settings(name,value,description) values('SHOW_SYSTEM_MENU','YES',
  'Признак показа системного меню');
prompt VIEW_OBJECT_ATTRIBUTES
insert into settings(name,value,description) values('VIEW_OBJECT_ATTRIBUTES','NO',
  'Показывать представления, являющиеся результатом раскрытия ссылки в другом представлении, в режиме "Просмотр реквизитов экземпляра"');
prompt NO_EXTEND_RIGHT_COLUMN
insert into settings(name,value,description) values('NO_EXTEND_RIGHT_COLUMN','NO',
  'Не расширять последнюю колонку представления на всю ширину таблицы');
prompt REPLACE_TYPE_MENU
insert into settings(name,value,description) values('REPLACE_TYPE_MENU','NO',
  'Признак замены меню типов системным меню');
prompt HIDE_NOVIEW_TYPES
insert into settings(name,value,description) values('HIDE_NOVIEW_TYPES','NO',
  'Показывать только те типы и справочники, которые не только доступны сами, но и имеют доступные пользователю представления, не помеченные флагом "Доступно только в операциях"');
prompt MESSAGE_PERIOD
insert into settings(name,value,description) values('MESSAGE_PERIOD','60',
  'Интервал запуска проверки внешних сообщений в секундах');
prompt MAX_SESSIONS_ALLOWED
insert into settings(name,value,description) values('MAX_SESSIONS_ALLOWED','0',
  'Максимально допустимое количество активных сессий (0 - ограничения нет)');

prompt LOCK_TIMEOUT
insert into settings(name,value,description) values('LOCK_TIMEOUT','300',
  'Максимально допустимый период (в сек.) неактивности сессии пользователя, по истечении которого сессия удаляется');
prompt RESTRICTED_MODE
insert into settings(name,value,description) values('RESTRICTED_MODE','NO',
  'Признак ограниченного доступа к системе (YES - вход в систему Навигатором закрыт)');
prompt LOCK_PATH
insert into settings(name,value,description) values('LOCK_PATH',:s,
  'Путь к файлу настроек LOCK_INFO (для внешнего процесса)');
prompt LOCK_PROFILE
insert into settings(name,value,description) values('LOCK_PROFILE',USER,
  'Профиль настроек LOCK_INFO (для внешнего процесса)');
prompt LOCK_SERVERS
insert into settings(name,value,description) values('LOCK_SERVERS','2',
  'Максимальное количество менеджеров блокировок');

insert into storage_parameters(param_group, param_name, param_value)
  values('GLOBAL','CHECK_PLSQL','&&CHKPLS');

exec patch_tool.update_props;

commit;



