prompt ie_db34
create or replace package ie_db34 is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iedb34_1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */

procedure imp_diary(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_diary_param(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_object_state_history(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);
procedure imp_values_history(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer);

procedure exp(p_owner varchar2, p_code pls_integer, p_date date, p_make_date_safe boolean);
procedure clr(p_owner varchar2, p_code pls_integer, p_date date, p_nrows pls_integer,
    p_table in out varchar2, p_count out pls_integer, p_error out varchar2);

end;
/
show err

