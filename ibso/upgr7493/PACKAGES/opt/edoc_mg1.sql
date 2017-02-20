prompt edoc_mgr
create or replace package edoc_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/edoc_mg1.sql $
 *  $Author: almakarov $
 *  $Revision: 42440 $
 *  $Date:: 2014-02-25 11:15:23 #$
 */

/* signs exception */
SIGNS_ERROR_NUMBER constant integer := -20401;
SIGNS_EXCEPTION exception;
pragma exception_init(SIGNS_EXCEPTION, -20401);

/* files exception */
FILES_ERROR_NUMBER constant integer := -20402;
FILES_EXCEPTION exception;
pragma exception_init(FILES_EXCEPTION, -20402);

/* ���������� ������������� �����������/����� */
subtype KEY_ID_TYPE is raw(32);

/* ���� ������ ��� ������� */
subtype BLOCK_TYPE  is raw(2000);

/* ������� ������� PKCS#7/�������*/
subtype SIGN_TYPE   is raw(2000);

/* reglament types */
subtype EDT_ID_TYPE is varchar2(16);

/* Hash ����� */
subtype HASH_TYPE is raw(32);

/* ������ �������� �������� �������� ����� */
subtype STATS_TYPE is raw(2000);

/* attribute */
type edoc_attr_t is record (
    type_id varchar2(16),
    serial_number number,
    qualifier varchar2(700),
    expression varchar2(1024)
);

type edoc_attrs_t is table of edoc_attr_t index by binary_integer;

/* class */
type edoc_class_t is record (
    class_id varchar2(16),
    cls_edt_map_meth varchar2(4000),
    obj_source varchar2(4000),
    cls_frm_map_meth varchar2(16)
);

/* sign */
type edoc_sign_t is record (
    res pls_integer,
    key_id KEY_ID_TYPE,
    type_id varchar2(16),
    charset varchar2(40),
    sign SIGN_TYPE
);

type edoc_signs_t is table of edoc_sign_t index by binary_integer;

/**
 * Licensing
 */
function is_enabled return pls_integer;

/**
 * Versioning
 */
function get_version return varchar2;
function get_kernel_version return varchar2;
function get_admin_interface return varchar2;
function pki_supported return pls_integer;

/**
 * Interface for crypt. server connection handling
 */
procedure logoff;

/**
 * Tools
 */

-- ���� ���� �����������, ����� ����� ���������� ���� � hex-���� � �������,
-- ��� ��� � ���������� ������� �������������� DOS->WIN1251->ISO-8859-5
-- � ����� ����� �������� ����� ��������.

-- ������������� ����� �� row � varchar2
-- � �� ��������� DOS � ��������� ����.
function key2str(k KEY_ID_TYPE) return varchar2;
-- ������������� ����� �� ��������� ���� � ��������� DOS.
-- � �� varchar2 � row
function str2key(s varchar2) return KEY_ID_TYPE;

function bcrraw2str(r raw) return varchar2;
function str2bcrstr(str varchar2) return varchar2;

/**
 * Interface for packages which implement class interface
 */

CDA_START constant pls_integer := 1;
CDA_CHECK_SIGNS constant pls_integer := 2;
CDA_ADD_AS_SIGN constant pls_integer := 3;
CDA_FINISH constant pls_integer := 4;

type transition_ctx_t is record (
    class_id varchar2(16),
    edt_id varchar2(16),
    obj_id varchar2(128),
    is_edoc boolean := false,           -- obj �������� ��� ���������, �.�. �������� ����������� ����������
    ostate_id varchar2(16),
    istate_id varchar2(16),
    state_changed boolean := false,     -- ��������� ���� �������� � �������� ��������
    failed_signs_i boolean := false,    -- ������������ �� ������ ������� ��� ����� � ����� ���������

    archive_check varchar2(1),          -- ��������� ��� ��� ������� �������
    archive_markers varchar2(1),        -- ������� ������� �������� ��������
    archive_ability varchar2(1),        -- ������� ����������� ���������� �������� ��������

    required_signs_i pls_integer,
    required_signs_o pls_integer,
    existing_signs pls_integer,
    role_id_i varchar2(16),
    role_id_o varchar2(16),

    src_id varchar2(16),
    block varchar2(2000),
    sign_dat varchar2(256),

    action pls_integer := CDA_START
);

