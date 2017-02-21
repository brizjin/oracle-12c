prompt rtl
create or replace
package rtl is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtl1.sql $<br/>
 *  $Author: vzhukov $<br/>
 *  $Revision: 89171 $<br/>
 *  $Date:: 2015-12-22 15:33:32 #$<br/>
 *  @headcom
 */
--
-- Predefined PLplus exceptions
--
    NO_DATA_FOUND exception;
    TOO_MANY_ROWS exception;
--
    CHECK_OBJECT  exception;
    PRAGMA EXCEPTION_INIT(CHECK_OBJECT, -20400); -- exception in check_obj procedure
    CANNOT_LOCK   exception;
    PRAGMA EXCEPTION_INIT( CANNOT_LOCK, -20500); -- reraised on RESOURCE_BUSY, RESOURCE_WAIT
    RESOURCE_BUSY exception;
    PRAGMA EXCEPTION_INIT( RESOURCE_BUSY, -54 ); -- ORA-00054: resource busy and acquire with NOWAIT specified
    RESOURCE_LOCK exception;
    PRAGMA EXCEPTION_INIT( RESOURCE_LOCK, -60 ); -- ORA-00060: deadlock detected while waiting for resource
    RESOURCE_WAIT exception;
    PRAGMA EXCEPTION_INIT(RESOURCE_WAIT,-30006); -- ORA-30006: resource busy; acquire with WAIT timeout expired
    DML_ERRORS    exception;
    PRAGMA EXCEPTION_INIT( DML_ERRORS,  -24381); -- ORA-24381: error(s) in array DML
    INVALID_PACKAGE_STATE exception;
    PRAGMA EXCEPTION_INIT( INVALID_PACKAGE_STATE, -6508 ); -- ORA-06508: PL/SQL: could not find program unit being called
    RESET_PACKAGE_STATE exception;
    PRAGMA EXCEPTION_INIT( RESET_PACKAGE_STATE, -4061 ); -- ORA-04061: existing state of ... has been invalidated
    OFFLINE_PARTITION exception;
    PRAGMA EXCEPTION_INIT( OFFLINE_PARTITION, -376 ); -- ORA-00376: file ... cannot be read at this time
    CLASS_PROCESSING   exception;
    PRAGMA EXCEPTION_INIT( CLASS_PROCESSING, -20999); -- standard interface exception
    NO_PRIVILEGES     exception;
    PRAGMA EXCEPTION_INIT( NO_PRIVILEGES   , -1031 ); -- ORA-01031: insufficient privileges
    NUMERIC_OVERFLOW exception;
    PRAGMA EXCEPTION_INIT( NUMERIC_OVERFLOW, -1426 ); -- ORA-01426: numeric overflow
    NULL_PASSWORD    exception;
    PRAGMA EXCEPTION_INIT( NULL_PASSWORD, -1005 ); -- ORA-01005 null password given; logon denied
    SNAPSHOT_TOO_OLD exception;
    PRAGMA exception_init(SNAPSHOT_TOO_OLD,-1555); -- ORA-01555: snapshot too old: rollback segment number  with name ... too small
--
    /* ������ ��������� */
    TB$  constant varchar2(1) := chr(9);
    /* ������ ��������� ������ */
    LF$  constant varchar2(1) := chr(10);
    /* ������ �������� ������� */
    CR$  constant varchar2(1) := chr(13);
    /* ������ escape */
    ESC$ constant varchar2(1) := chr(27);
    /* ����� ������ */
    NL$  constant varchar2(2) := chr(13)||chr(10);
--
    /* ��� ������ ���������� ����������.*/
    DEBUG2NULL constant varchar2(1) := 'N';
    /* ����� ���������� ���������� � ����� ������. */
    DEBUG2BUF  constant varchar2(1) := 'B';
    /* ����� ���������� ���������� � LOG-������� DIARY. */
    DEBUG2LOG  constant varchar2(1) := 'L';
    /* ����� ���������� ���������� � PIPE-�����. */
    DEBUG2PIPE constant varchar2(1) := 'P';
    /* ����� ���������� ���������� � ���������� ����. */
    DEBUG2FILE constant varchar2(1) := 'F';
    /* ������ PIPE �� ��������� (32�). */
    DEBUGPIPESIZE   constant pls_integer := 32764;
    /* ������ ������ ������ (SERVEROUTPUT) �� ��������� (100K). */
    DEBUGBUFFERSIZE constant pls_integer := 102400;
--
    /* ��������� ���������. */
    STRING_EXPR    constant varchar2(1) := 'S';
    /* �������� ���������. */
    NUMBER_EXPR    constant varchar2(1) := 'N';
    /* ��������� ���� ����. */
    DATE_EXPR      constant varchar2(1) := 'D';
    /* ���������� ���������. */
    BOOLEAN_EXPR   constant varchar2(1) := 'B';
    session_id     varchar2(20);
    usr$  varchar2(30);
    uid$  number;
