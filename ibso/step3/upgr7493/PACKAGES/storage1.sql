prompt storage_mgr
create or replace package storage_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/storage1.sql $
 *  $Author: petrushov $
 *  $Revision: 126198 $
 *  $Date:: 2016-10-31 11:06:44 #$
 */

    verbose boolean;
    v8_flag boolean;
    v9_flag boolean;
    v10_flag    boolean;
    Use_Context BOOLEAN;
    Use_Orascn  BOOLEAN;
    Prt_Actual  BOOLEAN;
    pipe_name   varchar2(30);
    max_string  pls_integer;
    max_nstring  pls_integer;

    PART_NONE constant varchar2(1) := '0'; -- �� ��������������
    PART_KEY  constant varchar2(1) := '1'; -- ������������� (PARTITION)
    PART_VIEW constant varchar2(1) := '2'; -- ������������� (PARTVIEW)
    PART_PROF constant varchar2(1) := '3'; -- ��������������� �� �������

    /**
     * Versioning.
     * @return   ������ �������.
     */
    function get_version return varchar2;    
    
    -- ������� ��� ������������ �������
    procedure update_class_storage(p_class_id varchar2,
                                   p_verbose boolean default false,
                                   p_pipe_name varchar2 default 'DEBUG',
                                   p_self_only boolean default false,
                                   p_build     boolean default false,
                                   p_delayed_actions_mode  boolean default false -- ������� ����������� ������ ���������� ��������
                                  );

    procedure update_storage_scheme(p_verbose boolean default false,
                                    p_pipe_name varchar2 default 'DEBUG'
                                   );
    procedure add_dependencies(p_class_id varchar2,p_depend varchar2);
    procedure add_dependent_classes(p_class_id varchar2,
                                    p_include_ref_arr boolean default false);-- �������� ���, � ������� ���� ��������� ����� ������ � ������ � ��������� ������� �����
    procedure create_dependent_classes(p_class  varchar2,
                                       p_pipe   varchar2 default null,
                                       p_compile boolean default true,
                                       p_mode    boolean default false,
                                       p_self    boolean default false,
                                       p_delayed_actions_mode  boolean default false, -- ������� ����������� ������ ���������� ��������
                                       p_include_ref_arr boolean default false -- �������� ���, � ������� ���� ��������� ����� ������ � ������ � ��������� ������� �����
                                       );
    procedure check_user(p_change boolean default false);

    /**
     * ��������� ������������������ �������� ������.
     * <ol>
     *   <li>��������� ����� �� ����� ���� ����������� �����������
     *   <li>���������� ����� �� ����� ���� ����������� ����������
     *   <li>��������� ����� �� ����� ����� �������� (��������������)
     *   <li>���� � ������ ���� �������, �� �� �������
     *     temporary ������ ��������� � ��������� � classes (����������� ����
     *     <code>check_table = true</code>)
     * </ol>
     * @param p_class_id ������������� ������
     * @param check_table ���������� �� ������� temporary � �������� ������ � � �������.
     * @throws message.sys_error(...) ���� �� ��� ��� ������� ���������
     */
    procedure check_class_description(p_class_id varchar2);
    procedure check_temp_description(p_class_id  varchar2, p_parent varchar2, p_part boolean,
                                     p_temp_type varchar2, p_check_table boolean);

    -- �������������� �������
    procedure recompile_object(p_name varchar2, p_type varchar2);

    -- �������������� ��������� �� �������
    procedure recompile_dependent(p_obj_name varchar2, p_obj_type varchar2);
    procedure restore_child_fkeys(p_class_id varchar2);

    -- ������ ������ ��� ���� ��������
    procedure analyze_object(p_obj_name varchar2 default NULL, p_option varchar2 default null, p_owner varchar2 default null);

    -- ������� ����������� ��������� ��� ������
    procedure create_static_object(p_class_id varchar2 default NULL);

    -- ������� ����������� ��������� ��� ������
    procedure delete_static_object(p_class_id varchar2 default NULL);

    -- ������� ������������ ����� (������ � ����������, �����������, ����������, ����������� ��������)
    procedure create_class_interface(p_class_id varchar2, body_only boolean default false);
    procedure create_child_interfaces(p_class_id varchar2);

    -- �������� ��� ������� ������
    procedure create_triggers(p_class_id varchar2);

    -- �������� �������
    procedure reconcile_class_table(p_class_id  varchar2,
                                p_verbose   boolean  default false,
                                p_pipe_name varchar2 default 'DEBUG',
                                p_build     boolean  default true,
                                p_ratio     number   default 1,
                                p_tspace    varchar2 default null,
                                p_init_     number   default null,
                                p_next_     number   default null,
                                p_ini_trans number   default null,
                                p_max_trans number   default null,
                                p_pct_free  number   default null,
                                p_pct_used  number   default null,
                                p_min_exts  number   default null,
                                p_max_exts  number   default null,
                                p_pct_incr  number   default null,
                                p_lists     number   default null,
                                p_groups    number   default null,
                                p_degree    number   default null,
                                p_id        number   default null,
                                p_condition varchar2 default null,
                                p_idxtspace varchar2 default null,
                                p_mode      pls_integer default null);

    -- ��� ������������� ������ ��� ������
    function interface_package(p_class_id varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( interface_package, WNDS, WNPS );

    -- ��� PL/SQL ��� SQL ����, ���������������� ������
    function global_host_type(p_class_id varchar2, p_prec boolean default false, p_sql boolean default false) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES (global_host_type, WNDS, WNPS );

    function make_nt_table_name(p_table varchar2, p_qual varchar2, i pls_integer) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES (make_nt_table_name, WNDS,WNPS);

    procedure create_fk_by_objid(class_id_ varchar2);
    -- No comments
    function  get_storage_parameter( group_ varchar2, name_ varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_storage_parameter, WNDS, WNPS );
    procedure set_storage_parameter( group_ varchar2, name_ varchar2, value_ varchar2);
    procedure get_globals(tab_tablespace out varchar2, idx_tablespace out varchar2,
                          tmp_tablespace out varchar2, dbblock out integer);
    procedure set_storage_group( class_ varchar2 default null, group_ varchar2 default null);
    procedure set_lob_storage_group( class_ varchar2 default null, group_ varchar2 default null);

    /**
     * ��������� SQL-�������. <br>
     * ���������� �������� ���������� <a href="storage_utils.html#verbose">verbose</a> �
     * <a href="storage_utils.html#pipe_name">pipe_name</a> ������
     * <a href="storage_utils.html">storage_utils</a> ������� ���������
     * ��������������� ����� ���������� �, ����� �����, ��������
     * <a href="storage_utils.html#execute_sql(varchar2,varchar2,boolean)">storage_utils.execute_sql</a>
     */
    procedure execute_sql ( p_sql_block clob, comment varchar2 default null, silent boolean default false );
    -- Output to pipe
    procedure WS(msg_str varchar2);

    -- No comments
    function  qual2elem(qual varchar2, varname varchar2 default null) return varchar2;
    -- No comments
    function  mapped(class_id_ varchar2, qual_ varchar2, table_ varchar2 default null) return boolean;
    function  has_column(table_name_ varchar2, column_name_  varchar2) return boolean;

    -- ��������/�������� �������� ������� �������
    procedure create_map_trigger(p_class_id varchar2);

    procedure uncoord(act_ varchar2 default 'SHOW',p_verbose boolean,p_pipe_name varchar2 default 'DEBUG');
    procedure map_column_data(src varchar2, dst varchar2, col varchar2);

    -- ���������� ������������� ������� � ��������������� ����������� �������� � ������������
    procedure map_column_data_cons_indexes(src_class_id varchar2, dst_table_owner varchar2, dst_table_name varchar2, column_name varchar2);

    -- �������� ����������� ������������/��������
    procedure create_indexes(p_class_id varchar2,p_retry pls_integer default null, p_position pls_integer default null);

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
    procedure create_constraints(p_class_id varchar2, p_refs boolean default false,p_position pls_integer default null,p_force pls_integer default 0,
                                 p_delayed_actions_mode  boolean default false -- ������� ����������� ������ ���������� ��������
                                 );
    procedure drop_indexes(p_class_id varchar2,p_unused_only boolean default true, p_position pls_integer default null);

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
    procedure drop_constraints(p_class_id varchar2,p_unused_only boolean default true,p_position pls_integer default null);
    procedure restore_constraints(p_class_id varchar2, p_init boolean default true, p_part boolean default null,
                                  p_delayed_actions_mode  boolean default false -- ������� ����������� ������ ���������� ��������
                                 );
--  �������� ������������
    procedure create_comments( p_class varchar2 );

--��� ����� ���������� ��� OBJECTS
    function  view_col2obj_name( p_class_id varchar2, p_part varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( view_col2obj_name, WNDS, WNPS );

    /**
     * ��������� SQL (�� �������), ����� �������� ����� ���� ����� 32k.
     * @param p_sql ������� � ������� SQL, ������� ������ �� ������ ������ �� 256 ��������.
     * @param comment �����, ������� ��������� ����� <a href="storage_utils.html#ws(varchar2)">storage_utils.ws</a>
     *   ����� ����������� �������.
     * @param p_err �������� �� � <a href="storage_utils.html#ws(varchar2)">storage_utils.ws</a> ��������
     *   ���������� ��������� �� ����� ���������� SQL. ���� <code>nvl(p_err, false) = false</code>
     *   ������ ������ �� ���������.
     * @param p_nl ���� <code>p_nl = true</code>, ��, ��� ���������� ����� �������,
     *   ��������� ����� ������ �� ��� ������� ������.
     */
    procedure create_object(p_sql   dbms_sql.varchar2s,
                            comment varchar2 default null,
                            p_err   boolean  default true,
                            p_nl    boolean  default false);
    procedure create_view_col2obj(p_class_id varchar2);
    procedure create_objects_view(p_err boolean default false);
    procedure create_collection_views(p_err boolean default false,p_build boolean default false);

    /**
     * ������� ����� ������� � �������.
     * p_param - ��������� ��� ��������, ���� �� ������, �� ����� 1.
     */
    function  rec_count( p_table varchar2, p_param varchar2 default null ) return integer;

    /**
     * ������� ����� ����������� ������.
     */
    function  obj_count( p_class varchar2 ) return integer;

    /**
     * �������� �� ��� ���������.
     */
    function  is_kernel( p_class varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( is_kernel, WNDS, WNPS );

    -- ��������������� �� ������� ���
    function is_partitioned ( p_class  varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( is_partitioned, WNDS, WNPS );

    /**
     * �������� �� ������� ������ ���������.
     * @param p_class ������������� ������
     * @param p_type ���� ������� ������ ���������, �� ����� ���� �������� ������������ �� ���:
     * <ul>
     *   <li>'D' - transaction-specific
     *   <li>'P' - session-specific
     * </ul>
     * @return '1' ��� ��������� ������� � '0' � ��������� ������.
     */
    function is_temporary (p_class varchar2, p_type out varchar2) return varchar2;
    pragma RESTRICT_REFERENCES ( is_temporary, WNDS, WNPS );

    /**
     * �������� �� ������� ������ ���������.
     * @param p_class ������������� ������
     * @return '1' ��� ��������� ������� � '0' � ��������� ������.
     */
    function is_temporary (p_class varchar2) return varchar2;
    pragma RESTRICT_REFERENCES ( is_temporary, WNDS, WNPS );

    --����� �� ������ �������
    function class_needs_table(p_class_id varchar2, p_refs boolean default null) return boolean;
    function needs_log_table(p_class_id varchar2, p_self boolean default true) return boolean;
    --����� �� ������� ������� ������
    function needs_collection_id(class_id_ varchar2,p_self boolean default true,p_temp boolean default true) return boolean;
    function needs_state_id(class_id_ varchar2,p_self boolean default true) return boolean;
    function needs_class_id(class_id_ varchar2) return boolean;
    --���������� �������� �������
    procedure refresh_columns(p_class varchar2);
    --�������� ����� has_instances
    procedure check_has_instances( p_class varchar2 default null, p_pipe varchar2 default null, p_modify boolean default false );
    --
    procedure alter_tablespace (p_name varchar2, p_option varchar2 default null);

    /**
     * ����������� �������������� ������ �� ����� ��� �������.
     * @param p_table ��� �������
     * @return ������������� ������, ���� <code>null</code> ���� �
     *   <code>class_tab_columns</code> ��� ���� ����������
     */
    function  table2class(p_table varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( table2class, WNDS, WNPS );

    procedure class2table(p_table out nocopy varchar2, p_owner out nocopy varchar2, p_class varchar2, p_arch varchar2);
    pragma RESTRICT_REFERENCES ( class2table, WNDS, WNPS );

    /**
     * ����������� ����� ������� ������.
     * @param p_class ������������� ������
     * @param p_arch  ������� ������ �������� ���������� (��� �������� '1')
     * @return ��� �������, ���� <code>null</code> ���� �
     *   <code>class_tab_columns</code> ��� ���� ����������
     */
    function  class2table(p_class varchar2,p_arch varchar2 default null,p_schema varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class2table, WNDS, WNPS );

    procedure delete_arc_table(p_class varchar2,p_drop boolean default false);
    procedure convert_obj_id(p_class varchar2,p_set_rights boolean default true);

    function check_trigger_events return boolean;
    function check_states(p_class_id class_attributes.class_id%type, p_check_state_exists boolean:=true) return boolean;
    procedure set_changes;

    -- ���������� �������� ��������� �������� REBUILD.STORAGE_TEMPLATE
    function get_rebuild_storage_template(p_group varchar2) return varchar2;

	procedure actualize_transition_methods;
end;
/
sho err
