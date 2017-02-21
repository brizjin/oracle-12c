prompt opt_mgr
create or replace package opt_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/opt_mgr1.sql $
 *  $Author: sasa $
 *  $Revision: 129085 $
 *  $Date:: 2016-11-28 11:39:44 #$
 */
--
USAGE_DISABLED      constant varchar2(1)  := '0';
USAGE_ENABLED       constant varchar2(1)  := '1';
USAGE_ENABLED_ABS   constant varchar2(1)  := '2';
--
type option_props is record (
    -- system_options
    parent_id varchar2(128),
    name Varchar2(2000),
    check_type varchar2(16),
    type  varchar2(16),
    get_sql varchar2(3000),
    required varchar2(1),
    version varchar2(16),
    ver_sql varchar2(2000),
    check_time date,
    calc_time date,
    crc_row number,
    crc_tree number,
    crc_obj number,
    value varchar2(2000),
    bound_value varchar2(2000),
    status varchar2(16),
    exec_sql varchar2(4000),
    crc_exec number,
    base varchar2(1),
    licensed varchar2(1),
    loc varchar2(1),
    -- license settings
    limit varchar2(2000),
    usage varchar2(1),
    usage_date date,
    warning_value Varchar2(2000),
    status_lic varchar2(16),
    crc_row_lic number,
    check_time_lic date,
    api_check varchar2(1),
    items type_string_table,		-- PLATFORM-1975 - ��������� ��� ������������ ������ (�����: USERS_LICENSED)
    src_limit varchar2(2000)		-- PLATFORM-1975 - �����, ��� �� ��������� � ��������, ���� limit ��� ����� � ����������� ������� �������� ������������ ��������
  );
--
  type Varchar4K_Table is table of varchar2(4000) index by binary_integer;
--
  mode_readonly  constant pls_integer := dbms_lob.lob_readonly;
  mode_readwrite constant pls_integer := dbms_lob.lob_readwrite;
--
  NO_PRIVILEGES     exception;
  PRAGMA EXCEPTION_INIT( NO_PRIVILEGES   , -1031 ); -- ORA-01031: insufficient privileges
-- ������ ���������� ��������������
function get_version return varchar2;
--
-- *** ��������� ��������� ������� ������������ ��������/��������
-- ���������� �������� ���������
function  get_description (p_id varchar2) return varchar2;
-- ���������� �������� ������������� �����������
function  get_limit(p_id varchar2) return varchar2;
-- ���������� ������ ������������ ���������
function  get_lic_status(p_id varchar2,p_check boolean default false) return varchar2;
-- ���������� ������� �������� ����������� ��������� ��� �������
function  get_value (p_id varchar2) return varchar2;
-- ���������� ������������ �������� ����������:
-- ������� ��������� ���������� � ID �� ������ 'CORE', ���� ����� ������� ��� - �� ������������
-- ������������ ���������� 'CORE',
function  get_app_name return varchar2;
--
-- ***
-- �������� ��������� ������������ �����������, �������� �� RUNTIME
function check_sys_value(p_raise boolean default false) return varchar2;
-- �������� ������������ �����������
function check_value(p_id varchar2, p_force boolean default false,
                     p_sys_only boolean default false, p_report boolean default true) return varchar2;
