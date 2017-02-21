-- Раздача необходимых грантов для работы "ЦФТ - Подсистемы работы с формами" под сервисным пользователем APP_SRV.
-- Выполняется из-под IBS.

spool grant_fs.log

prompt Раздача грантов для "ЦФТ - Подсистемы работы с формами"

set echo on

prompt FS grants

declare
  OWNER_APPSRV   varchar2(37);
begin
  OWNER_APPSRV := INST_INFO.OWNER || '_APPSRV';
  
  execute immediate 'grant select on z#fs_ctl_params to ' || OWNER_APPSRV;
  execute immediate 'grant select on z#fs_controls to ' || OWNER_APPSRV;
  execute immediate 'grant select on z#fs_ctl_types to ' || OWNER_APPSRV;
  execute immediate 'grant select on z#fs_forms to ' || OWNER_APPSRV;
end;

/

set echo off
spool off

exit