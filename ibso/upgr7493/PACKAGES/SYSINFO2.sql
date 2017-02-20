prompt SYSINFO body
CREATE OR REPLACE Package Body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/SYSINFO2.sql $
 *  $Author: kuvardin $
 *  $Revision: 54716 $
 *  $Date:: 2014-11-07 12:11:55 #$
 */
SYSINFO IS
--
PROCEDURE SetValue ( Value_Name IN VARCHAR2,
   Value_Value IN VARCHAR2, Value_Description IN VARCHAR2 DEFAULT 'NO DESCRIPTION') IS
BEGIN
  if Value_Description = 'NO DESCRIPTION' then
    rtl.put_setting(Value_Name,Value_Value,null);
  else
    rtl.put_setting(Value_Name,Value_Value,Value_Description);
  end if;
END SetValue;
--
FUNCTION GetValue (Value_Name IN VARCHAR2) RETURN  VARCHAR2 IS
BEGIN
 return rtl.setting(upper(Value_Name));
END GetValue;
--
PROCEDURE CreateValue (  Value_Name IN VARCHAR2,
                        Value_Type IN VARCHAR2,
                        Value_Value IN VARCHAR2,
                        Value_Description IN VARCHAR2) IS
BEGIN
  rtl.put_setting(Value_Name,Value_Value,Value_Description);
END CreateValue;
--
PROCEDURE DeleteValue (  Value_Name IN VARCHAR2) IS
BEGIN
  rtl.put_setting(Value_Name,null,null);
END DeleteValue;
--
procedure find_data(p_list in out nocopy  varchar2,
                    p_id varchar2 default null,
                    p_type   varchar2 default null,
                    p_status varchar2 default null) is
begin
  opt_mgr.find_data(p_list,p_id,p_type,p_status);
end;
--
function open_data (p_id varchar2) return pls_integer is
begin
  return opt_mgr.open_data(p_id);
end;
--
function read_data (p_handle pls_integer, p_data in out nocopy raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer isbegin
  return opt_mgr.read_data(p_handle,p_data,p_size);
end;
--
function close_data(p_handle pls_integer, p_commit boolean default true) return pls_integer is
begin
  return opt_mgr.close_data(p_handle,p_commit);
end;
--
function get_data_size(p_handle pls_integer) return pls_integer is
begin
  return opt_mgr.get_data_size(p_handle);
end;
--
function check_value(p_id varchar2, p_force boolean default false,
                     p_sys_only boolean default false, p_report boolean default true) return varchar2 is
begin
  return opt_mgr.check_value(p_id,p_force,p_sys_only,p_report);
end;
procedure check_options(p_id varchar2, p_err_compile out nocopy varchar2, p_force boolean default false) is
begin
  opt_mgr.check_options(p_id, p_err_compile, p_force);
end;
procedure compile_options(p_id varchar2 default null,p_err_compile out nocopy varchar2,p_recompile boolean default false) is
begin
  opt_mgr.compile_options(p_id, p_err_compile, p_recompile);
end;
function calc_version(p_id varchar2) return varchar2 is
begin
  return opt_mgr.calc_version(p_id);
end;
function obj_licensed(p_type varchar2, p_class_id varchar2, p_short_name varchar2) return varchar2 is
begin
  return opt_mgr.obj_licensed(p_type, p_class_id, p_short_name);
end;
function class_licensed(p_class_id varchar2) return varchar2 is
begin
  return opt_mgr.class_licensed(p_class_id);
end;
procedure init_option_context(p_force boolean default false, p_clear boolean default false) is
begin
  opt_mgr.init_option_context(p_force,p_clear);
end;
function status_option_context return varchar2 is
begin
  return rtl.bool_char(opt_mgr.context_is_init);
end;
function new_api_report return number is
begin
  return opt_mgr.new_api_report;
end;
procedure clear_api_reports (p_dt date default null) is
begin
  opt_mgr.clear_api_reports(p_dt);
end;
-- Сброс кэша в пакете opt_mgr, используемый для ускорения установки лицензионной информации
procedure clear_lic_cache is
begin
  opt_mgr.clear_cache;
end;
procedure collect_report(p_id varchar2) is
begin
  opt_mgr.collect_report(p_id);
end;
function get_lic_version return varchar2 is
begin
  return opt_mgr.get_version;
end;
--
function get_report_month(p_year pls_integer, p_month pls_integer, p_xml in out nocopy clob, p_check boolean default false) return number is
v_start date;
v_end date;
begin
  begin
    v_start:= to_date('01'||'/'||p_month||'/'||p_year, 'DD/MM/YYYY');
  exception when others then
    raise VALUE_ERROR;
  end;
  if v_start>=trunc(sysdate,'MM') then
    raise VALUE_ERROR;
  end if;
  v_end:= add_months(v_start,1);
  return opt_mgr.get_report_interval(v_start, v_end, p_xml, p_check);
end;
--
-- Получение значения переменной
function  get_sysinfo_variables( p_groups varchar2, p_code varchar2) return varchar2 is
    v_value varchar2(100);
begin
  select value into v_value from sysinfo_variables
   where groups = p_groups and code = p_code;
  return v_value;
exception when no_data_found then
  return null;
end;
-- Установка значения переменной
procedure set_sysinfo_variables( p_groups varchar2, p_code varchar2, p_value varchar2, p_commit boolean default true) is
begin
  update sysinfo_variables
     set value = p_value
   where groups = p_groups
     and code = p_code;
  if sql%notfound then
    insert into sysinfo_variables
        (groups,  code,  value )
    values
        (p_groups, p_code, p_value);
  end if;
  if p_commit then
    commit;
  end if;
end;
-- Добавление переменной/обновление информации о переменной
procedure add_sysinfo_variables( p_groups varchar2, p_code varchar2, p_name varchar2, p_description varchar2) is
begin
  update sysinfo_variables
  set name = p_name,description = p_description
  where groups = p_groups and code = p_code;
  if sql%notfound then
    insert into sysinfo_variables
        (groups ,code ,name ,description )
    values
        (p_groups,p_code,p_name,p_description);
  end if;
  commit;
end;
--
-- Настройка параметров для e-mail событий-нотификаций
--
procedure set_notification_status(p_event varchar2, p_status varchar2) is
begin
  opt_mgr.set_notification_status(p_event, p_status);
end;
--
procedure set_recipient(p_event varchar2, p_email varchar2, p_name  varchar2) is
begin
  opt_mgr.set_recipient(p_event, p_email, p_name);
end;
--
procedure set_recipient_status(p_event varchar2, p_email varchar2, p_status varchar2) is
begin
  opt_mgr.set_recipient_status(p_event, p_email, p_status);
end;
--
END;
/
show err package body sysinfo

