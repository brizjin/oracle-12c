prompt ie_db54
create or replace package ie_db54 is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iedb54_1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */

function date_to(p_owner varchar2, p_code pls_integer, p_date date default null) return date;

procedure imp_diary_n(p_owner in varchar2, p_code in pls_integer, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_dp(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_och(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_osh(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_valsh(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);

procedure exp(p_owner varchar2, v6 boolean, p_code pls_integer, p_date date, p_make_date_safe boolean);
procedure clr(p_owner varchar2, p_code pls_integer, p_date date, p_nrows pls_integer,
    p_table in out varchar2, p_count out pls_integer, p_error out varchar2);

end;
/
show err