procedure check_driver(ctx in out nocopy transition_ctx_t);
procedure finish_trans(ctx in transition_ctx_t); -- ��������� �������

/**
 * Interface for Navigator
 */
function get_attrs(p_edt_id varchar2) return varchar2;
procedure add_sign(p_edt_id varchar2, p_obj_id number, p_state_id varchar2,
        p_block BLOCK_TYPE, p_sign SIGN_TYPE, p_characterset varchar2 := null);
/**
 * code - ��� ���������� ��������
 *      0 - ��� OK
 *    > 0 - ���� ������ �������
 *   -100 - �� ������� ���������� ���� � ���� �������� ������
 *     -1 - ������ ���������� � ����������
 *    < 0 - ���� ������ ����������
 * key_id - ������������ �����. ��� ������ ������������
 *   ����� ������������� � ������� key2str.
 */
procedure check_sign(p_id number, p_code out number, p_key_id out KEY_ID_TYPE);
-----------------------------------------------------------------------------
-- ����� ��������������� ��������� �������
-----------------------------------------------------------------------------

/**
 * ����������� �� ��������� � ���������� �������� ��������������� ��������.
 */
function is_as_meth(p_class_id varchar2, p_short_name varchar2) return boolean;

/**
 * ��������� ������ ��������������� ��������� �������. ��������� ���� �
 * ��������� ������������� ����� ��������������� ��������, � �������
 * ������ ��������� � ���������� ��������.
 */
procedure enable_as_sign(p_class_id varchar2, p_short_name varchar2);

/**
 * ���������� ������ ��������������� ��������� �������.
 */
procedure disable_as_sign;

/**
 * �������� ��������� ����� ��������������� ��������� �������.
 * ���� �� ���� ����������� ������ enable_as_sign, �� ������ �� ������.
 */
procedure leave_process;

/**
 * ����� �������� ����� ��������������� ��������� �������.
 * ���� �� ���� ����������� ������ enable_as_sign, �� ������ �� ������.
 */
procedure enter_process;

-----------------------------------------------------------------------------
-- ������������, �������� �������� ���������.
-----------------------------------------------------------------------------

/**
 * ��������� �������������� �������. ���� �� ������� ���������������
 * �����, �� ����������� ����������.
 *
 * �� ������������� � �������������. �������� ��
 * add_sign(p_class_id varchar2, p_edt_id varchar2, p_obj_id number);
 */
procedure add_as_sign(p_class_id varchar2, p_edt_id varchar2, p_obj_id number);

/**
 * ��������� ������� ��� ����� ���������. ���������� � ����� ������ ��������
 * (�������������� �������/������) �, � ����������� �� �����, �����������
 * �������������� �������, ��� ���������� ���������� ��� ����������.
 */
procedure add_sign(p_class_id varchar2, p_obj_id number);

/**
 * ��������� �������� ������� � ��������� �� ������������.
 */
function get_signs(p_class_id varchar2, p_obj_id number,
                signs in out nocopy edoc_signs_t) return pls_integer;

-----------------------------------------------------------------------------
-- ������������ ������
-----------------------------------------------------------------------------

/**
 * � ������ �������� ��������� key_id = null (���� �� �������� ��� ������),
 * ����� ��������� ������ ������������� �� ��������, ������������������ �
 * ���������� ��� ��� �������������� �������. � ���� ������ ���� �����
 * �������� ������ ���������������� ��������������� ��������. � ������
 * ������������� ��������� ���� ��������� ������, ���� ������ ����������������
 * ��������������� ��������, ����� ����������� ���������������� exception,
 * ���������� �������� �������. �������� exception:
 * Raise_application_error(edoc_mgr.FILES_ERROR_NUMBER, ������� �������/�������� �����. ���: � || code);
 * Code = -101: key_id is null � ����� ���� �� ���� ������� edoc_mgr.enable_as_sign,
 * ���� ��� ���� �� �������������� �������.
 */
procedure sign_file(p_file_path varchar2, p_key_id KEY_ID_TYPE := null);

