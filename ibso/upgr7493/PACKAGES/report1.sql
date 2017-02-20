prompt report_mgr
create or replace package report_mgr is
/*
 * $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/report1.sql $<br/>
 * $Author: Alexey $<br/>
 * $Revision: 15072 $<br/>
 * $Date:: 2012-03-06 13:41:17 #$<br/>
*/

-- Типы отчетов
REPORT_NAV    constant varchar2(1)  := 'N';  /* Навигатор */
REPORT_UADMIN constant varchar2(1)  := 'U';  /* Администратор доступа */
REPORT_PDADMIN constant varchar2(1) := 'P';  /* Администратор персональных данных */

-- Методы для работы с отчетами
procedure Check_Report_Rights(p_username varchar2);
procedure Check_Report_User(p_username  in out nocopy varchar2
                           ,p_os_user   varchar2
                           ,p_os_domain varchar2
                           ,p_rpt_type  varchar2 default REPORT_NAV);
procedure Create_Report(p_job       in out nocopy number
                       ,p_pos       in out nocopy number
                       ,p_username  varchar2
                       ,p_os_user   varchar2
                       ,p_os_domain varchar2
                       ,p_class_id  varchar2
                       ,p_method_id varchar2
                       ,p_params    varchar2
                       ,p_rpt_name  varchar2
                       ,p_out_name  varchar2
                       ,p_props     varchar2
                       ,p_rpt_drv   varchar2
                       ,p_trace_opt varchar2
                       ,p_schedule  date
                       ,p_priority  number
                       ,p_wait      boolean default false
                       ,p_engine    varchar2 default 'ORA'
                       ,p_rpt_type  varchar2 default REPORT_NAV);
procedure Delete_Report(p_username varchar2, p_job number, p_pos number);
procedure Rerun_Report (p_username varchar2, p_job number, p_pos number);
procedure Cancel_Report(p_username varchar2, p_job number, p_pos number);
function  Lock_Report(p_username varchar2, p_job number, p_pos number) return number;
procedure Set_Props(p_job number, p_pos number, p_props varchar2);
procedure Set_Rpt_Drv(p_job number, p_pos number, p_rpt_drv varchar2);
procedure Save_Par(p_job number, p_pos number, p_name varchar2, p_value blob);
procedure Save_Par(p_job number, p_pos number, p_name varchar2, p_value clob);
procedure Save_Params(p_job number, p_pos number, p_params varchar2, p_lock boolean);
procedure open(
        p_job    out pls_integer,
        p_job_pos out pls_integer,
        p_session_id out pls_integer,
        p_domain out USERS.OS_DOMAIN%type,
        p_user out USERS.OS_USER%type,
        p_param  out ORSA_JOBS_PAR.VALUE%type,
        p_orsa_server in  ORSA_JOBS.SERVER_EXECUTED%type default null,
        p_reuse_session in boolean default null
);
procedure open_rpt_session(
  p_job        in  pls_integer,
  p_job_pos    in  pls_integer,
  p_session_id out pls_integer,
  p_domain     out USERS.OS_DOMAIN%type,
  p_user       out USERS.OS_USER%type,
  p_properties out ORSA_JOBS.PROPERTIES%type
);
function  Clear_Orsa_Jobs(p_min_date date,p_force boolean default false) return pls_integer;
end;
/
show errors

