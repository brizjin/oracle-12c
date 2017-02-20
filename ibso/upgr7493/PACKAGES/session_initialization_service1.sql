prompt session_initialization_service
create or replace
package session_initialization_service is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/session_initialization_service1.sql $<br/>
 *  $Author: kurkin $<br/>
 *  $Revision: 56851 $<br/>
 *  $Date:: 2014-12-02 16:50:03 #$<br/>
 *  @headcom
 */

/**
 * ���������� �������� ��������� ������������� NLS � Alter_Session ����������
*/
function is_NLS_init return boolean;

/**
 * Versioning.
 * @return            ������ �������.
 */
function get_version return varchar2;

/**
 * ����������� ������������ ������ ������������.
 */
procedure finit_session_immediate;

/**
 * ������������� ���������������� � ��������� ��������.
 * @param   p_class   ������� ������������� ���������.
 */
procedure set_context(p_class varchar2 default null);

/**
 * ˸���� ������������� ������.
 * @param   p_id                     ������������� ������.
 * @param   p_user                   ������������.
 * @param   p_mode                   ������ ������������� ����������.
 * @param   p_attr_mapping_service   ����� ������ ������� ������������� ����������.
 */
procedure init_session_light(p_id pls_integer, p_user varchar2,
                             p_mode varchar2 := null, p_attr_mapping_service varchar2 := null, p_nls_init boolean:=false);

/**
 * ������� ������������� ������.
 * @param   p_id                     ������������� ������.
 * @param   p_os_user                ������������.
 * @param   p_domain                 ����� ������������.
 * @param   p_class                  ������� ������������� ���������.
 */
procedure init_session_heavy(p_id pls_integer, p_os_user varchar2, p_domain varchar2, p_class varchar2 default null, p_nls_init boolean:=false);

/**
 * ����������� ������.
 * @param   p_reset   ������ ������ � ���������������� � ��������� ����������.
 */
procedure finit_session(p_reset varchar2 default null);

/**
 * ˸���� ����������� ������.
 * @param   p_reset   ������ ������ � ���������������� � ��������� ����������.
 */
procedure finit_session_light(p_reset varchar2 default null);

end session_initialization_service;
/
show errors

