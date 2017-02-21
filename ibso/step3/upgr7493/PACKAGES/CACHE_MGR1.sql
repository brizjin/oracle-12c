prompt cache_mgr
CREATE OR REPLACE
package cache_mgr as
    /**
     * <hr/>
     *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/CACHE_MGR1.sql $<br/>
     *	$Author: sasa $<br/>
     *	$Revision: 50609 $<br/>
     *	$Date:: 2014-08-27 16:44:23 #$<br/>
     *
     * <hr/><br/>
     * <h1>����� ��� ����������� ����������� �����������.</h1>
     *
     * <h2>1 ���������� ��� ���������� ����� ������ �� ��������� ���������� �����������. (��������� ���������)</h2>
     * ����������� ������� ��������� �����������:
     * <ul>
     *   <li><a href="#reg_obj_change(varchar2,varchar2,boolean)">reg_obj_change</a>
     *   <li><a href="#reg_change(varchar2,boolean)">reg_change</a>
     *   <li><a href="#reg_event(pls_integer,varchar2,pls_integer)">reg_event</a>
     * </ul>
     *
     * ���������� ������������ �� ��� ���������  � �� ���������������� �� PL+ ����:
     * <ul>
     *   <li><a href="#cache_commit">cache_commit</a>
     *   <li><a href="#cache_set_savepoint(varchar2)">cache_set_savepoint</a>
     *   <li><a href="#cache_rollback(varchar2)">cache_rollback</a>
     * </ul>
     *
     * <h2>2 ������� (����� ������������ � ���������� ����)</h2>
     *
     * <h3>2.1 ���������� ����� ��� �������� ��������� � pl\sql �������.<A NAME="hashes"></A></h3>
     * <i>���� ���������� ����� ������ � Oracle 8. � ������� ���� ����������� �������������
     * pl\sql ������� ��������� �����. �� Oracle 9 ��������������� ������ cache_mgr,
     * ������� ���������� ��� �����������.</i><br><br>
     * ���� ���� ������������� ��������� � pl\sql ������� �������� �� ����������
     * ��� number ������� � ������������ �������� ������, ����� ���������������
     * ���������� ��������� ��� ���������� ��������:
     * <ul>
     *   <li><a href="#Hash_Id(number)">Hash_Id</a> ��� ����� (number),
     *   <li><a href="#Hash_Str(varchar2)">Hash_Str</a> ��� �����.
     * </ul>
     * ����� ���������, ��� ��� ��� ������� ����� ���������� ���������� ��������
     * ��� ������ ������� ������. ������� ����� ������� � �������� ��� ��������
     * ����, ����� ���������� � �������� ���������� ��� ���� � ������, �� ��������
     * �������� ���, �, ��� �������, �������� ������, ���� ����� ������.
     * ������ ������ ����� ��������� �������� �������������� �����. �������� (����������
     * �������), ����� � ��������� ��� �������� ��������� �� 1 ���� �� ������ ������ �����
     * ��� ����������. ��� ������ ���� ��������� �� 1 ���� �� ������
     * ����������� ���� (������� ������), ���� �� ������� �� ������ �����
     * (�������� ��� � �������). ���� ����� ������������ 1 ��� ����� ������������
     * ��������, ���������� ��� � 0.
     * <h3>2.2 ��������������� ������� ��� ������������ �������� ���������
     * � ������� �������������, �������� ������ ���������� �����.</h3>
     * �������� ������: ����� ������������ ����������� N ��������� ����������������
     * ����������� ���. ���� ���������� ������ � pl\sql ������� � ���� �������.
     * ������� ����������� � pl\sql ������� ����������� �� id � ��������������
     * <a href="#hashes">Hash_Id</a> ��� <a href="#hashes">Hash_Str</a>.
     * ��� ������ ���-�� ����������� � ������� ��������� N, ����� �����������
     * ��� ������, ����� ���������� ����� �� N ����������� ������������� ������ ����
     * � ������� ���, ����� ����� ���-�� ���������� N. ����������� ��� ���:
     * <ul>
     *   <li>��������� ���������� ���� <a href="#lru_list_t(varchar2(128),varchar2(128),pls_integer_table_t,pls_integer_table_t)">lru_list_t</a>
     *   <li>��� ���������� ���������� ���������� ��� ��������� � ����� ������������
     *       ���������� <a href="#lru_touch(varchar2,lru_list_t)">lru_touch</a> � �������� �����
     *       ���������� � pl\sql �������.
     *   <li>����� ����������� ���������� ���������� ��������� �� ����� ���-��.
     *       ���� ��� ����� N, �� �������� <a href="#lru_remove(lru_list_t)">lru_remove(lru_list_t)</a>
     *       � ������� �� ������� ��������� � ������������ ���� �������� ��������.
     *   <li>���� ����� �������� ��� ��� ������� ������������ ��� ���������, �� ����� �������
     *       <a href="#lru_clear(lru_list_t)">lru_clear</a> ���
     *       <a href="#lru_remove(varchar2,lru_list_t)">lru_remove(varchar2,lru_list_t)</a>
     *       ��������������.
     * <ul>
     * @headcom
     */

    /**
     * ������� �����. ������������ �
     * <a href="#lru_list_t(varchar2(128),varchar2(128),pls_integer_table_t,pls_integer_table_t)">lru_list_t</a>.
     * �������� �������� �� 8i ������, ��� ������ ���� ������������ varchar2 ��� ����������.

    type pls_integer_table_t is table
        of varchar2(128) index by varchar2(128);*/
    subtype pls_integer_table_t is constant.refstring_table_s;

    /**
     * ��������� ������ ��� ��������� ������������ ��������
     * � ������� �������������, �������� ������ ���������� �����.
     */
    type lru_list_t is record (
        first varchar2(128),
        last  varchar2(128),
        prev pls_integer_table_t,
        next pls_integer_table_t
    );

    /**
     * ���������� ��� ��� ����� (number).
     * ����� ���������� ���������� �������� ��� ������ �����, ����� �������� ��.
     * <A href="#hashes">���������� ����� ��� �������� ��������� � pl\sql �������</A>.
     * @param p_num �����.
     * @return ��� ����������� �����.
     */
    function Hash_Id (p_num number  ) return pls_integer;

    /**
     * ���������� ��� ��� �����.
     * Hash_Str ���������� ������������� �������� (-1..-2147483647)
     * Hash_Id  ���������� ��������������� �������� (0..2147483646)
     * ����� ���������� ���������� �������� ��� ������ �����, ����� �������� ��.
     * <A href="#hashes">���������� ����� ��� �������� ��������� � pl\sql �������</A>.
     * @param p_str ������.
     * @return ��� ���������� ������.
     */
    function Hash_Str(p_str varchar2) return pls_integer;
    function Hash_Id (p_str varchar2) return pls_integer;

    /**
     * ����������� ��������� ���������� ���. ������������ ��� �������� �����������.
     * @param class_id ������������� ���.
     * @param obj_id ������������� ����������.
     * @param cascade ����������� �� ��������� ���� ������������ ����� (��� ���������� ������ ����� ���������).
     */
    procedure reg_obj_change(class_id varchar2, obj_id varchar2, cascade boolean);

    /**
     * ����������� ��������� ����������� ���. ������������ ��� batch �����������.
     * @param class_id ������������� ���.
     * @param cascade ����������� �� ��������� ���� ������������ ����� (��� ���������� ������ ����� ���������).
     */
    procedure reg_change(class_id varchar2, cascade boolean);

    /**
     * ������������/������� �������.
     * ���� ��������� CLS_STATIC_EVENT in ('Y', '1'), �� �� ����� ������ ����������� ������� p_event � ����� 0.
     * � ��������� ������, ������������ ��� � �������, � ������� ���������� � <a href="#cache_commit">cache_commit</a>
     * @param p_code ��� �������.
     * @param p_event ���� �������.
     * @param p_pipe ��� ����� ��� �������� �������� ������� (������ �������� - �������� �������� �� ����� ��������������)
     */
    procedure reg_event (p_code pls_integer, p_event varchar2, p_pipe varchar2 default null);

    /**
     * ������� ������ ������� ��� �������� ��� ���������� �������� ����������.
     * @param p_code ��� �������, ������� ������� �������� (������ �������� �������� ������� ���� �������.
     */
    procedure reg_clear (p_code pls_integer default null);

    /**
     * �������� ����������. �������� ��������� ������� ����������� �� ���������� ���������� �����������.
     * �������� ��������� ������� ��������������� �������.
     * ���� ��� ������ ��� �������������� ������ max_cnt �����������,
     * �� ��� ������� ���������� ����������� ����������� � ���, ��� ��� ����� �������� �� ����.
     * ���� ��� ������ ��� �������������� >= max_cnt �����������,
     * �� ����������� ����������� � ���, ��� ����� �������� ��� ����� ��� ���������.
     */
    procedure cache_commit(p_autonom boolean default false);

    /**
     * ��������� ����� ����������.
     * @param savepointname ��� ����� ����������.
     */
    procedure cache_set_savepoint(savepointname varchar2);

    /**
     * ����� ���������� (�������� �� ����� ������).
     * ����� ����� ���������� �����. ���� ������������ ��� ����������, �� ����� ���������� �� ����������.
     * @param savepointname ��� ����� ����������. ���� �� ������, �� ������������ ��� ����������.
     */
    procedure cache_rollback(savepointname varchar2 default null,p_autonom boolean default false);

    /**
     * �� ������������ (java placeholders).
     */
    procedure write_cache;
    procedure cache_flush(info varchar2 default null);
    procedure cache_clear(info varchar2 default null);
    procedure cache_refresh_class(classId varchar2);
    procedure cache_refresh(id number);
    procedure cache_refresh(id varchar2);

    /**
     * ��������, ��� ������� � �������� �������� ������������� ���������.
     * @param idx ������ ��������.
     * @param lru_list ������.
     * @return ������ ���������� ��������.
     */
    procedure lru_touch(idx varchar2, lru_list in out nocopy lru_list_t);
    pragma restrict_references(lru_touch, WNDS, WNPS, RNDS, RNPS);

    /**
     * ������� �� ������ ���������� �� �������� � ������� �������������,
     * �������� ������ ���������� �����, � ������� ��� ������.
     * @param lru_list ������.
     * @return ������ ���������� ��������.
     */
    function lru_remove(lru_list in out nocopy lru_list_t) return varchar2;
    pragma restrict_references(lru_remove, WNDS, WNPS, RNDS, RNPS);

    /**
     * ������� �� ������ ���������� �� �������� � �������� ��������.
     * @param idx ������ ��������.
     * @param lru_list ������.
     * @return ������ ���������� ��������.
     */
    procedure lru_remove(idx varchar2, lru_list in out nocopy lru_list_t);
    pragma restrict_references(lru_remove, WNDS, WNPS, RNDS, RNPS);

    /**
     * �������� ������. ���������� ���������� ���������� �������.
     * @param lru_list ������.
     */
    procedure lru_clear(lru_list in out nocopy lru_list_t);
    pragma restrict_references(lru_clear, WNDS, WNPS, RNDS, RNPS);

    /**
     * ��������/������� ���� ������ � ������ �������� �������.
     * ������������ ��� ��������/������� ������ �� ������� ����������
     * ���� ������������ ������� �����.
     * @param p_pipe ����� ��� �������� ������ ������.
     * @param p_add ������� ����������(true)/��������(false) ������.
     */
    procedure reg_pipe_events (p_pipe varchar2, p_add boolean);
    pragma restrict_references(reg_pipe_events, WNDS, WNPS, TRUST);

    /**
     * ��������� ������� �� ��������� ������ ��������.
     * ������������ ��� �������� ������� ���������� ���� ������������
     * ������� ����� �� cache_commit.
     * @param p_pipe ����� ��� �������� ������ ������ ��� ��������.
     * @param p_code ��� ������� (������ �������� ������ ����������� ������ ��������).
     * @param p_event ���� �������.
     */
    procedure send_pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2);

    /**
     * ���������� ������� ������ � �������� �����
     * @param p_init_classes
     * - null (�� ���������)  - ���������� ���� ��� ���������� �����
     * - true - ���������� � ������������� ���� ��� ���������� �����
     * - false - ���������� ������������ ���-����
     */
    procedure refresh_cache_pipes(p_init_classes boolean default null);

    /**
     * ��������� �������� ������� ���������� commit/rollback � ���������
     * @param p_disable
     * - true - ���������� ������
     * - null,false - ����� ������
     */
    procedure set_commit_disabled(p_disable boolean);

    /**
     * ��������� �������� ������� ���������� commit/rollback � ���������
     */
    function  get_commit_disabled return boolean;

    /**
     * �������� �������� ������� ���������� commit/rollback � ���������
     * ��� ������� ������� �������� ������ � ��������������� �������
     * @param p_commit_msg
     * - true (�� ���������) - ��������� � ������� ���������� commit
     * - null,false - ��������� � ������� ���������� rollback
     */
    procedure check_commit(p_commit_msg boolean default true);
	
    /**
     * ����� ���� ��� ���������� ��� ����� ���
     * @param p_class - ����� ����������
     * @param p_cascade - ��������� ���������� ����� ��� �� p_class �� ������ ��������
     * @param p_id - ������������� ���������� (���� �� ������ - ����� ����� ���� ���)
     */
    procedure cache_reset(p_class in varchar2, p_cascade boolean, p_id in varchar2);
end cache_mgr;
/
show err

