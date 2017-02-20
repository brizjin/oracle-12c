prompt SYSINFO
CREATE OR REPLACE Package SYSINFO
  IS
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/SYSINFO1.sql $
 *  $Author: kuvardin $
 *  $Revision: 54716 $
 *  $Date:: 2014-11-07 12:11:55 #$
 */
--
-- Purpose: Общение с системными установками (табличка SETTINGS)
--
    PROCEDURE SetValue ( Value_Name IN VARCHAR2,
        Value_Value IN VARCHAR2, Value_Description IN VARCHAR2 DEFAULT 'NO DESCRIPTION');
    FUNCTION GetValue (Value_Name IN VARCHAR2) RETURN  VARCHAR2 DETERMINISTIC;
    pragma restrict_references(GetValue, WNDS, WNPS);
    PROCEDURE CreateValue (  Value_Name IN VARCHAR2,
                            Value_Type IN VARCHAR2,
                            Value_Value IN VARCHAR2,
                            Value_Description IN VARCHAR2);
    PROCEDURE DeleteValue (Value_Name IN VARCHAR2);
-- Licensing
    procedure find_data(p_list in out nocopy  varchar2,
                        p_id varchar2 default null,
                        p_type   varchar2 default null,
                        p_status varchar2 default null);
    function open_data (p_id varchar2) return pls_integer;
    function read_data (p_handle pls_integer, p_data in out nocopy raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
    function close_data(p_handle pls_integer, p_commit boolean default true) return pls_integer;
    function get_data_size(p_handle pls_integer) return pls_integer;
    function check_value(p_id varchar2, p_force boolean default false,
                     p_sys_only boolean default false, p_report boolean default true) return varchar2;
    procedure check_options(p_id varchar2, p_err_compile out nocopy varchar2, p_force boolean default false);
    procedure compile_options(p_id varchar2 default null,p_err_compile out nocopy varchar2,p_recompile boolean default false);
    function calc_version(p_id varchar2) return varchar2;
    function obj_licensed(p_type varchar2, p_class_id varchar2, p_short_name varchar2) return varchar2;
    function class_licensed(p_class_id varchar2) return varchar2;
    procedure init_option_context(p_force boolean default false, p_clear boolean default false);
    function status_option_context return varchar2;
    function new_api_report return number;
    procedure clear_api_reports (p_dt date default null);
    procedure collect_report(p_id varchar2);
    procedure clear_lic_cache;
    function get_report_month(p_year pls_integer, p_month pls_integer, p_xml in out nocopy clob, p_check boolean default false) return number;
    -- Версия подсистемы лицензирования
    function get_lic_version return varchar2;
-- Хранение глобальных переменных
function  get_sysinfo_variables( p_groups varchar2, p_code varchar2) return varchar2 deterministic;
procedure set_sysinfo_variables( p_groups varchar2, p_code varchar2, p_value varchar2, p_commit boolean default true);
procedure add_sysinfo_variables( p_groups varchar2, p_code varchar2, p_name varchar2, p_description varchar2);
-- Настройка параметров для e-mail событий-нотификаций
procedure set_notification_status(p_event varchar2, p_status varchar2);
procedure set_recipient(p_event varchar2, p_email varchar2, p_name  varchar2);
procedure set_recipient_status(p_event varchar2, p_email varchar2, p_status varchar2);
--
END;
/
show err