/**
 * �������� ������� �����.
 *
 * filePath - ���� � ����� �� ������� Oracle.
 * eDocID - ���
 * eMemberID - �� ���������.
 * removeSign - ������� �������?
 * key_id - ������������ �� �����, ������� ������������ �������.
 * arch_date - ���� �� null, �� �������� ������� ���������� ��� �� ����������, ��� �
 *    �� �������� ���� �������� ������ �������������� �� ��������� ����.
 *
 * ���� � ����������� �������� ������, ������������� ����� ������� ������,
 * ����� ����������� �� ��������� ���������� �� ���������� ���. �.�. � ����������
 * ������ ������������ ��� ���, �������� <��������� ��>, � �������� ���, ��������
 * <������� �������>. � ������ ������������� ��������� ���� � �����, ���� �������
 * ��� �������� ������� ����� ����������� ���������������� exception, ����������
 * �������� ������������ ������. �������� exception:
 * Raise_application_error(edoc_mgr.FILES_ERROR_NUMBER, '������ �������/�������� �����. ���: ' || code);
 * Code = -100: �� ���� ����� ���� � sign.dat �� ���������� eDocID � eMemberID.
 */
procedure verify_file_sign(p_file_path varchar2
                          ,p_edt_id varchar2
                          ,p_member_id varchar2
                          ,p_remove_sign boolean
                          ,p_key_id in out nocopy KEY_ID_TYPE
                          ,p_arch_date date := null);

/**
 * �������� ������� �����.
 *
 * filePath - ���� � ����� �� ������� Oracle.
 * sign_dat - ���� � ���� �������� ������. ���� �������� ������ ����������� ��
 *    ���������� ����, �� ��� ���������� ����, ��������� ��� �����. ���� �������
 *    �������� arch_date, �� ��� ���� � ���� ������������ ��������� ��������
 *    ������ ��� ����� �����.
 * removeSign - ������� �������?
 * key_id - ������������ �� �����, ������� ������������ �������.
 * arch_date - ���� �� null, �� �������� ������� ���������� ��� �� ����������, ��� �
 *    �� �������� ���� �������� ������ �������������� �� ��������� ����.
 *
 * � ������ ������ ��� �������� ������� ����� ����������� ����������������
 * exception, ���������� �������� ������������ ������. �������� exception:
 * Raise_application_error(edoc_mgr.FILES_ERROR_NUMBER, '������ �������/�������� �����. ���: ' || code);
 */
procedure verify_file_sign(p_file_path      varchar2
                          ,p_sign_dat       varchar2
                          ,p_remove_sign    boolean
                          ,p_key_id         in out nocopy KEY_ID_TYPE
                          ,p_arch_date      date := null);

/**
 *   ���������� hash �����
 *
 * p_file_path - ���� � ����� �� ������� Oracle.
 * p_hash_file - Hash �����
 */
procedure get_hash_file(p_file_path varchar2, p_hash_file out HASH_TYPE);

/**
 *   �������� ������� �������� �����
 *
 * p_file_path - ���� � ����� �� ������� Oracle.
 * p_signed_data - ���� � ���� �������� ������. ���� �������� ������ ����������� ��
 *    ���������� ����, �� ��� ���������� ����, ��������� ��� �����. ���� �������
 *    �������� arch_date, �� ��� ���� � ���� ������������ ��������� ��������
 *    ������ ��� ����� �����.
 * p_remove_sign - ������� �������? �� ����������� ����!
 * p_signs - ������� ����� edoc_sign_t.
 * p_arch_date - ���� �� null, �� �������� ������� ���������� ��� �� ����������, ��� �
 *    �� �������� ���� �������� ������ �������������� �� ��������� ����.
 *
 * ��� ��������� ����������� �������� �������� �� ����� ���������� �������� ������� ������� � ������� p_signs,
 * ������� ���������� ��������� ��������. ��� ����, ������ ������� ��������� �������������.
 * ������:
 *  declare
 *    file_name constant varchar2(50) := 'c:\001.jpg';
 *    signed_data varchar2(200) := 'C:\Cryptobox\sign.dat';
 *    signs edoc_mgr.edoc_signs_t;
 *    sign1 edoc_mgr.edoc_sign_t;
 *  begin
 *    signs(0) := sign1;
 *    edoc_mgr.check_file_signs(file_name,signed_data,false,signs);
 *  end;
 *
 * � ���� edoc_sign_t ������������ ������ ���� res � key_id. � ��� ������������ ��������� ��������:
 * 1) ���� p_signs.res = 0, �� �������� ������ ������� � � p_signs.key_id ��������� ����
 * 2) ���� p_signs.res < 0, �� ������ ��������� �������������� � ��������������
 * 3) ���� p_signs.res > 0, �� ���� �� ������ ���������
 */
