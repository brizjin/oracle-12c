set verify off
set heading off
set feedback off

prompt
prompt LICENSE notifications

var res_msg varchar2(2000)

declare
  v_sender  varchar2(64);
  v_sname   varchar2(200);
  v_res_msg varchar2(2000);
  
  procedure add_one(p_event varchar2, p_subject varchar2, p_message varchar2, p_description varchar2) is
    v_res number;
  begin
    select 1 into v_res from notifications
    where owner = '&&OWNER' and event = p_event and rownum < 2;
  exception
    when no_data_found then
      mail_mgr.set_notification('&&OWNER', p_event, p_subject, p_message, v_sender, v_sname, p_description);
      mail_mgr.set_notification_status('&&OWNER',p_event,'INACTIVE');
      v_res_msg := v_res_msg || chr(9) || p_event || chr(10);
  end;
  
begin
  v_res_msg := '';
  begin
    select value into v_sender from settings where owner='&&OWNER' and name='MAIL_DEF_SENDER';  
  exception
    when no_data_found then v_sender := '';
  end;
  begin
    select value into v_sname from settings where owner='&&OWNER' and name='MAIL_DEF_SENDER_NAME';  
  exception
    when no_data_found then v_sname := v_sender;
  end;
  add_one('LOG_LICENSE_STATUS_BAD', 'LOG_LICENSE_STATUS_BAD', 'LOG_LICENSE_STATUS_BAD', 'Событие нарушения лицензионных ограничений');
  add_one('LOG_LICENSE_USAGE_DATE', 'LOG_LICENSE_USAGE_DATE', 'LOG_LICENSE_USAGE_DATE', 'Контроль срока использования подсистемы');
  add_one('LOG_LICENSE_WARNING', 'LOG_LICENSE_WARNING', 'LOG_LICENSE_WARNING', 'Контроль фактических значений лицензионных ограничений');
  add_one('LOG_OPTION_CORRUPTED', 'LOG_OPTION_CORRUPTED', 'LOG_OPTION_CORRUPTED', 'Событие нарушения описания приложений');
  add_one('LOG_LICENSE_MESSAGE', 'LOG_LICENSE_MESSAGE', 'LOG_LICENSE_MESSAGE', 'Сообщение подсистемы лицензирования');
  add_one('LOG_LICENSE_DIFF', '', '', 'Оповещение об изменении КЛО');
  if v_res_msg is not null then
    v_res_msg := 'Added events: '||chr(10)||v_res_msg; 
  end if;
  :res_msg := v_res_msg;
  commit;
end;
/
print res_msg

set verify on
set heading on
set feedback on

