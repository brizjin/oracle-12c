prompt rtl_utils 
create or replace package 
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtl_utils1.sql $<br/>
 *  $Author: kurkin $<br/>
 *  $Revision: 47795 $<br/>
 *  $Date:: 2014-06-24 15:04:06 #$<br/>
 *  @headcom
 */

rtl_utils is
    
    PREFIX        constant varchar2(30) := 'LOCKS$'||Inst_info.owner||'$';

/**
 * ������� ���������� �������
 * @Param   p_session_id ���������� ������������� ������    
 */
procedure kill_session(p_session_id pls_integer);

/**
 * ���������� ������ ���������� ������
 * @Param   p_uid        ���������� ������������� ������
 * @Param   p_sid        ������������� ������
 * @Param   p_instance   ���� �������� ������
 */
function session_status(p_uid pls_integer, p_sid pls_integer, p_rtl_instance pls_integer default null) return varchar2;

/**
 * ���������������� �������, ���������� � �������������
 * ����������� (������-������ ��), � �������� ID ������
 * ������������� �������� AUDSID ������ (V$SESSION.AUDSID)
 * Oracle, � ������� ������������ ���������� � �������� Oracle.
 */
function is_session_2l(p_session_id pls_integer) return boolean;

/**
 * ���������������� �������, ���������� � �������������
 * ����������� (������ - ������ ����������, ��, - ������ ��),
 * � �������� ID ������ ������������� ������������ ��������
 * �������� � ��������� -1073741824..-2147483647.
 */
function is_session_3l(p_session_id pls_integer) return boolean;

/**
 * ���������������� �������, ������������� ����� �������
 * ������� Oracle (DBA_JOBS), � �������� ID ������ �������������
 * ������������� �������� ������ ������� � ������� ������� Oracle
 * (DBA_JOBS) - �������� �������� -1..-1073741823.
 */
function is_session_job(p_session_id pls_integer) return boolean;

function get_user_id(p_ses varchar2) return pls_integer;

/**
 * ���������, ��������� � �������� ����������� ��������
 */
function get_rtl_users_props(p_id number, p_name varchar2) return varchar2;
pragma RESTRICT_REFERENCES ( get_rtl_users_props, WNDS, WNPS, RNDS, RNPS, TRUST );
procedure set_rtl_users_props(p_id number, p_name varchar2, p_value varchar2); 
function del_rtl_users_props(p_id number) return boolean;

end rtl_utils;
/
show errors package rtl_utils