procedure check_file_signs(p_file_path   varchar2
                          ,p_signed_data varchar2
                          ,p_remove_sign boolean
                          ,p_signs in out nocopy edoc_signs_t
                          ,p_arch_date date := null);

/**
 *   �������� ������� �������� �����
 *
 * p_file_path - ���� � ����� �� ������� Oracle.
 * eDocID - ���
 * eMemberID - �� ���������.
 * p_remove_sign - ������� �������? �� ����������� ����!
 * p_signs - ������� ����� edoc_sign_t.
 * p_arch_date - ���� �� null, �� �������� ������� ���������� ��� �� ����������, ��� �
 *    �� �������� ���� �������� ������ �������������� �� ��������� ����.
 *
 * ��� ��������� ����������� �������� �������� �� ����� ���������� �������� ������� ������� � ������� p_signs,
 * ������� ���������� ��������� ��������. ��� ����, ������ ������� ��������� �������������.
 * ������:
 *  declare
 *    file_name constant varchar2(50) := 'c:\001.jpg';
 *    signs edoc_mgr.edoc_signs_t;
 *    sign1 edoc_mgr.edoc_sign_t;
 *    ted_id edoc_types.id%type;
 *    member_id edoc_members.id%type;
 *  begin
 *    signs(0) := sign1;
 *    ted_id := 'TEST1';
 *    member_id := 'FILIAL1';
 *    edoc_mgr.check_file_signs(file_name,ted_id,member_id,false,signs);
 *  end;
 *
 * � ���� edoc_sign_t ������������ ������ ���� res � key_id. � ��� ������������ ��������� ��������:
 * 1) ���� p_signs.res = 0, �� �������� ������ ������� � � p_signs.key_id ��������� ����
 * 2) ���� p_signs.res < 0, �� ������ ��������� �������������� � ��������������
 * 3) ���� p_signs.res > 0, �� ���� �� ������ ���������
 *
 * ���� � ����������� �������� ������, ������������� ����� ������� ������,
 * ����� ����������� �� ��������� ���������� �� ���������� ���. �.�. � ����������
 * ������ ������������ ��� ���, �������� <��������� ��>, � �������� ���, ��������
 * <������� �������>. � ������ ������������� ��������� ���� � �����, ���� �������
 * ��� �������� ������� ����� ����������� ���������������� exception, ����������
 * �������� ������������ ������. �������� exception:
 * Raise_application_error(edoc_mgr.FILES_ERROR_NUMBER, '������ �������/�������� �����. ���: ' || code);
 * Code = -100: �� ���� ����� ���� � sign.dat �� ���������� eDocID � eMemberID.
 */
procedure check_file_signs(p_file_path   varchar2
                          ,p_edt_id varchar2
                          ,p_member_id varchar2
                          ,p_remove_sign boolean
                          ,p_signs in out nocopy edoc_signs_t
                          ,p_arch_date date := null);
-----------------------------------------------------------------------------
-- ������������ ����� ������
-----------------------------------------------------------------------------

/**
 * � ������ �������� ��������� key_id = null (���� �� �������� ��� ������),
 * ����� ��������� ������ ������������� �� ��������, ������������������ �
 * ���������� ��� ��� �������������� �������. � ���� ������ ���� �����
 * �������� ������ ���������������� ��������������� ��������.
 * ���� key_id is null � ����� ���� �� ���� ������� edoc_mgr.enable_as_sign,
 * �� ������� ������ -101
 */
function sign_data(p_key_id KEY_ID_TYPE := null, p_data raw, p_sign out SIGN_TYPE) return pls_integer;

/**
 * �������� ������� ����� ������.
 *
 * sign_dat - ���� � ���� �������� ������. ���� �������� ������ ����������� ��
 *    ���������� ����, �� ��� ���������� ����, ��������� ��� �����. ���� �������
 *    �������� arch_date, �� ��� ���� � ���� ������������ ��������� ��������
 *    ������ ��� ����� �����.
 * data - ���� ������.
 * sign - �������.
 * key_id - ������������ �� �����, ������� ������������ �������.
 * arch_date - ���� �� null, �� �������� ������� ���������� ��� �� ����������, ��� �
 *    �� �������� ���� �������� ������ �������������� �� ��������� ����.
 * p_convert_sign_dat - ������� ����������� p_signed_data �� ��������� ����������� � ��������� �������.
 */
