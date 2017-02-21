create or replace package calendar_mgr is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/calen_mgr1.sql $<br/>
 *  $Author: verkhovskiy $<br/>
 *  $Revision: 50083 $<br/>
 *  $Date:: 2014-08-14 18:23:13 #$
 *  @headcom
 */

/* �� ���� ������� ��������������� �������, �.�. � ��� ������ �� ��������. */
ST_NOT_COMPILED constant pls_integer := 1;
/* ������� ���� ����������������. */
ST_VALID constant pls_integer := 2;
/* ������� �������� ������. */
ST_INVALID constant pls_integer := 3;

NIL constant varchar2(1) := chr(0);

/* ��������� ��� ����������� ���������� � ���������. */
type calendar_rec_t is record (
  id number,
  has_exceptions boolean,
  status pls_integer,
  name varchar2(16),
  rule varchar2(32767)
);

/**
 * �������������� ������ ������� � �������� ��������.
 * @return
 *   <ul>
 *     <li><code>'NOT COMPILED'</code>, ���� <code>p_status = </code><a href="#ST_NOT_COMPILED"><code>ST_NOT_COMPILED</code></a>
 *     <li><code>'VALID'</code>, ���� <code>p_status = </code><a href="#ST_VALID"><code>ST_VALID</code></a>
 *     <li><code>'INVALID'</code>, ���� <code>p_status = </code><a href="#ST_INVALID"><code>ST_INVALID</code></a>
 *     <li><code>null</code> � ��������� �������
 *   </ul>
 */
function status_str_to_num(p_status in varchar2) return pls_integer;
PRAGMA RESTRICT_REFERENCES(status_str_to_num, RNDS, WNDS, WNPS);

/**
 * �������������� ��������� �������� � ������ �������.
 * @return  ���� <code>p_staus</code> �� �� ����������������� ������.
 *   <ul>
 *     <li><a href="#ST_NOT_COMPILED"><code>ST_NOT_COMPILED</code></a>, ���� <code>p_status = 'NOT COMPILED'</code>
 *     <li><a href="#ST_VALID"><code>ST_VALID</code></a>, ���� <code>p_status = 'VALID'</code>
 *     <li><a href="#ST_INVALID"><code>ST_INVALID</code></a>, ���� <code>p_status = 'INVALID'</code>
 *     <li><code>null</code> � ��������� �������
 *   </ul>
 */
function status_num_to_str(p_status in pls_integer) return varchar2;
PRAGMA RESTRICT_REFERENCES(status_num_to_str, RNDS, WNDS, WNPS);

/**
 * ��������� ������� ��������� �� �������� ��� ��� �������.
 */
function get_dates(p_calendar_name in varchar2,
       p_date in date, p_period in binary_integer) return varchar2;

/**
 * �������������� �������� �������, � ������� dbms_sql.parse
 */
FUNCTION check_rule(rule IN VARCHAR2, bRaise IN VARCHAR2 DEFAULT NULL)
    RETURN BINARY_INTEGER;

/**
 * ��������� ���������� �� ��������� ���������.
 * ������������ ��� ���������� ������ ������ � ���, ��� ��� ��������
 * ������ � ���������.
 * @param p_calendar_name ��� ���������.
 * <ul>
 *   <li> ���� <code>p_calendar_name is not null</code>, ��
 *     ��������� ��������� � ����� ������.
 *   <li> ���� <code>p_calendar_name is null</code>, ��
 *     ���������� ��������� ����������.
 * </ul>
 */
procedure update_cache_event(p_calendar_name in varchar2);

/**
 * �������� ���������� � ��������� � ����.
 * ������������ ��� ���������� �� ������ ������ � ���, ��� ��� ��������
 * ������ � ���������. ����, �� ������ ������, � ���� ��� ������ � ���������,
 * ��, ����� �������������� ����� ������ � ������� �� ������������
 * ���� ���������, ��� �� �����������.
 * @param p_calendar_name ��� ���������.
 * <ul>
 *   <li> ���� <code>p_calendar_name is not null</code>, ��
 *     �� ���� ������������ ���������� � ��������� � ����� ������.
 *     ���� ������ ��������� ���, �� ���������� � ��� ��������� �� ����
 *     � �������� ���������� NO_DATA_FOUND.
 *   <li> ���� <code>p_calendar_name is null</code>, ��
 *     ��� ��������� ������������ (�����, ���� �������� ��������� ����������).
 * </ul>
 */