--
    /**
     * ������ � ���������� ������ ������� ������.
     */
    type object_rec is record (
        id              varchar2(128),
        class_id        varchar2(16),
        collection_id   number,
        state_id        varchar2(16)
    );
    /**
     * ������ � ����������� �������
     */
    type debug_rec is record (
        debug_dir       varchar2(1),
        debug_pipe_name varchar2(30),
        debug_file_name varchar2(500),
        debug_level     pls_integer,
        debug_buf_size  pls_integer,
        debug_pipe_size pls_integer,
        debug_file_handle pls_integer
    );
    subtype REFERENCE_TABLE  is constant.NUMBER_TABLE;
    subtype STRING_TABLE     is constant.STRING_TABLE;
    subtype DEFSTRING_TABLE  is constant.DEFSTRING_TABLE;
    subtype REFSTRING_TABLE  is constant.REFSTRING_TABLE;
    subtype BOOLSTRING_TABLE is constant.BOOLSTRING_TABLE;
    subtype MEMO_TABLE       is constant.MEMO_TABLE;
    subtype DATE_TABLE       is constant.DATE_TABLE;
    subtype NUMBER_TABLE     is constant.NUMBER_TABLE;
    subtype BOOLEAN_TABLE    is constant.BOOLEAN_TABLE;
    subtype INTEGER_TABLE    is constant.INTEGER_TABLE;
    subtype RAW_TABLE        is constant.RAW_TABLE;
    subtype DEFRAW_TABLE     is constant.DEFRAW_TABLE;
    subtype ROWID_TABLE      is constant.ROWID_TABLE;
    type    OBJECT_TABLE     is table of object_rec index by binary_integer;
    type    STRING40_TABLE   is table of varchar2(40)  index by binary_integer;
    type    STRING300_TABLE  is table of varchar2(300) index by binary_integer;
--
    ACT_CHK_VALID_SN constant pls_integer := 0;
    ACT_CALL_TRN_CHK constant pls_integer := 1;
    ACT_CALL_TRN_MTD constant pls_integer := 2;
    ACT_FINISH constant pls_integer := 3;
--
    LOOP_NULL constant pls_integer := 0;
    LOOP_S constant pls_integer := 1;
    LOOP_M constant pls_integer := 2;
    LOOP_SM constant pls_integer := 3;
--
    type pass_state_context_t is record (
        activity    pls_integer,
        stack_idx   pls_integer, -- idx in stack of to_change_state backups
        loop_type   pls_integer,
        obj_id      varchar2(128),
        class_id    varchar2(16),
        state_id    varchar2(16),
        fstate_id   varchar2(16),
        method      varchar2(16),
        state_name  varchar2(200),
        meth_sname  varchar2(16),
        trans_id    varchar2(16),
        position    number,
        chk_access  boolean,
        trn_access  boolean,
        result      boolean
    );
    type pass_state_context_tbl_t is table of pass_state_context_t index by binary_integer;
--
    /**
     * ���������� ������� �������� ���� � ������� (������ SYSDATE)
     */
    function  getdate return date;
--
    /**
     * ������� ������������
     */
    function  USR return varchar2 deterministic;
    pragma restrict_references ( usr, wnds, wnps, trust );
--
    /**
     * ����� ���� RAC ������� ������ (��� �������, �.�. ������ �� 0)
     */
    function  RTL0 return number deterministic;
    pragma restrict_references ( rtl0, wnds, wnps, trust );
--
    /**
     * ���������� ����� RAC (��� �������)
     */
    function  RTL_NODES return number deterministic;
    pragma restrict_references ( rtl_nodes, wnds, wnps, trust );
--
    /**
     * ID ���������������� ������
     */
    function  USERID return pls_integer deterministic;
    pragma restrict_references ( userid, wnds, wnps, trust );
    function  get_uid(p_ses varchar2) return pls_integer deterministic;
    pragma restrict_references ( get_uid, wnds, wnps, trust );
    function  get_profile(p_user varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_profile,wnds,wnps,trust);
--  Settings
    function  get_setting(p_name varchar2) return varchar2 deterministic;
    pragma restrict_references(get_setting,wnds,wnps);
    function  setting(p_name varchar2) return varchar2 deterministic;
    pragma restrict_references(setting,wnds,wnps,trust);
    function  num_set(p_name varchar2) return number deterministic;
    pragma restrict_references(num_set,wnds,wnps,trust);
    procedure put_setting(p_name varchar2, p_value   varchar2,
                          p_description varchar2 default null);
    procedure clear_setting(p_name varchar2 default null,p_context boolean default false);