-- ������ �������� �������� ������������ ��������� ��� �������
function calc_value(p_id varchar2, p_force boolean default false) return varchar2;
-- ������ ������� �������� ������������ ��������� ��� �������
function calc_props(p_id varchar2, p_force boolean default false) return option_props;
--
-- *** ������� ��� �������� ��������
-- �������� ���-����� �������� ����� ��� ��������� ����������
-- �������� �������� p_error ���������� ���������� �� ������� ����������
procedure check_options(p_id varchar2, p_err_compile out nocopy varchar2, p_force boolean default false);
-- ���������� �������� ����� � �������� ����� � �������� �� ���
procedure compile_options(p_id varchar2 default null,p_err_compile out nocopy varchar2,p_recompile boolean default false);
-- ������ ������ ������ �������� �����
function calc_version(p_id varchar2) return varchar2;
--
-- *** ������� ��� RUNTIME
-- �������� �������� �������� "���������� ������������� �����"
function option_usage(p_id varchar2) return varchar2;
-- ���������� ������� - ��������� �� ������������� �����
function option_enabled(p_id in varchar2) return boolean;
-- ��������� �� ����� �����
function option_limit_reached(p_id varchar2) return boolean;
-- ������������ � ���������� �������� ��� �������
function get_sensor_value(p_id varchar2, p_calc boolean default true) return varchar2;
--
-- ������� ��� �������� ������� ��������� � ������������� ��������� ����������
-- ���� ������ ���� � ������ ��������� �������� ���������� ���������� '1', ����� ���������� '0'
function obj_licensed(p_type varchar2, p_class_id varchar2, p_short_name varchar2) return varchar2;
-- ���� ���� �� ���� ������� ������ ���� � ������ ��������� �������� ���������� ���������� '1',
-- ����� ���������� '0'
function class_licensed(p_class_id varchar2) return varchar2;
--
-- ���� ������
procedure collect_report(p_id varchar2);
--
-- *** ��������� ��� ��������� ��������
-- �������� �������� ����� ��� ��������� ����������
procedure delete_options(p_id varchar2);
-- ���������� ������� ��� ������� ������� � system_option
procedure prepare_options(p_init boolean,
                         p_t_opt_id "CONSTANT".REFSTRING_TABLE,
                         p_t_opt_parent_id "CONSTANT".REFSTRING_TABLE,
                         p_t_opt_name "CONSTANT".VARCHAR2_TABLE,
                         p_t_opt_type "CONSTANT".REFSTRING_TABLE,
                         p_t_opt_check_type "CONSTANT".REFSTRING_TABLE,
                         p_t_opt_get_sql Varchar4K_Table,
                         p_t_opt_crc_row "CONSTANT".NUMBER_TABLE,
                         p_t_opt_crc_tree "CONSTANT".NUMBER_TABLE,
                         p_t_opt_crc_obj "CONSTANT".NUMBER_TABLE,
                         p_t_opt_required "CONSTANT".REFSTRING_TABLE,
                         p_t_opt_version "CONSTANT".REFSTRING_TABLE,
                         p_t_opt_ver_sql "CONSTANT".VARCHAR2_TABLE,
                         p_t_opt_licensed "CONSTANT".VARCHAR2S,
                         p_t_opt_loc "CONSTANT".VARCHAR2S);
-- ���������� ������� ��� ������� ������� � objects_options
procedure prepare_objects(p_init boolean,
                         p_t_obj_type "CONSTANT".REFSTRING_TABLE,
                         p_t_obj_class_id "CONSTANT".REFSTRING_TABLE,
                         p_t_obj_short_name "CONSTANT".REFSTRING_TABLE,
                         p_t_obj_option_id "CONSTANT".REFSTRING_TABLE);
--
-- ���������� ������� ��� ������� ������� � license_settings
procedure prepare_license(p_init boolean,
                          p_t_lic_id "CONSTANT".VARCHAR2S,
                          p_t_lic_limit "CONSTANT".VARCHAR2_TABLE,
                          p_t_lic_usage "CONSTANT".VARCHAR2S,
                          p_t_lic_usage_date "CONSTANT".DATE_TABLE,
                          p_t_lic_crc_row "CONSTANT".NUMBER_TABLE,
                          p_t_lic_api_check "CONSTANT".VARCHAR2S);
-- ��������� ������������ ����������
procedure install_license;
--  ��������� �������� � ������� ��������� ����������, ��������� � ��������������
-- � ������� �������� prepare_options, prepare_objects
-- p_base - id �������� ����������
procedure install_options(p_base varchar2);
-- ��������� �������� WARNING_VALUE ��� ������������ ���������
procedure set_warning_value(p_id varchar2, p_warning_value varchar2);
--
-- *** �������� ��� ��������������
-- ������� ������������� ����������� ��������� ��� ��������������,
-- ��� p_force = true �������� ��������������������
-- ��� p_force = false ������������� ����������, ���� �������� �� ������������������
-- p_clear - ������� "������� �������� ��� �����������������"
procedure init_option_context(p_force boolean default false, p_clear boolean default false);
-- ������� �������� ������������� ���������
-- ������ null � ������, ���� �������� ��� ������������������ ��� ������� ��������� CHECK_SUM <> 'VALID'
function context_is_init return boolean;
-- ��������� ����� (p_force_start==true  - �������������� ������� �������)
procedure submit(p_force_start boolean default false);
procedure job (p_job integer, p_date in out nocopy date, p_broken in out nocopy boolean );
procedure stop_job;
--
-- *** ��������� ��� �������� ��� ���������� ���������
procedure chk(p_insert boolean, p_delete boolean, p_name varchar2);
--
-- *** ������� ��� ������ � �������� LICENSE_DATA
procedure set_data(p_id varchar2, p_type varchar2,
                   p_description  varchar2,
                   p_date_begin date,
                   p_date_end   date);
--
procedure find_data(p_list in out nocopy  varchar2,
                    p_id varchar2 default null,
                    p_type   varchar2 default null,
                    p_status varchar2 default null);