procedure update_cache(p_calendar_name in varchar2);

/**
 * ��������� ���������� � ���������.
 * ���� � ���� ��� ������ � ���������, �� ��� ������������ �� ����,
 * ��� ����, ���� � ���� ���� ������ ���, �� �������� NO_DATA_FOUND.
 * @param p_calendar_name ��� ���������.
 * @param p_info ���� ���������� ������ � ���������.
 */
procedure get_info(p_calendar_name in varchar2, p_info out calendar_rec_t);

/**
 * �������� ���������.
 * @param p_calendar_name ��� ���������.
 * @param p_rule ������� �������� �������������� ����.
 * @param p_description �������� ���������
 */
procedure create_calendar(p_calendar_name in varchar2,
                          p_rule in varchar2, p_description in varchar2);
/**
 * �������������� ���������. ���� �������� ��������� ����� NIL
 *   �� ��������������� ������� �� ��������.
 * @param p_calendar_name ��� ���������.
 * @param p_rule ������� �������� �������������� ����.
 * @param p_description �������� ���������.
 */
procedure edit_calendar(p_calendar_name in varchar2,
                        p_rule in varchar2 := NIL, p_description in varchar2 := NIL);
/**
 * �������� ���������.
 * ����������/������ � ����������� ������, ����������� � ���������, ��������� ����.
 * @param p_calendar_name ��� ���������. ���� <code>p_description is null</code>,
 *   �� ��������� ��� ���������.
 */
procedure delete_calendar(p_calendar_name in varchar2);

/**
 * �������� ����������/������ � ����������� ������.
 */
procedure insert_value(p_calendar_name in varchar2,
                       p_value in date, p_type in varchar2);

/**
 * �������� ����������/������ � ����������� ������.
 * ���� �����-���� �� ���������� <code>is not null</code>,
 * �� ��������� ������ ���������� �� ��������� ����������������
 * ���� ������ ����� ���������. ���� ������ ��� ���� ��������
 * <code>is not null</code> �� ��������������� �������
 * �� �������� ����� ������������� �� <code>and</code>.
 */
procedure delete_value(p_calendar_name in varchar2,
                       p_value in date, p_type in varchar2);
/**
 * ������� ������������� ����������/������ � ����������� ������.
 * ������� �������� ���������� �� �������� ����������
 * <a href="#delete_value(varchar2,date,varchar2)">delete_value</a>
 * @return
 * <ul>
 *   <li> '1' - ���� ����������
 *   <li> '0' - ���� �� ����������
 * </ul>
 */
function has_value(p_calendar_name in varchar2,
                    p_value in date, p_type in varchar2) return varchar2;

/**
 * ����������� ����������.
 */
procedure set_exception(p_calendar_name in varchar2, p_date in date, p_type in varchar2);

/**
 * ������� ����������.
 */
procedure delete_exception(p_calendar_name in varchar2, p_date in date);

/**
 * ��������� ������� � ����������, � ��������������.
 */
procedure set_rule_and_excs(p_calendar_name in varchar2,
        p_rule in varchar2, p_compile in boolean, p_values in varchar2);

/**
 * ������� ��������� ������ calendar_rules. ����� ��������� �������� ��. �
 * <a href="#build_calendar_rules_body">build_calendar_rules_body</a>
 */
PROCEDURE build_calendar_rules_iface;

/**
 * ������� ���� ������ calendar_rules.
 * ����� �������� ����� ���� �������
 * <code>function check_date(id number, d date) return varchar2;</code>,
 * ������� ��������� ����������� �� ���� <code>d</code> ��������� <code>id</code>.
 * ����� ����� ����� �� ��������� �������� ����� ������������ sql.
 * @return
 * <ul>
 *   <li> '1' - ���� �����������
 *   <li> '0' - ���� �� �����������
 *   <li> null - ���� �� ������ ��������� ������ ��������� <code>id</code>
 *     �� ������������, ���� �� �������� ������������� �������� �������
 *     �� �������������� ���.
 * </ul>
 */
PROCEDURE build_calendar_rules_body;

/**
 * TOOLS\CALENDAR\c_undo.sql
 */
procedure register_calendar;
/**
 * TOOLS\CALENDAR\c_first.sql
 */
procedure unregister_calendar;
/**
 * �������� ���� � ���������
 */
function check_date(CALENDAR IN OUT NOCOPY CALENDAR_REC_T,D IN date,RULEONLY IN varchar2) return varchar2;
END calendar_mgr;
/
sho err

