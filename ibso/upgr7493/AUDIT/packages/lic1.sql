prompt lic_mgr
create or replace package lic_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/lic1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04#$
 */
--
type license_props is record (
    limit varchar2(2000),
    usage varchar2(1),
    usage_date date,
    warning_value Varchar2(2000),
    api_check varchar2(1),
    check_time  date,
    crc_row   number
  );
--
    NO_PRIVILEGES     exception;
    PRAGMA EXCEPTION_INIT( NO_PRIVILEGES   , -1031 ); -- ORA-01031: insufficient privileges
--
function  get_version return varchar2;
--
function  get_props(p_owner varchar2, p_id varchar2,
                    p_props in out nocopy license_props) return varchar2;
--
function  get_limit (p_owner varchar2, p_id varchar2) return varchar2;
procedure set_status(p_owner varchar2, p_id varchar2, p_status varchar2);
--
function  check_status(p_status varchar2) return boolean;
function  get_status(p_owner varchar2, p_id varchar2, p_check boolean default false) return varchar2;
--
procedure set_license(p_owner varchar2, p_id varchar2,
                  p_limit varchar2,
                  p_usage varchar2,
                  p_usage_date date,
                  p_check number,
                  p_commit boolean default true);
procedure set_license(p_owner varchar2, p_id varchar2,
                  p_limit varchar2,
                  p_usage varchar2,
                  p_usage_date date,
                  p_api_check varchar2,
                  p_check number,
                  p_commit boolean default true);
procedure delete_license(p_owner varchar2,p_commit boolean default true);
procedure set_warning_value(p_owner varchar2, p_id varchar2, p_warning_value varchar2);
--
--
procedure write_report(p_owner varchar2,
                       t_sensor_id DBMS_SQL.varchar2s,
                       t_limit DBMS_SQL.Varchar2_Table,
                       t_value DBMS_SQL.Varchar2_Table,
                       t_version DBMS_SQL.Varchar2s,
                       t_status DBMS_SQL.varchar2s,
                       t_check_date DBMS_SQL.date_table,
                       t_crc_row DBMS_SQL.number_table
                       );
--
procedure chk(p_insert boolean, p_delete boolean, p_name varchar2);
procedure install;
--
procedure set_notification_status(p_owner varchar2, p_event varchar2, p_status varchar2);
procedure set_recipient(p_owner varchar2, p_event varchar2,
                        p_email varchar2, p_name  varchar2);
procedure set_recipient_status(p_owner varchar2, p_event  varchar2,
                               p_email varchar2, p_status varchar2);
--															
end;
/
show err