--
procedure set_data_status(p_id varchar2, p_status varchar2);
--
function open_data(p_id varchar2, p_mode pls_integer default mode_readonly ) return pls_integer;
function get_data_size(p_handle pls_integer) return pls_integer;
function read_data (p_handle pls_integer, p_data in out nocopy raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
function clear_data(p_handle pls_integer, p_size pls_integer default null) return pls_integer;
function write_data(p_handle pls_integer, p_data raw, p_size pls_integer default null, p_pos pls_integer default null) return pls_integer;
function close_data(p_handle pls_integer, p_commit boolean default true) return pls_integer;
--
-- ������� ��� ������ � �������� �� ������������� API
--
-- �������� ������
function new_api_report return number;
-- �������� ����������� ������ �� ��������� ���� (�� ��������� ����������� ������ �� ��������� 30 ����)
procedure clear_api_reports (p_dt date default null);

--
-- ��������� ���������� ��� e-mail �������-�����������
procedure set_notification_status(p_event varchar2, p_status varchar2);
procedure set_recipient(p_event varchar2, p_email varchar2, p_name  varchar2);
procedure set_recipient_status(p_event varchar2, p_email varchar2, p_status varchar2);
--
-- ������������ ����������
procedure lic_diff_form(p_subj out varchar2, p_body out clob, p_dt_prev date default null, p_dt_last date default null);
-- �������� ����������
procedure lic_diff_send(p_subj varchar2, p_body clob);
-- ���������� �� ��������� ���
-- p_dt_prev, p_dt_last ���� �������������� � ���������� ������� (������ �� ��������).
-- ���� ���� ���������� ������ �� ��������, �� ���� �����������
procedure lic_diff_notify(p_dt_prev date default null, p_dt_last date default null);
--
-- ������������ ������ ���
procedure auto_send_report;
function get_report_interval(p_start date, p_end date, p_xml in out nocopy clob, p_check boolean default false) return number;
-- API ��� ��������� ������� ������� �� ��������
-- ��� ������� � �������� �������� ���������� p_type - CLASSES|METHODS|CRITERIA
-- ��������� ���������� � ���, �������� �� ������ ������������� "�������������" API
function is_object_api_check(p_type varchar2, p_class varchar2, p_short_name varchar2) return pls_integer;
-- ��������� ���������� � ���, �������� �� ������ �������������
function is_object_licensable(p_type varchar2, p_class varchar2, p_short_name varchar2) return pls_integer RESULT_CACHE;
-- ��������� ���������� � ���, �������� �� ������ ���������������
function is_api_licensed(p_type varchar2, p_class varchar2, p_short_name varchar2) return pls_integer RESULT_CACHE;
function is_api_licensed(p_type varchar2, p_object_id varchar2) return pls_integer RESULT_CACHE;
-- ��������� ���������� � ���, �������� �� ������ API, ����������� � �������������
--  p_flag - ��������, �������������� ����������� �������� is_check_obj_access, �� ���� �������� �� ������ "�������������" API � �������� �� ����� LOCAL_APP.OBJ_ACCESS
function is_api_denied(p_flag boolean, p_type varchar2, p_object_id varchar2) return boolean;
-- ��������� ���������� � ���, �������� �� ����� LOCAL_APP.OBJ_ACCESS � �������� �� ������ ������������� "�������������" API
function is_check_obj_access(p_type varchar2, p_class varchar2, p_short_name varchar2) return boolean;
-- ��������� ���������� � ���, �������� �� ������ ��������� ������������������(�� � �������� ������)/��������������������
-- ���� ������������ �������� = TRUE, �� ������ ���������, ��������������� ���������� �������� �����������
-- ���� ������������ �������� = FALSE, �� ������ �� �������� ���������
function is_object_local(p_type       varchar2
                        ,p_class      varchar2
                        ,p_short_name varchar2
                        -- '1'        - ������������������(�� � �������� ������)
                        -- '0'(null)  - ��������������������
                        ,p_registred  varchar2 default '0')
                                              return boolean RESULT_CACHE;
-- �������� �������� �� ������ ���������, ���������� �� ���� ���������������(�� � �������� ������) �� ��� �� ���������������
function is_object_local_ext(p_type       varchar2
                        	  ,p_class      varchar2
                            ,p_short_name varchar2)
                                              return boolean RESULT_CACHE;
-- ��������� ������� ����
procedure clear_cache;
-- ��������� ������� � ���������� ������
pipe_name   varchar2(30);
verbose boolean;

end OPT_MGR;
/
show err