--
    /**
     * ������������� ������� ������� �������, ����� ������ � ������
     * ������ ������ ��� ������ ���������� ����������.
     * @param dlevel ������� ������� ������� (�� ��������� 0).
     * @param ddir ����� ������ (�� ��������� DEBUG2BUF - ����� ������).
     * @param buf_size ������ ������ ������ (�� ��������� NULL), ����
     *   �����, �� ���������� ������������� ������ ������
     *   (�������� ������ ��������������� DEBUGBUFFERSIZE).
     */
    procedure set_debug(dlevel pls_integer default 0,
                        ddir   varchar2 default DEBUG2BUF,
                        buf_size pls_integer default NULL);
    /**
     * ������������� ��� � ������ PIPE ��� ������ ���������� ����������.
     * @param pipe_name ��� PIPE.
     * @param pipe_size ������ PIPE. ������������� ��������, ���� �����,
     *   �� ������ ��������������� ��������� ��������, �������� ������
     *   ��������������� DEBUGPIPESIZE.
     */
    procedure set_debug_pipe(pipe_name varchar2,
                             pipe_size pls_integer default NULL);
    /**
     * ������������� ��� ����������� ����� � ������� ��� ��������.
     * ���� ���������� ���� �� ����� ��� ������, �� ��������� ��� �������.
     * ���������� ����� �� ��������� ������������ � �������� �������
     * ������� ������������.
     * @param file_name ��� ����������� �����. ���� ��� ����� �� ������ ���
     *   ������ ������, �� ��� �� ����������, ���� ��� ������ ���������
     *   <code>'DEFAULT'</code>, ����� ����� ������������ ��������������
     *   ��� ����������� �����.
     * @param file_open ������� ��� ��������.���� <code>file_open=true</code>,
     *   ����� ���������� ���� ����� ������ � ������ ������ ���������,
     *   ����� - � ������ ������ ������ ���������� ���������� � ����.
     */
    procedure set_debug_file(file_name varchar2 default null,
                             file_open boolean default false);
    procedure set_debug_all(p_info debug_rec);
    procedure get_debug_all(p_info in out nocopy debug_rec);
    /**
     * �������� ������� ��������� ���������.
     * @param dlevel ������� �������.
     * @param buf_size ������ ������ ������.
     * @param pipe_name ��� ���������� PIPE.
     * @param pipe_size ������ ���������� PIPE.
     */
    procedure get_debug_info(dlevel out nocopy pls_integer, buf_size  out nocopy pls_integer,
                             pipe_name out nocopy varchar2, pipe_size out nocopy pls_integer);
    /**
     * �������� ������� ��������� �������� �������.
     * @param file_name ��� ����������� �����
     * @param file_handle �������� ����������� �����.
     * <ul>
     *   <li><code>file_handle>0</code> �������� ���������� ��������� �����,
     *   <li><code>file_handle<0</code> - ��� ������ ��������� �������� ��������,
     *   <li><code>file_handle=0</code> - ������ ������������� �������� ����������
     *     (��� ������ � �������� stdio.get_fio_pid),
     *   <li>������ �������� - ���������� ���� ��� �� ��� ������.
     * <ul>
     */
    procedure get_debug_file(file_name out nocopy varchar2, file_handle out nocopy pls_integer);

    /**
     * ������� ���������� ��������� � �������� ������� �������.
     * @param msg ���������
     * @param dlevel ������� (�� ��������� 1). ���������� ���������,
     *   ���� dlevel <= �������� ������ �������, ��������� � set_debug.
     * @param p_put_time ���� ���������� � TRUE (�� ��������� FALSE),
     *   �� � ��������� ����������� ����� ������ ���������.
     * @param p_dir ��������� ����� ������ ����������. �� ��������� NULL,
     *   �.�. ����� � ������������� �����, ���������� ���������� SET_DEBUG,
     *   �������, � ���� �������, �� ��������� ������������� ����� � ����� ������).
     */
    procedure debug ( msg varchar2, dlevel pls_integer default 1,
                      p_put_time boolean  default FALSE,
                      p_dir      varchar2 default NULL,
                      p_code     varchar2 default NULL);
    /**
     * ������� ��������� � ���������� PIPE-�����.
     * ��������� ��� � <a href="#debug(varchar2,pls_integer,boolean,varchar2,varchar2)">debug</a>.
     */
    procedure debug_pipe( msg varchar2, dlevel pls_integer default 1,
                          p_put_time boolean default FALSE);
    /**
     * ������� ��������� � ���������� ���� �� �������.
     * ��������� ��� � <a href="#debug(varchar2,pls_integer,boolean,varchar2,varchar2)">debug</a>.
     */
    procedure debug_file( msg varchar2, dlevel pls_integer default 1,
                          p_put_time boolean default FALSE);
    /**
     * ������� ��������� � LOG-������� DIARY.
     * ��������� ��� � <a href="#debug(varchar2,pls_integer,boolean,varchar2,varchar2)">debug</a>.
     */
    procedure debug_log ( msg varchar2, dlevel pls_integer default 1,
                          p_put_time boolean default FALSE,
                          p_code     varchar2 default NULL);
    /**
     * ������� ��������� � ����� ������.
     * ��������� ��� � <a href="#debug(varchar2,pls_integer,boolean,varchar2,varchar2)">debug</a>.
     */
    procedure debug_buf ( msg varchar2, dlevel pls_integer default 1,
                          p_put_time boolean default FALSE);
    /**
     * ���������� ����� ���������� ���������� �� ���������� ������.
     * ���� � ������ ���������� ������� ����� ���������� (>32k), �����
     * ��� ������� ������� �������� ��������������� �� ��� ���, ����
     * ��� �� ������ NULL (�� ���� ����� ������� ���������� ������
     * �������� �� 32k).
     * @param ddir ���� ������, �� ����������� ����� �� ������ ������.
     */
    function  get_debug_text (ddir varchar2 default DEBUG2BUF,
                              p_clear boolean default TRUE) return varchar2;

    /**
     * ������ ����������� ����������.
     * @param p_topic
     * @param p_text
     * @param p_id
     * @param p_code
     * @param p_user
     * @param p_audsid
     */
    procedure write_log( p_topic varchar2, p_text varchar2, p_id number default null,
                         p_code  varchar2 default null, p_user varchar2 default null, p_audsid number default null);

    /**
     * ������ ����������� ���������� (� ���������� ����������).
     * ��. �������� <a href="#write_log(varchar2,varchar2,number,varchar2,varchar2,number)">write_log</a>
     */
    procedure writelog ( p_topic varchar2, p_text varchar2, p_id number default null,
                         p_code  varchar2 default null, p_user varchar2 default null, p_audsid number default null);
    procedure log_param ( p_id number, p_qual varchar2, p_text varchar2, p_base varchar2 default null );
    procedure log_vals  ( p_obj_id varchar2, p_qual varchar2, p_base varchar2 default null, p_value varchar2 default null, p_class_id varchar2 default null );
    procedure log_state ( p_obj_id varchar2, p_state varchar2, p_class_id varchar2 default null );
    procedure log_colls ( p_obj_id varchar2, p_collection number, p_class_id varchar2 default null, p_parent varchar2 default null );
