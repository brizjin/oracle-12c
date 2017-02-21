prompt session_service
create or replace
package session_service is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/session_service1.sql $<br/>
 *  $Author: kurkin $<br/>
 *  $Revision: 56855 $<br/>
 *  $Date:: 2014-12-02 17:01:22 #$<br/>
 *  @headcom
 */
/*� ������������ APP_ADM, ��������� ����� �� ���� �����*/
NO_SUCH_SESSION exception;
PRAGMA EXCEPTION_INIT(NO_SUCH_SESSION, -20655);

/**
 * Versioning.
 * @return                         ������ �������.
 */
function get_version return varchar2;

/**
 * ����������� 2L ������.
 * @param   p_read_pipe_messages   ������� ������ � ��������� ���������� �����.
 */
procedure open_session(p_read_pipe_messages boolean := true);

/**
 * ����������� 3L ������.
 * @param   p_os_user               ������������.
 * @param   p_domain                ����� ������������.
 * @param   p_retry                 ������� �������� ������ ������ ������������
 * @param   p_lock_touch_service    ������� ����������� ������ � ���������� ���������
 * @param   p_host_sid              ������������� http ������.
 * @param   p_host_name             ��� �����.
 */
function open_session_3L(p_os_user varchar2,
                         p_domain varchar2,
                         p_retry varchar2 := null,
                         p_lock_touch_service varchar2 := '1',
                         p_host_sid varchar2 := null,
                         p_host_name varchar2 := null) return pls_integer; 

/**
 * �������� ������.
 * @param   p_id                   ������������� ������ (rtl_users).
 */
procedure close_session(p_id pls_integer);

/**
 * �������� ������.
 * @param   p_sid                  V$SESSION.SID.
 * @param   p_serial               V$SESSION.SERIAL#.
 */
procedure kill_session(p_sid pls_integer, p_serial pls_integer);

/**
 * ��������� ��������� ��� ��������.
 * @param   p_id                   ������������� ������ (rtl_users).
 * @param   p_host_sid             ������������� http ������.
 * @param   p_host_name            ��� �����.
 */
procedure set_host(p_id pls_integer, p_host_sid varchar2, p_host_name varchar2);

/**
 * ��������� ����� ����� ��������.
 * @param   p_id                   ������������� ������ (rtl_users).
 * @param   p_host_sid             ������������� http ������.
 * @param   p_host_name            ��� �����.
 */
procedure set_host_name(p_id pls_integer, p_host_sid varchar2, p_host_name varchar2);

/**
 * �������� ������.
 * @param   host_id                   ��� ����� (rtl_users.host_name).
 */
procedure close_sessions(host_id varchar2);
end session_service;
/
show errors

