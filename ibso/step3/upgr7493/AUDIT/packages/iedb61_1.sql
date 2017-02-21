prompt ie_db61
create or replace package ie_db61 is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iedb61_1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */

function date_to(p_owner varchar2, p_code pls_integer,
                 p_date date default null, p_parts boolean default true) return date;
function chk_exp_date(p_owner varchar2, p_code pls_integer, p_date  in out nocopy date,
                      p_make_date_safe boolean default true,p_parts boolean default true) return boolean;

procedure imp_diary(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_diary_param(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_object_state_history(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_values_history(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);

procedure imp_diary_n(p_owner in varchar2, p_code in pls_integer, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_dp(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_och(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_osh(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_valsh(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_edh(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);

procedure exp(p_owner varchar2, p_code pls_integer, p_date date, p_make_date_safe boolean);
procedure clr(p_owner varchar2, p_code pls_integer, p_date date, p_result out nocopy varchar2);

end;
/
show err