--
    function get_class ( p_object_id in out nocopy varchar2,
                         p_class varchar2 default NULL,
                         p_info  varchar2 default NULL,
                         p_key number default NULL
                       ) return varchar2 deterministic;
    /**
     * ���������� ��������� OBJECT �� ������ p_object_id.
     * ���� �������� p_lock ���������� � TRUE, �� ������������
     * ������ ����������� � ��������� ���������� � ���������� p_info.
     */
    function get_object ( p_object_id varchar2,
                          p_info  varchar2 default NULL,
                          p_lock  boolean  default FALSE,
                          p_class varchar2 default NULL
                        ) return object_rec;
    /**
     * ���������� ������� p_object_id (select for update nowait),
     * ��� ��������� ���������� ��������� ���������� CANNOT_LOCK.
     * P_info - ������������� ��������, ������ ����������.
     */
    procedure lock_object ( p_object_id varchar2,
                            p_info  varchar2 default NULL,
                            p_class varchar2 default NULL,
                            p_wait  number default null);
    /**
     * ���������� ������� p_object_id (select for update),
     * p_info - ������������� ��������, ������ ����������.
     */
    procedure lock_object_wait ( p_object_id varchar2,
                                 p_info  varchar2 default NULL,
                                 p_class varchar2 default NULL,
                                 p_wait  number default null );
    procedure Lock_Params (p_retry  out nocopy pls_integer, p_delay out nocopy number);
    procedure Lock_Params1(p_active out nocopy pls_integer, p_size  out nocopy pls_integer);
    procedure rtl_info(p_ulist out nocopy pls_integer, p_llist out nocopy pls_integer, p_refresh out nocopy pls_integer,
                       p_lbc out nocopy varchar2, p_lks out nocopy varchar2, p_list in out nocopy integer_table);
--
    /**
     * ������������� ���������� ��������� �����.
     */
    procedure Randomize;

    /**
     * ��������� ����� � �������� ���������.
     * @return ��������� ����� � ��������� �� 0 �� p_base (�� ��������� �� 0 �� 1).
     */
    function  Random ( p_base number default 1 ) return number;
    pragma restrict_references ( random, wnds, trust );
--
    /**
     * �������������� varchar2 � boolean.
     * @return
     * <ul>
     *   <li><code>null</code> ���� <code>p_ok is null</code>.
     *   <li><code>false</code> ���� <code>p_ok=constant.NO</code>.
     *   <li><code>true</code> � ��������� ������.
     * </ul>
     */
    function char_bool ( p_ok    varchar2) return boolean;
    pragma restrict_references ( char_bool, wnds, wnps );

    /**
     * �������������� boolean � varchar2.
     * @return
     * <ul>
     *   <li>C����� p_true ���� ok=true,
     *   <li>C����� p_false ���� ok=false,
     *   <li>������ p_null ���� ok is null.
     * </ul>
     */
    function bool_char ( ok boolean,
                         p_true  varchar2 default '1',
                         p_false varchar2 default '0',
                         p_null  varchar2 default NULL
                       ) return varchar2;
    pragma restrict_references ( bool_char, wnds, wnps );

    /**
     * �������������� boolean � number.
     * @return
     * <ul>
     *   <li>����� p_true ���� ok=true,
     *   <li>����� p_false ���� ok=false,
     *   <li>����� p_null ���� ok is null.
     * </ul>
     */
    function bool_num ( ok boolean,
                        p_true  number default 1,
                        p_false number default 0,
                        p_null  number default NULL
                      ) return number;
    pragma restrict_references ( bool_num,  wnds, wnps );
