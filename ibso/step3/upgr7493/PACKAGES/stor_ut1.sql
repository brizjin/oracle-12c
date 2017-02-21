prompt storage_utils
create or replace package storage_utils as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/stor_ut1.sql $
 *  $Author: vzhukov $
 *  $Revision: 124343 $
 *  $Date:: 2016-10-13 16:57:33 #$
 */
--
    verbose boolean := false;
    pipe_name varchar2(30) := 'DEBUG';
--
    --�����/�������� ������ � �� - ��������� ���������, ����� �� ����������, OLE-�������
    procedure lost_collections(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG',p_target varchar2 default null);
    procedure lost_rights(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG');
    procedure lost_oles(act_ varchar2 default 'SHOW',p_verbose boolean default true,p_pipe_name varchar2 default 'DEBUG');

    -- ���������� ����������� ���������� �������
    function  optimal_param (p_size number, p_initial varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(optimal_param,wnds,wnps);

    procedure optimal_params(p_size number, sp_init out varchar2 , sp_next out varchar2);
    pragma restrict_references(optimal_params,wnds,wnps);

    procedure get_optimal_param(seg_name in varchar2, sp_init out varchar2 , sp_next out varchar2, p_owner varchar2 default null);
    pragma restrict_references(get_optimal_param,wnds,wnps);

    function  optimal_group (p_size number,p_param varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(optimal_group,wnds,wnps);
    
    function build_ref_constraint_name(p_table_name varchar2, p_postfix varchar2) return varchar2 deterministic;
    pragma restrict_references(build_ref_constraint_name,wnds,wnps);
    
    function build_parallel return pls_integer deterministic;
    pragma restrict_references(build_parallel,wnds,wnps);

    function build_nologging return varchar2 deterministic;
    pragma restrict_references(build_nologging,wnds,wnps);

    function direct_insert_hint return varchar2 deterministic;
    pragma restrict_references(direct_insert_hint,wnds,wnps);

    function build_online return varchar2 deterministic;
    pragma restrict_references(build_online,wnds,wnps);

    function build_novalidate return varchar2;
    pragma restrict_references(build_novalidate,wnds,wnps);

    function build_deferrable return varchar2;
    pragma restrict_references(build_deferrable,wnds,wnps);

    -- PLATFORM-3493 �������� ����������� ����������� ������ � ��������� ��� ������������ �������
    function build_constr_with_index return boolean;
    pragma restrict_references(build_constr_with_index,wnds,wnps);

    function  get_sql_type(p_type varchar2,p_size pls_integer,p_prec pls_integer,p_scale pls_integer) return varchar2 deterministic;
    pragma restrict_references(get_sql_type,wnds,wnps,rnds,rnps);

    function  get_column_type(p_table varchar2,p_column varchar2,p_prec varchar2,p_owner varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_column_type,wnds,wnps);

    function  get_column_props(p_table varchar2,p_column varchar2,
              col_type  in out nocopy varchar2,
              col_len   in out nocopy pls_integer,
              col_prec  in out nocopy pls_integer,
              col_scale in out nocopy pls_integer,
              col_not_null in out nocopy varchar2,
              p_owner   varchar2 default null ) return boolean;
    pragma restrict_references(get_column_props,wnds,wnps);

    function  get_object_schema(p_object varchar2, p_type varchar2, p_all varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_object_schema,wnds,wnps);

    function  get_project_owner(p_object varchar2, p_type varchar2) return varchar2 deterministic;
    pragma restrict_references(get_project_owner,wnds,wnps);

    procedure analyze_object(p_obj_name varchar2, p_subobject varchar2 default null,
                             p_option   varchar2 default null,
                             p_cascade  boolean  default null,
                             p_degree   pls_integer default null,
                             p_owner    varchar2 default null);

    --  �������� ��������� ��������
    procedure create_indexes(p_class_id varchar2,p_retry pls_integer, p_position pls_integer);

    /**
     * ������� ��������� ����������� ����������� ��� �������, ��������(partview) � ������ (partition) ������.
     * @param p_class_id ������������� ������, ��� �������� ����� ������� �����������
     * @param p_refs ???
     * @param p_position ���� ������� ������ ����������������, �� ��� ����� �������,
     * ��� �������� ����� ������� �����������(� ������ partview) ��� ��� ������� ��������
     * ����� ������� �����������(� ������ partition). ������:
     * <ul>
     *   <li>���� <code>p_position is null</code>, �� ��������� ������ ��� �������� �������
     *   <li>���� <code>p_position = 0</code>, �� ��������� ��� �������� ������� ���� ���
     *     ���� ��������(������)
     *   <li>���� <code>p_position > 0</code>, �� ��������� ��� �������� ������� ���� ���
     *     �������(������� �������) � ������� <code>p_position</code>
     * </ul>
     * @param p_force ����� �������� ��������� ����������� ����������� (0 - �� ���������, 1- ��������� �������� DEFERRABLE)
     */
    procedure create_constraints(p_class_id varchar2, p_refs boolean, p_position pls_integer, p_force pls_integer,
                                 p_delayed_actions_mode  boolean default false -- ������� ����������� ������ ���������� ��������
                                );
    --  �������� ��������� ��������
    procedure drop_indexes(p_class_id varchar2,p_unused_only boolean, p_position pls_integer);

    /**
     * ������� ��������� ����������� ����������� ��� �������, ��������(partview) � ������ (partition) ������.
     * @param p_class_id �������� �������� <a
     *   href="#create_constraints(varchar2,boolean,pls_integer)">create_constraints</a>
     * @param p_unused_only ���� ������, �� ������� ������ �����������,
     *   ������� ������� ������� ��� �������� ��� ���������, � ����� ����������� ��
     *   �������-��������� � �������-������, ��� ������� ���� ������� �� ��������� �����������.
     * @param p_position �������� �������� <a
     *   href="#create_constraints(varchar2,boolean,pls_integer)">create_constraints</a>
     */
    procedure drop_constraints(p_class_id varchar2,p_unused_only boolean,p_position pls_integer);
    -- �������� ��� ������� ������
    procedure create_triggers (p_class_id varchar2, p_refs boolean default false);
    procedure create_refced_triggers (p_class_id varchar2, p_ref_part boolean default false, p_refs boolean default false);
    procedure create_refcing_triggers(p_class_id varchar2, p_ref_part boolean default false, p_refs boolean default false);
    procedure create_unique_trigger  (p_class_id varchar2);
    procedure drop_triggers(p_class_id varchar2,p_type varchar2 default null);
    -- ��������� ��� ���������� ��������� �� ������� ��� ���� �� �������� �����������
    procedure update_refced_triggers(p_class_id varchar2);

    /**
     * �������������� ���� ������� �������.
     * @param base1 ������� ��� ������� ����������
     * @param base2 ������� ��� ������� ���������
     * @param type1 ��� ������� ����������
     * @param type2 ��� ������� ���������
     * @param col ��� ������������� �������
     * @param len ����� �� ������� ���������� ��������������� �������� ����
     *    <code>base1 in ('STRING','MEMO')</code>
     * @param krn1 ������� <code>kernel</code> ���� ������� ����������
     * @param krn2 ������� <code>kernel</code> ���� ������� ���������
     * @return
     * <ul>
     *   <li>���� ������� �� "�����" ��� �������������, �� ���������� <code>null</code>.
     *   <li>���� �������������� ����������, �� ���������� <code>'NULL'</code>.
     *   <li>�� ���� ��������� ������� ���������� SQL-��������� ��� ��������������
     *     ���� ������� ��� ������� �� �������. ��������,
     *     <code>get_conv('STRING', 'DATE', 'VARCHAR2', 'DATE', 'my_col', 10, '0', '0')</code>
     *     ������ <code>'SUBSTR(TO_CHAR(my_col,''YYYY-MM-DD HH24:MI:SS''), 1, 10)'</code>.
     * </ul>
     */
    function  get_conv(base1 varchar2, base2 varchar2, type1 varchar2, type2 varchar2, col varchar2, len number) return varchar2;
    function  conv_ref_table(p_class varchar2,p_column varchar2,
                             p_context boolean default null,p_mirror varchar2 default null) return varchar2;
    function  find_id_column(p_class varchar2,p_attr in out nocopy varchar2,p_owner in out nocopy varchar2,p_column in out nocopy varchar2) return varchar2;

    --procedure rebuild_referencies;
    procedure rebuild_col2obj;
    procedure rebuild_refs;
    procedure rebuild_fkeys;

    -- ������� ������, � ������� ��� ������������ � ������������/�������� ��������
    procedure delete_stuff(p_parent boolean default false,p_class varchar2 default null);
    -- ��������� ������������� ������ � �������
    procedure add_missing_records(p_parent boolean default false,p_class varchar2 default null);

    /**
     * �������������� ������ ���������.
     * ����� ��������� ���������� �� ���� �������� ���� ������ �������.
     * ��� ���� ������� ������ ������������ ���������� �����������
     * �� ����� ������� � ����� �������. ���������� ����� � ������� ��������� ��
     * ������������ ����������� <code>p_table</code> � <code>p_column</code>.
     * ������ ���� ����� <code>p_once</code>, �� ����� ���������� � ����� ������
     * ������������ ����������� <code>p_table</code> � <code>p_column</code>, �,
     * ��� ����, �������������� ������ ������ �������� �������-���������.
     * ���� ����� <code>p_class</code>, �� ������� ����� ������ ������������
     * ������� ������ <code>p_class</code>.
     * @param p_table ��� �������,� ������� �������� ������ ���������.
     *   ���� �� ������, ��������������� ��� ������� �������.
     * @param p_column ��� �������,� �������(�� ��������� �� �������) ��������
     *   ������ ���������. �������� ������ ���� ����� <code>p_table</code>.
     * @param p_class ������������� ������, � ������� �������� ������ ���������
     * @param p_once ���� ������, �� �������������� ������ �������� ���������.
     * @param p_position �������� ��������
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure update_empty_collections (p_table varchar2 default NULL, p_column varchar2 default null,
                                        p_class varchar2 default NULL, p_once   boolean  default false,
                                        p_position pls_integer default null);

    /**
     * �������� �������������� ������.
     * �������� ����, ��� ���������� ����� ������, � ����� ���������� ����������
     * <code>p_table</code>, <code>p_column</code>, <code>p_class</code> �
     * <code>p_once</code> �������� � <a
     * href="#update_empty_collections(varchar2,varchar2,varchar2,boolean,pls_integer)">update_empty_collections</a>
     * @param p_ole ���� ������, �� ������ ������ �� ole-�������
     *   (�.�. �� ������� long_data). � ��������� ������ ������ ������ �� ������.
     * @param p_position �������� ��������
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure update_invalid_references(p_table varchar2 default NULL, p_column varchar2 default null,
                                        p_class varchar2 default NULL, p_once   boolean  default false,
                                        p_ole boolean default false, p_position pls_integer default null);

    /**
     * �������� ������� (��������� ������).
     * @param p_class ������������� ������, ������� �������� ����� ��������/���������
     * @param p_column ��� ����������/����������� �������
     * @param p_value ��������, ������� ����������� �������.
     * @param p_where ������� �� ������ �������, � ������� ���������� �������.
     *   ���� �� ������, �� ������������ � ������������ �� <code>p_value</code>:
     *   <ul>
     *     <li><code>p_value is null</code>: <code>p_where := 'IS NOT NULL'</code> - ������� ����������
     *     <li><code>p_value is not null</code>: <code>p_where := 'IS NULL'</code> - ������� �����������
     *   </ul>
     * @param p_position �������� ��������
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure clear_column (p_class varchar2, p_column varchar2, p_value varchar2 default null,
                            p_where varchar2 default null, p_position pls_integer default null);

    /**
     * �������������� �������� �������
     * @param p_class ������������� ������, ������� �������� ����� �������������
     * @param p_column ��� ������������� �������
     * @param p_updcol ��� �������������� �������
     * @param p_conv ��������� ��� �������������� �������� ������� � ������� ����������
     *   <a href="storage_mgr.html#get_conv(varchar2,varchar2,varchar2,varchar2,varchar2,integer,varchar2,varchar2)">get_conv</a>
     * @param p_position �������� ��������
     *   <a href="#init_class_id(varchar2,boolean,pls_integer)">init_class_id</a>
     */
    procedure move_column (p_class varchar2, p_column varchar2, p_updcol varchar2,
                           p_conv  varchar2, p_position pls_integer default null);

    procedure cons_indexes(p_table varchar2,p_column varchar2,p_drop boolean,p_cascade boolean,p_owner varchar2 default null);
    procedure convert_id_column(p_class varchar2,p_column varchar2,p_col_owner varchar2,p_qual varchar2);
    procedure convert_obj_id(p_class varchar2,p_set_rights boolean default true);

    /**
     * ������������� <code>CLASS_ID</code> � ��������� �������� ������������.
     * @param p_class ������������� ������, ������� �������� ������ ���������
     *   �������� ������������, � ������� ����� �������� <code>CLASS_ID</code>
     * @param p_clear ���� ������, ��, ����� ��������������, � ������� ������
     *   <code>p_class</code> ���������� ������� <code>CLASS_ID</code>
     * @param p_position ���� �� <code>null</code>, ��, ����� �������� �������,
     *   ����� ���������������� partviews � �������(���� ��� ����).
     *   <ul>
     *     <li>���� <code>p_position = 0</code>, �� ���������������� ��� partviews(�������)
     *     <li>���� <code>p_position > 0</code>, �� ���������������� partview(�������)
     *       � ��������� ������� �������.
     *   </ul>
     */
    procedure init_class_id (p_class varchar2, p_clear boolean default false,
                             p_position pls_integer default null);

    procedure clear_diarys;

    /**
     * ������� ��������� � pipe.
     * ������� ������ ���� <code><a href="#verbose">verbose</a> = true</code>.
     * ��� pipe ������������ <a href="#verbose">pipe_name</a>.
     * @param msg_str ���������.
     */
    procedure ws(msg_str varchar2);

    /**
     * ��������� SQL.
     * @param p_sql_block ����� SQL.
     * @param p_comment �����, ������� ��������� ����� <a href="#ws(varchar2)">ws</a>
     *   ����� ����������� �������.
     * @param p_silent �������� �� � <a href="#ws(varchar2)">ws</a> ��������
     *   ���������� ��������� �� ����� ���������� SQL. ���� <code>nvl(silent, false) = false</code>
     *   ������ ������ �� ���������.
     */
    procedure execute_sql( p_sql_block clob, p_comment varchar2 default null,
                           p_silent boolean default false, p_owner varchar2 default null );

    /**
     * ��������� SQL.
     * @param p_sql_block ����� SQL.
     * @param p_comment �����, ������� ��������� ����� <a href="#ws(varchar2)">ws</a>
     *   ����� ����������� �������.
     * @param p_silent �������� �� � <a href="#ws(varchar2)">ws</a> ��������
     *   ���������� ��������� �� ����� ���������� SQL. ���� <code>nvl(silent, false) = false</code>
     *   ������ ������ �� ���������.
     * @return ���������� ���������� �������� �����.
     */
    function  execute_sql( p_sql_block clob, p_comment varchar2 default null,
                           p_silent boolean default false, p_owner varchar2 default null ) return number;

    /**
     * ��������� ����� �� ����� ������ <= 256 � �������� �� � PL\SQL �������.
     * @param p_text �����
     * @param p_buf PL/SQL �������, ���� ���������� �������� �����.
     * @param p_end ���� <code>true</code>, ��������� �������� ����� �
     *   ����� �������, � ��������� ������ - � ������.
     */
    procedure put_text_buf(p_text varchar2,
                           p_buf in out nocopy dbms_sql.varchar2s,
                           p_end boolean := true);
    /**
     * ���������� �����, ������������ � pl\sql ��������.
     * �������� ������ �� ������ �� ������ �� ���������� ���������,
     * �.�. ����� ����� ���� ������ �� ������ ��-�������.
     * @param p_buf1 ������ ������� � �������
     * @param p_buf2 ������ ������� � �������
     */
    function texts_equal(p_buf1 dbms_sql.varchar2s,
                        p_buf2 dbms_sql.varchar2s) return boolean;
    /**
     * ��������� SQL (�� �������), ����� �������� ����� ���� ����� 32k.
     * @param p_sql_block ������� � ������� SQL, ������� ������ �� ������ ������ �� 256 ��������.
     * @param comment �����, ������� ��������� ����� <a href="#ws(varchar2)">ws</a>
     *   ����� ����������� �������.
     * @param p_ins_nl ���� <code>p_ins_nl = true</code>, ��, ��� ���������� ����� �������,
     *   ��������� ����� ������ �� ��� ������� ������.
     * @param silent �������� �� � <a href="#ws(varchar2)">ws</a> ��������
     *   ���������� ��������� �� ����� ���������� SQL. ���� <code>nvl(silent, false) = false</code>
     *   ������ ������ �� ���������.
     */
    procedure execute_sql(p_sql_block dbms_sql.varchar2s, p_ins_nl boolean := false,
                          p_comment varchar2 := null, p_silent boolean := false);

    procedure drop_column(p_table varchar2,p_column varchar2,p_cascade boolean,p_silent boolean);
    function has_table(table_name varchar2) return boolean;

    /**
     * ���������� �������� �������� NULLABLE � ������� �������.
     * @param p_table  ������������ �������
     * @param p_column ������� �������
     * @param p_class  ������������� ������
     * @param p_attr   ������������ ������� ������
     * @param p_nullable �������� �������� NULLABLE ������� �������
     */
    procedure set_column_nullable(p_table varchar2, p_column varchar2, p_class varchar2, p_qual varchar2, p_nullable boolean);

    /**
     * ��������� �������� �������� NULLABLE � ������� �������.
     * @param p_table  ������������ �������
     * @param p_column ������� �������
     * @param p_owner  �������� �������
     */
    function get_column_nullable(p_table varchar2, p_column varchar2, p_owner varchar2 default null) return boolean;

    /**
     * �������������� �����������
     * @param p_table  ������������ �������
     * @param p_constraint_name_old ������ ������������ �����������
     * @param p_constraint_name_new ����� ������������ �����������
     */
    procedure rename_constraint(p_table varchar2, p_constraint_name_old varchar2, p_constraint_name_new varchar2);

end;
/
show err