function verify_data_sign(p_sign_dat  varchar2
                         ,p_data      raw
                         ,p_sign      SIGN_TYPE
                         ,p_key_id    in out nocopy KEY_ID_TYPE
                         ,p_arch_date date := null
                         ,p_convert_sign_dat boolean := false) return pls_integer;

/**
 * Block to sign
 */
procedure Ress(s varchar2);
procedure PutS(s varchar2);
procedure Put(s varchar2);
procedure Put(n number);
procedure Put(b boolean);
procedure Put(d date);
function GetAll return varchar2;

procedure install;

/**
 * �������� �������������.
 * Reglament manager uses these
 */
procedure create_class(p_class_id varchar2, p_cls_edt_map_meth varchar2,
        p_obj_source varchar2, p_cls_frm_map_meth varchar2);
procedure edit_class(p_class_id varchar2, p_cls_edt_map_meth varchar2 := null,
        p_obj_source varchar2 := null, p_cls_frm_map_meth varchar2 := null);
procedure delete_class(p_class_id varchar2);
procedure get_class(p_class in out nocopy edoc_class_t);

procedure create_type(p_type_id EDT_ID_TYPE, p_class_id varchar2, p_path varchar2, p_name varchar2);
procedure edit_type(p_type_id EDT_ID_TYPE, p_path varchar2 := null, p_name varchar2 := null);
procedure delete_type(p_type_id EDT_ID_TYPE);
procedure get_types(p_class varchar2, p_types in out nocopy constant.refstring_table);

procedure create_state(p_type_id EDT_ID_TYPE, p_state_id varchar2,
                        p_required_signs_i number, p_required_signs_o number, p_marker varchar2 := null);
procedure create_state2(p_type_id EDT_ID_TYPE, p_state_id varchar2,
                        p_required_signs_i number, p_required_signs_o number, p_marker varchar2, p_failed_signs_i varchar2);
procedure edit_state(p_type_id EDT_ID_TYPE, p_state_id varchar2,
                        p_required_signs_i number, p_required_signs_o number, p_marker varchar2 := null);
procedure edit_state2(p_type_id EDT_ID_TYPE, p_state_id varchar2,
                        p_required_signs_i number, p_required_signs_o number, p_marker varchar2, p_failed_signs_i varchar2);
procedure delete_state(p_type_id EDT_ID_TYPE, p_state_id varchar2 := null);
procedure get_states(p_type varchar2, p_states in out nocopy constant.refstring_table);

procedure create_attr(p_type_id EDT_ID_TYPE, p_qualifier varchar2,
        p_expression varchar2, p_serial_number number := null);
procedure edit_attr(p_type_id EDT_ID_TYPE, p_serial_number number,
            p_qualifier varchar2, p_expression varchar2);
procedure delete_attr(p_type_id EDT_ID_TYPE, p_qualifier varchar2 := null);
procedure get_attrs(p_type varchar2, p_attrs in out nocopy edoc_attrs_t);

procedure create_member(p_member_id EDT_ID_TYPE, p_path varchar2, p_name varchar2);
procedure edit_member(p_member_id EDT_ID_TYPE, p_path varchar2 := null, p_name varchar2 := null);
procedure delete_member(p_member_id EDT_ID_TYPE);

procedure create_process(p_process_id varchar2, p_name varchar2, p_key_id KEY_ID_TYPE);
procedure edit_process(p_process_id varchar2, p_name varchar2, p_key_id KEY_ID_TYPE);
procedure delete_process(p_process_id varchar2);

procedure add_proc_meth(p_process_id varchar2, p_class_id varchar2, p_short_name varchar2);
procedure delete_proc_meth(p_process_id varchar2, p_class_id varchar2 := null, p_short_name varchar2 := null);

/**
 * �������� �������������.
 * �������.
 */
procedure set_debug_pipe(p_pipe_name varchar2);
procedure set_debug_level(p_level pls_integer);

/**
 * �������� �������������.
 * ������������.
 */
procedure log_edoc(p_obj_id number, p_class_id varchar2,
                   p_edt_id varchar2, p_code varchar2, p_text varchar2 := null);

/**
 * ����� ������ ��������� ��������.
 * ���� ������� �� ������ ����� �������, ��� ����
 * ��������� ��������� �������� 0, �� ��������� �����������.
 */
function get_err_msg return varchar2;
--
end;
/
show err