--
    /**
     * ���������� �������� ��� �������� �������, �������� ����������� �����.
     * @param p_class_id ������������� ������.
     * @return �������� ��� �������� ������� (ENTITY_ID).
     */
    function class_entity ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma restrict_references ( class_entity, wnds, wnps, trust );

    /**
     * ���������� �������� ��� ������������� ������ �� ��������� � ������.
     * @param p_class_id ������������� ������.
     * @return �������� ��� ������������� ������ (PARENT_ID).
     */
    function class_parent ( p_class_id IN varchar2 ) return varchar2 deterministic;
    pragma restrict_references ( class_parent, wnds, wnps, trust );

    /**
     * ���������� ������, �������� ����������� ���������.
     * @param p_collect ������������� ���������.
     */
    function get_parent ( p_collect number,
                          p_class   varchar2 default NULL ) return object_rec;
    /**
     * ���������� cc���� �� ������, �������� ����������� ���������.
     * @param p_collect ������������� ���������.
     */
    function collection_parent ( p_collect IN number,
                                 p_class   IN varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� �������� ��� (CLASS_ID) ������ �������, �������� ����������� ���������.
     * @param p_collect ������������� ���������.
     */
    function collection_class  ( p_collect IN number,
                                 p_class   IN varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� �������� ��� ������������� ������ �� ��������� � ������ �������.
     * @param p_object_id ������������� �������.
     * @param p_class ����� �������. ���� �� �����, ������������ ������ �������.
     * @return �������� ��� ������������� ������ (PARENT_ID).
     */
    function object_class_parent ( p_object_id IN varchar2,
                                   p_class varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� �������� ��� �������� �������, �������� ����������� ����� �������.
     * @param p_object_id ������������� �������.
     * @param p_class ����� �������. ���� �� �����, ������������ ������ �������.
     * @return �������� ��� �������� ������� (ENTITY_ID).
     */
    function object_class_entity ( p_object_id IN varchar2,
                                   p_class varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� �������� ��� ������, �������� ����������� ������.
     * @param p_object_id ������������� �������.
     * @return �������� ��� (CLASS_ID) ������.
     */
    function object_class ( p_object_id IN varchar2,
                            p_class varchar2 default NULL, p_key number default NULL ) return varchar2 deterministic;
    /**
     * ���������� ������������� ���������, ������� ����������� ������.
     * @param p_object_id ������������� �������.
     * @param p_class ����� �������. ���� �� �����, ������������ ������ �������.
     * @return ������������� ��������� (COLLECTION_ID).
     */
    function object_collection ( p_object_id IN varchar2,
                                 p_class varchar2 default NULL ) return number deterministic;
    /**
     * ���������� ������������� �������� ��������� �������.
     * @param p_object_id ������������� �������.
     * @param p_class ����� �������. ���� �� �����, ������������ ������ �������.
     * @return ��������� ������� (STATE_ID).
     */
    function object_state ( p_object_id IN varchar2,
                            p_class varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� cc���� �� ������, ��������� �������� ����������� �������� ������.
     * @param p_object_id ������������� �������.
     * @param p_class ����� �������. ���� �� �����, ������������ ������ �������.
     */
    function object_parent ( p_object_id IN varchar2,
                             p_class varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� �������� ��� ������ �������, ��������� �������� ����������� �������� ������.
     * @param p_object_id ������������� �������.
     * @param p_class ����� �������. ���� �� �����, ������������ ������ �������.
     */
    function object_parent_class ( p_object_id IN varchar2,
                                   p_class varchar2 default NULL ) return varchar2 deterministic;
    /**
     * ���������� �������� ����� ����������
     * @param p_object_id ������������� �������.
     * @param p_class ����� ������� (������ ���� �����, ������ ������� �� ������������)
     */
    function get_key ( p_object_id IN varchar2,
                       p_class varchar2 default NULL
                     ) return varchar2;
--
    /**
     * ������ ��������� ��� ����� ��������.
     * @param str �������� ������
     * @param str1 ������ ��� ���������, ������� ����� ����� � str
     *   ���� �����, �� ������������ �� ���������������� ������.
     * @param str2 ������ �� ������� ���������� ��� ��������� str1 � str.
     *   ���� �����, �� ��� ��������� str1 ���������.
     * @return ������, ���������� �� str ����� ������ ���� ���������
     *   ��������� str1 �� str2 (������ ����� � ������ case insensitive).
     */
    function safe_replace(str  varchar2,
                      str1 varchar2 default null,
                      str2 varchar2 default null) return varchar2 deterministic;
    pragma restrict_references ( safe_replace, wnds, wnps );
--
    procedure sn2id ( p_class_id    IN  varchar2,
                      p_object_id   IN  varchar2,
                      p_method_name IN  varchar2,
                      p_method_id   OUT varchar2);

    /**
     * ������������� �������� ����� ����� ��������� ����������.
     * ������������ ��������� CHANGE_STATE ���������� (p_change=TRUE)
     * ��� �� ����������(p_change=FALSE - �� ���������) ��������� � �����
     * ��������� ��� �������� (��� ����������) ���������� �������� ��������.
     * ��������� ����� ����� ������ � ��������� ��������� �������� �� ������
     * ��������� � ������. �������� p_stack_idx ��������� ��� ������ ������
     * ������ ��������� ��������� ��������� ���� p_change (���� ��������
     * �� ������, �� ������������ ������� �������.
     */
    procedure change_state_error(p_change    boolean default false,
                                 p_stack_idx pls_integer default null);
    /**
     * ���������� �������� ����� ����� ��������� ��� ��������� ������ �������� p_stack_idx
     * (���� ������� �� �����, �� ��� ��������). ������������ �������� - true ��� false.
     * ������ �������� �������� ���������� ������ � ��������. ���� ������ ����������,
     * �� ����������� ����� � �������� �������� � ��������� p_status
     */
    function change_state_error_status(p_status in out nocopy pass_state_context_t,
                                       p_stack_idx pls_integer default null) return boolean;
    /**
     * ���������� ������� ������� ����� ������� ���������
     */
    function change_state_error_idx return pls_integer;
    /**
     * ���������� ���� ������� ��������� �� ���������� �������� (0-������ �����)
     */
    procedure unwind_change_state_error(p_stack_idx pls_integer default 0);

    /**
     * ��������� ������ p_Object_ID � ����� ��������� p_New_State ���
     * ������ �������� � �������� ������ p_Method_Name � ������
     * p_Class_ID. ��� ���������� ��������� ����������� ��� ������������
     * ��������, ��� ��� ��� ��������� ����� ���� �� ����� �������.
     */
    procedure change_state ( p_Object_ID   IN  varchar2,
                             p_New_State   IN  varchar2 default NULL,
                             p_Method_Name IN  varchar2 default NULL,
                             p_Class_ID    IN  varchar2 default NULL,
                             p_Async       IN  boolean  default False
                           );
-- Interface for hard-coded change state calls
    function  pass_state ( obj           in out nocopy object_rec,
                           p_new_state   IN  varchar2 default NULL,
                           p_method_name IN  varchar2 default NULL,
                           p_access      IN  boolean  default FALSE
                          ) return boolean;
    function  call_check ( ctx pass_state_context_t, p_check boolean ) return boolean;
    procedure init_pass_state_ctx(ctx in out nocopy pass_state_context_t,
                                  obj object_rec,
                                  p_new_state   varchar2 default NULL,
                                  p_method_name varchar2 default NULL,
                                  p_access boolean  default FALSE);
    procedure pass$state(ctx in out nocopy pass_state_context_t);
    procedure set_object_state ( p_object_id IN varchar2,
                                 p_state     IN varchar2,
                                 p_class varchar2 default NULL );
    /**
     * ������������� �������������� ������� p_object_id ���������
     * p_collect. ��� ��������� COLLECTION_ID ����� �����������_
     * ������������ ������, ������� ����� ������������ ����������
     * COLLECTION_ID ����� ��������� �������.
     */
    procedure set_object_collection ( p_object_id IN varchar2,
                                      p_collect   IN number,
                                      p_class varchar2 default NULL );
--
    procedure write2log ( p_object_id IN varchar2,
                          p_class varchar2 default NULL );
--
    /**
     * ����� ������� ��������� ������ �� ��������� ��� ����������.
     * ����� ������ �������� �� ������ �� ���� ����������.
     * @param p_class_id ������������� ������ �������� �������.
     * @param p_qual1 ������������ ��������� 1
     * @param p_value1 �������� ��������� 1
     * @param p_qual2 ������������ ��������� 2
     * @param p_value2 �������� ��������� 2
     * @param p_qual3 ������������ ��������� 3
     * @param p_value3 �������� ��������� 3
     * @return ������ �� ��������� ������ � ������ ���������
     *   ������, ����� - NULL ��� ������ ����������.
     * @throws NO_DATA_FOUND
     * @throws TOO_MANY_ROWS
     */
    function  locate_object( p_class_id varchar2,
                             p_qual1    varchar2,
                             p_value1   varchar2,
                             p_qual2    varchar2 default NULL,
                             p_value2   varchar2 default NULL,
                             p_qual3    varchar2 default NULL,
                             p_value3   varchar2 default NULL,
                             p_exact    boolean  default TRUE
                           ) return varchar2;
--
    /**
     * ��������� SQL ������ � block, ���������� 0 ��� ��������
     * ����������, ����� 1. ����� ����� ������ �� 3 bind-����������
     * � ������� p_var1, p_var2, p_var3 � ���������� p_value1, p_value2,
     * p_value3 ��������������.
     */
    function execute_sql ( p_sql_block varchar2,
                           p_var1      varchar2 default NULL,
                           p_value1    varchar2 default NULL,
                           p_var2      varchar2 default NULL,
                           p_value2    varchar2 default NULL,
                           p_var3      varchar2 default NULL,
                           p_value3    varchar2 default NULL,
                           p_var4      varchar2 default NULL,
                           p_value4    varchar2 default NULL,
                           p_var5      varchar2 default NULL,
                           p_value5    varchar2 default NULL
                         ) return integer;
    /**
     * ��������� SQL ������ �� p_sql_block, ���������� 0 ��� ��������
     * ����������, ����� 1. ��� ���� ����� ������ ���� bind-����������
     * � ������ p_var � ��������� p_value. ���� ���������� ����� ����
     * ��������� �������� � ����������� �������, ������� ����� ��������
     * � p_value ��� �������� ���������� �������. ����� ����� ������
     * �� 3 bind-���������� � ������� p_var1, p_var2, p_var3 � ����������
     * p_value1, p_value2, p_value3 ��������������.
     */
    function exec_sql_out( p_sql_block varchar2,
                           p_var       varchar2,
                           p_value  in out nocopy varchar2,
                           p_var1      varchar2 default NULL,
                           p_value1    varchar2 default NULL,
                           p_var2      varchar2 default NULL,
                           p_value2    varchar2 default NULL,
                           p_var3      varchar2 default NULL,
                           p_value3    varchar2 default NULL,
                           p_var4      varchar2 default NULL,
                           p_value4    varchar2 default NULL
                         ) return integer;
    /**
     * ���������� ��������� ���������� ����� �� ������������������
     * � ������ p_seq_name (�������� ������������������ ������,
     * ������������ id ��������, ��������, ��������� - 'SEQ_ID',
     * ������ ��� ���� ������������������ ����������� ����������������
     * select seq_id.nextval, � �� ������������ ������).
     */
    function  next_value ( p_seq_name  varchar2 default null ) return number;
--
    /**
     * ���������� ��������� �������� ���������� ��������� �
     * �������������� p_qualifier. � ������ ������ ���������� NULL.
     */
    function  system( p_qualifier IN  varchar2 default ' ') return varchar2;
--
    /**
     * ��������� ���������, ������������ � p_expression, ����
     * p_type (�� ��������� STRING_EXPR - ��������� ���������) �,
     * ���� ���������� ���� p_transform � true, ����������� ���������
     * � ��������� ������������� (���� p_type<>STRING_EXPR).
     * ���������� ������������ ���������, ���� ������� ���������
     * ���������, ����� ���� ��������� p_expression.
     */
    function  calculate( p_expression IN varchar2,
                         p_type       IN varchar2 default STRING_EXPR,
                         p_transform  IN boolean  default FALSE
                       ) return varchar2;
--
    /**
     * ������� ����� ������ ������ p_class_id (���� ����� p_parent -
     * ������������ �����, �� ������������ �������� �������������
     * ����� p_class_id <-> p_parent). ���������� ������ �� �����
     * ��������� ������. ���� ������ ��������� p_collect, �� ������
     * ��������� � ��������� ���������.
     */
    function  constructor(p_class_id in varchar2,
                          p_parent   in varchar2 default null,
                          p_collect  in number default null
                         ) return varchar2;
    /**
     * ������� ������ p_obj_id (c ������������ ��������� ��������������
     * ������ ������� �������� ������ p_parent). ���� ����� �������
     * p_class �� �����, �� �� ������������ ����� ����������.
     */
    procedure destructor (p_obj_id   in varchar2,
                          p_parent   in varchar2 default null,
                          p_class    in varchar2 default null);
    /**
     * ��������� �������������� ������ p_class_id �������� ������
     * p_parent. ���� p_class_id �� �������� ����������� �� p_parent,
     * �� ����������� ���������� (message.EXEC_EXCEPTION c �������
     * -20100).
     */
    procedure check_child(p_class_id in varchar2,
                          p_parent   in varchar2);
--
    /**
     * ���������� ��������� �������� ��������� qual_ ������� obj_id_.
     * �������� �� ������ ���� ��������� (����������).
     */
    function  get_value (obj_id_ in varchar2,
                         qual_   in varchar2,
                         class_  in varchar2 default null,
                         target_ in boolean  default false ) return varchar2;
    /**
     * ������������� �������� value_ ��� ��������� qual_ ������� obj_id_.
     */
    procedure set_value (obj_id_ in varchar2,
                         qual_   in varchar2,
                         value_  in varchar2,
                         class_  in varchar2 default null);
    procedure get_props ( class_id_  in out nocopy varchar2,
                          qual_      in out nocopy varchar2,
                          p_set      in boolean,
                          self_class in out nocopy varchar2,
                          base_id    in out nocopy varchar2,
                          target_id  in out nocopy varchar2,
                          func       in out nocopy varchar2,
                          prefix     in out nocopy varchar2,
                          suffix     in out nocopy varchar2);
--------------------------------------------------------------------
-- LOCK_INFO
--
type locks_info is record
(
    id       number,
    user_id  pls_integer,
    user_sid pls_integer,
    time     date,
    object   varchar2(128),
    subject  varchar2(16),
    info     varchar2(256),
    einfo    varchar2(512)
);
type users_info is record
(
    id          pls_integer,
    instance    pls_integer,
    sid         pls_integer,
    userid      number,
    logontime   date,
    ses_id      varchar2(20),
    os_user     varchar2(30),
    ora_user    varchar2(30),
    username    varchar2(64),
    info        varchar2(128)
);
--
type locks_tbl is table of locks_info index by binary_integer;
type users_tbl is table of users_info index by binary_integer;
--
    procedure lock_run(p_job in pls_integer default null, p_instance pls_integer default null);
    procedure lock_stop(p_instance pls_integer default null, p_node pls_integer default null, p_mode pls_integer default null);
--
    function  db_readonly return boolean;
    function  info_active return boolean;
    function  info_open   return boolean;
    function  server_test (p_instance pls_integer default null, p_node pls_integer default null) return boolean;
    procedure lock_refresh(p_instance pls_integer default null, p_node pls_integer default null);
    procedure lock_flash  (p_instance pls_integer default null, p_node pls_integer default null);
--
    function  open(p_name varchar2 default NULL,
                   p_info varchar2 default NULL,
                   p_user_id pls_integer default NULL,
                   p_commit  boolean default true
                  ) return pls_integer;
    procedure close(p_user_id pls_integer default NULL,p_stop boolean default false);
    procedure lock_clear(p_all   boolean default FALSE,
                         p_user_id   pls_integer default NULL,
                         p_clear boolean default FALSE);
    procedure lock_touch(p_user_id   pls_integer default null);
--
    procedure set_ids(p_id type_number_table, p_frm boolean default false);
    procedure set_ids(p_id type_refstring_table, p_frm boolean default false);
    procedure set_ids(p_id refstring_table, p_frm boolean default false);
    function fill_ids(p_list varchar2, p_frm boolean default false) return boolean;
--
    procedure lock_put( p_object  varchar2,
                        p_subject varchar2 default NULL,
                        p_info    varchar2 default NULL,
                        p_user_id pls_integer default NULL);
    procedure lock_put_get( p_object  varchar2,
                            p_subject varchar2 default NULL,
                            p_info    varchar2 default NULL);
    procedure lock_put_push(p_object  varchar2,
                            p_subject varchar2 default NULL,
                            p_info    varchar2 default NULL);
    procedure lock_get( p_object  varchar2,
                        p_subject varchar2 default NULL);
    procedure lock_get_push( p_object  varchar2,
                             p_subject varchar2 default NULL);
    procedure lock_del( p_object  varchar2,
                        p_subject varchar2 default NULL);
    function  lock_request(p_object  varchar2,
                           p_info    varchar2 default NULL,
                           p_wait    number   default NULL,
                           p_class   varchar2 default NULL
                          ) return varchar2;
    procedure check_obj(p_object  varchar2, p_get boolean default true, p_class varchar2 default null);
--
    procedure read(p_wait number default 0);
    function  read_answer(p_wait number default 1,
                          p_get  boolean default true) return boolean;
    function  lock_info( l_info in out nocopy locks_info,
                         u_info in out nocopy users_info ) return boolean;
--
    function  req_lock( p_object  varchar2,
                        p_class   varchar2,
                        p_objscn  number,
                        p_info    varchar2,
                        p_einfo   varchar2 default NULL
                      ) return varchar2;
    procedure chk_lock(p_object varchar2, p_objscn number, p_einfo varchar2 default NULL);
    procedure put_lock(p_object  varchar2,
                       p_class   varchar2,
                       p_objscn  number,
                       p_info    varchar2 default NULL,
                       p_einfo   varchar2 default NULL);
    function  get_lock(p_lock in out nocopy locks_info, p_object varchar2) return boolean;
    function  get_user_locks( p_locks in out nocopy locks_tbl,
                              p_user_id   pls_integer default NULL,
                              p_time      date default NULL
                            ) return boolean;
    function  clear_locks( p_object  varchar2,
                           p_user_id pls_integer default null,
                           p_nowait  boolean default false
                         ) return pls_integer;
    function  request_lock( p_object  varchar2,
                            p_class   varchar2,
                            p_info    varchar2 default NULL
                          ) return varchar2;
    function  object_scn( p_object  varchar2,
                          p_class   varchar2
                        ) return number;
    procedure check_lock(p_object varchar2, p_class varchar2);
--
    procedure clear_stack;
    procedure push_info;
    function  pop_info return boolean;
    function  stack_info(p_idx pls_integer default 0) return boolean;
--
    function  get_info( p_object  in out nocopy varchar2,
                        p_subject in out nocopy varchar2,
                        l_info    out nocopy varchar2,
                        l_time    out nocopy date,
                        l_user    out nocopy varchar2,
                        u_ses     out nocopy varchar2,
                        os_user   out nocopy varchar2,
                        ora_user  out nocopy varchar2,
                        username  out nocopy varchar2,
                        u_info    out nocopy varchar2,
                        p_wait    number default 1
                      ) return boolean;
    function get_user_info( u_info in out nocopy users_info,
                            u_idx  pls_integer default null,
                            u_sid  pls_integer default null,
                            p_init boolean default true
                          ) return boolean;
    function get_lock_info( l_info in out nocopy locks_info,
                            l_idx  number default null
                          ) return boolean;
--
    function get_user_list( p_users  in out nocopy users_tbl,
                            ora_user varchar2 default null,
                            p_init   boolean  default true
                          ) return boolean;
    function get_lock_list( p_locks in out nocopy locks_tbl,
                            p_user_id   pls_integer default NULL,
                            p_time      date default NULL,
                            p_subject   varchar2 default NULL,
                            p_user_sid  pls_integer default NULL
                          ) return boolean;
    function get_lock_list( p_locks in out nocopy locks_tbl,
                            p_user  users_info default NULL,
                            p_time  date default NULL,
                            p_subject   varchar2 default NULL
                          ) return boolean;
--
    function  check_job ( p_job in number, p_queue boolean) return pls_integer;
    procedure check_privs(p_job in number, p_queue boolean default true);
    procedure lock_date ( p_date in out nocopy date, p_broken in out nocopy boolean );
    function  lock_hold ( p_hold boolean, p_instance pls_integer default null, p_node pls_integer default null ) return varchar2;
    function  init_user ( p_user in out nocopy users_info ) return boolean;
    function  submit_job( p_submit in out nocopy  boolean, p_commit  boolean default true ) return varchar2;
    function  session_exists(p_uid pls_integer, p_sid pls_integer) return boolean;
    function  session_status(p_uid pls_integer, p_sid pls_integer) return varchar2;
--
    procedure send_event (p_uid pls_integer, p_code  pls_integer, p_event varchar2 default null, p_node pls_integer default null,p_sid pls_integer default null);
    procedure send_events(p_code pls_integer,p_event varchar2 default null,
                          p_user varchar2 default null, p_uid pls_integer default null);
--
    procedure set_context( p_name varchar2, p_value varchar2 );
    procedure init_context;
    procedure lock_context;
    procedure lock_reset;
    procedure lock_init(p_id     pls_integer default null,
                        p_os_user   varchar2 default null,
                        p_os_domain varchar2 default null);
    function init_session(p_os_user varchar2, p_os_domain varchar2, p_clear boolean := false, p_service_lock_touch boolean := true) return pls_integer;
    function  set_server(p_srv pls_integer) return pls_integer;
--
    procedure enable_proxy_mode;
    procedure lock_init_light(p_session_id pls_integer,
                              p_user varchar2,
                              p_mode varchar2 default null);
    procedure lock_reset_light;
    function process_events return varchar2;
--
    procedure lock_log(p_code varchar2,p_text varchar2,p_id pls_integer default null);
    function read_pipe(p_pipe varchar2, p_text in out nocopy varchar2, p_wait in out nocopy pls_integer
                      ) return pls_integer;
    procedure write_pipes(p_text varchar2);
    procedure counts(u in out nocopy pls_integer, l in out nocopy pls_integer);
    procedure counters(u in out nocopy pls_integer, l in out nocopy pls_integer);
    procedure chkusers(setts in out nocopy varchar2,
                       u in out nocopy number_table,
                       s in out nocopy number_table);
    procedure rtlusers(u in out nocopy number_table,
                       s in out nocopy number_table,
                       o in out nocopy string40_table,
                       r in out nocopy string40_table,
                       n in out nocopy refstring_table,
                       i in out nocopy refstring_table,
                       p_cnt in out nocopy pls_integer);
    procedure rtllocks(l in out nocopy string40_table,
                       u in out nocopy number_table,
                       o in out nocopy refstring_table,
                       s in out nocopy string40_table,
                       i in out nocopy defstring_table,
                       t in out nocopy string40_table,
                       p_cnt in out nocopy pls_integer);
    procedure putuser(uidx in out nocopy pls_integer, p_sid in out nocopy pls_integer,
                      p_os_user in out nocopy varchar2,  p_ora_user in out nocopy varchar2,
                      p_username in out nocopy varchar2, p_info in out nocopy varchar2,
                      p_mode varchar2 default null);
    procedure get_v$lock(p_id1 in out nocopy pls_integer, p_id2 in out nocopy pls_integer,
                         p_sid pls_integer, p_typ varchar2, p_req boolean);
    function  get_v$lock_user(p_user in out nocopy users_info,
                              p_id1  pls_integer, p_id2 pls_integer, p_typ varchar2) return pls_integer;
--
end rtl;
/
show errors

