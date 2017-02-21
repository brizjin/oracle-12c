prompt class_mgr
create or replace package class_mgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/class1.sql $
 *  $Author: kuvardin $
 *  $Revision: 66754 $
 *  $Date:: 2015-02-19 16:32:45 #$
 */
--
    subtype class_ref_t is class_utils.class_ref_t;
    subtype class_cursor_t is class_utils.class_cursor_t;
    subtype id_rec  is class_utils.id_rec;
    subtype id_tab  is class_utils.id_tab;
    subtype ref_tab is class_utils.ref_tab;
    subtype attrs_rec_t is class_utils.attrs_rec_t;
    subtype attrs_cursor_t is class_utils.attrs_cursor_t;
--
    -- Constants for dict_changes
    DCOT_CLASSES                constant varchar2(30) := 'CLASSES';
      DCCT_CLASSES              constant varchar2(30) := 'CLASSES';
      DCCT_CLASS_TAB_COLUMNS    constant varchar2(30) := 'CLASS_TAB_COLUMNS';
    DCOT_CLASS_ATTRIBUTES       constant varchar2(30) := 'CLASS_ATTRIBUTES';
    DCOT_STATES                 constant varchar2(30) := 'STATES';
    DCOT_TRANSITIONS            constant varchar2(30) := 'TRANSITIONS';
    DCOT_INDEXES                constant varchar2(30) := 'INDEXES';
    DCOT_CONSTRAINTS            constant varchar2(30) := 'CONSTRAINTS';
    DCOT_TRIGGERS               constant varchar2(30) := 'TRIGGERS';
    DCOT_CRITERIA               constant varchar2(30) := 'CRITERIA';
      DCCT_CRITERIA             constant varchar2(30) := 'CRITERIA';
      DCCT_CRITERIA_COLUMNS     constant varchar2(30) := 'CRITERIA_COLUMNS';
      DCCT_CRITERIA_PRINTS      constant varchar2(30) := 'CRITERIA_PRINTS';
      DCCT_CRITERIA_METHODS     constant varchar2(30) := 'CRITERIA_METHODS';
    DCOT_METHODS                constant varchar2(30) := 'METHODS';
      DCCT_CONTROLS             constant varchar2(30) := 'CONTROLS';
      DCCT_METHOD_PARAMETERS    constant varchar2(30) := 'METHOD_PARAMETERS';
      DCCT_METHODS              constant varchar2(30) := 'METHODS';
      DCCT_METHOD_VARIABLES     constant varchar2(30) := 'METHOD_VARIABLES';
      DCCT_SOURCES              constant varchar2(30) := 'SOURCES';
    DCOT_PROFILES               constant varchar2(30) := 'PROFILES';
    DCOT_SETTINGS               constant varchar2(30) := 'SETTINGS';
      DCCT_SETTINGS             constant varchar2(30) := 'SETTINGS';
    DCOT_GUIDE_GROUPS           constant varchar2(30) := 'GUIDE_GROUPS';
      DCCT_GUIDE_GROUPS         constant varchar2(30) := 'GUIDE_GROUPS';
    DCOT_TOPICS                 constant varchar2(30) := 'TOPICS';
      DCCT_TOPIC_DESCRIPTION    constant varchar2(30) := 'DESCRIPTION';
    DCOT_LRAW                   constant varchar2(30) := 'LRAW';
      DCCT_LRAW                 constant varchar2(30) := 'LRAW';
    DCOT_PROCEDURES             constant varchar2(30) := 'PROCEDURES';
      DCCT_PROCEDURES           constant varchar2(30) := 'PROCEDURES';
    DCOT_REPORTVIEWS            constant varchar2(30) := 'REPORTVIEWS';
      DCCT_REPORTVIEWS          constant varchar2(30) := 'REPORTVIEWS';
--
    compile_errors exception;
    pragma exception_init(compile_errors,-24344);
    mutating_error exception;
    pragma exception_init(mutating_error,-4091);
--
    -- creates interface for class
    procedure create_class_interface ( p_class_id varchar2, body_only boolean default false );
    -- creates interface for class and returns errors for class interface packages/bodies
    function  build_interface  ( p_class_id varchar2 ) return varchar2;
    function  build_class_definition ( p_class_id varchar2 ) return varchar2;
    function  build_otypes(p_class_id varchar2) return boolean;
    procedure create_child_interfaces( p_class_id varchar2 );
    procedure check_user(p_change boolean default false);
    -- returns cursor with attributes of class
    procedure get_class_cursor(attrs in out nocopy attrs_cursor_t, p_class_id varchar2);
--
    function replace_invalid_symbols(p_name varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( replace_invalid_symbols, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_valid_literal(p_name varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_valid_literal, WNDS, WNPS, RNDS, RNPS, TRUST );
    function  interface_package( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( interface_package, WNDS, WNPS, RNDS, RNPS, TRUST );
    function  make_class_name  ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_class_name, WNDS, WNPS, RNDS, RNPS, TRUST );
    function  make_table_name  ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_table_name, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_arc_table_name(p_class_id in varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_arc_table_name, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_class_rowname( p_class_id in varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_class_rowname, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_table_rowname( p_class_id in varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_table_rowname, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_record_tables( p_class_id in varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_record_tables, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_plsql_table_name  ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_plsql_table_name, WNDS, WNPS, RNDS, RNPS, TRUST );
    function qual2elem(qual varchar2, varname varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( qual2elem, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_column_name(qual varchar2, i pls_integer) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_column_name, WNDS, WNPS, RNDS, RNPS, TRUST );
    function make_type_description(p_class_id varchar2,p_prec boolean,p_sql boolean,
                                   base_ varchar2,kern_ varchar2,targ_ varchar2,siz_ pls_integer,prec_ pls_integer, targ_kern_ varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_type_description, WNDS, WNPS );
    function make_otype_name(p_class_id varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_otype_name, WNDS, WNPS );
    function make_otype_table(p_class_id varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_otype_table, WNDS, WNPS );
    function needs_oracle_type(p_class_id varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( needs_oracle_type, WNDS, WNPS );
    function type_exists(p_type varchar2,p_owner varchar2 default NULL) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( type_exists, WNDS, WNPS );
    function count_children(p_class varchar2,p_table varchar2 default null) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( count_children, WNDS, WNPS );
    -- returns errors for package/body from user_errors
    function  package_errors ( p_package IN varchar2,
                               p_title   IN boolean  default TRUE,
                               p_owner   IN varchar2 default NULL
                             ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( package_errors, WNDS, WNPS );
    -- returns errors for class interface packages/bodies
    function  class_errors ( p_class_id IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_errors, WNDS, WNPS );
--
    procedure base2sql(base_type varchar2, sql_type out varchar2, data_size out varchar2, suffix out varchar2,
                       p_class   varchar2, p_target varchar2, p_sql boolean, p_kernel varchar2);
--
    -- returns hash value for class id between 1 and 1073741824
    function  hash_id(p_id varchar2) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( hash_id, WNDS, WNPS );
    -- sorting routine (returns scan level), tables must be filled properly
    function  sort_scan(ctab   in out nocopy id_tab, rtab in out nocopy ref_tab,
                        p_pipe in boolean default false) return pls_integer;
    -- clears internal list of classes to be compiled
    procedure clear_class_list;
    -- adds classes to the internal list from string list p_list with separator p_char(default chr(10))
    procedure add_class_list ( p_list  in varchar2,
                               p_clear in boolean  default true,
                               p_char  in varchar2 default null );
    -- adds classes to the internal list from cursor
    procedure add_class_cursor(p_cursor  in out nocopy class_cursor_t,
                               p_clear   in boolean  default true);
    -- processes classes from the internal list
    procedure process_classes( p_pipe    in varchar2 default null, -- pipe name for information output
                               p_compile in boolean  default false,-- update_class_storage(true),create_class_interface(false),only sort (null)
                               p_sort    in boolean  default true, -- flag for call of sorting routine (sort_scan)
                               p_mode    in boolean  default false ); -- flag for update_class_storage.p_build/create_class_interface.body_only
    -- processes classes from the given cursor
    procedure compile_classes( p_cursor  in out nocopy class_cursor_t,
                               p_pipe    in varchar2 default null,
                               p_compile in boolean  default false,
                               p_sort    in boolean  default true,
                               p_mode    in boolean  default false );
    -- extracts id's from id_table (p_idx is start number for output, returns index>0 if only part of list returned)
    function  get_id_list(p_idx  in out nocopy pls_integer,
                          p_tbl  in id_tab) return varchar2;
    -- extracts classes id's from internal table (after process_classes with p_compile=null)
    function  get_class_list(p_idx    in out nocopy pls_integer,
                             p_clear  in boolean default true) return varchar2;
--
    /**
     * ��������� ����� �� ����� ������ <= 256 � �������� �� � PL\SQL �������.
     * @param p_text �����
     * @param p_buf PL/SQL �������, ���� ���������� �������� �����.
     * @param p_end ���� <code>true</code>, ��������� �������� ����� �
     *   ����� �������, � ��������� ������ - � ������.
     */
    procedure put_text_buf ( p_text varchar2,
                             p_buf  in out nocopy dbms_sql.varchar2s,
                             p_end  boolean default true );
--
    procedure skip_changes(p_obj_type varchar2, p_change_type varchar2);
    function  attr_vals_field_name(p_base varchar2,p_value varchar2, p_self in varchar2, p_krn in varchar2, p_target in varchar2, p_resolve_ref in boolean default false, p_resolve_bool in boolean default false) return varchar2;
    procedure check_changes_access(aobj_type in varchar2, aobj_id in varchar2, achange_type in varchar2, acheck boolean := true);
    procedure check_obj_access(aobj_type in varchar2, aobj_class_id in varchar2, aobj_sname in varchar2,achange_type in varchar2, acheck boolean := true);
    procedure write_changes(aobj_type in varchar2, aobj_id in varchar2, achange_type in varchar2, adeleting in boolean := false);
    procedure insert_changes(aobj_type in varchar2, aobj_id in varchar2, achange_type in varchar2,
                             aobj_type2 in varchar2, aobj_id2 in varchar2, achange_type2 in varchar2);
    procedure update_changes(aobj_type in varchar2, aobj_id in varchar2, achange_type in varchar2,
                             aobj_type2 in varchar2, aobj_id2 in varchar2, achange_type2 in varchar2);
    function check_states(p_class_id class_attributes.class_id%type, p_check_state_exists boolean:=true) return boolean;
--
    function ne(v1 in varchar2, v2 in varchar2) return boolean deterministic;
    pragma RESTRICT_REFERENCES ( ne, WNDS, WNPS, RNDS, RNPS, TRUST );
--
    function ne(v1 in number, v2 in number) return boolean deterministic;
    pragma RESTRICT_REFERENCES ( ne, WNDS, WNPS, RNDS, RNPS, TRUST );
--
    function ne(v1 in date, v2 in date) return boolean deterministic;
    pragma RESTRICT_REFERENCES ( ne, WNDS, WNPS, RNDS, RNPS, TRUST );
--
    procedure check_grant(p_name varchar2,p_owner varchar2,p_check boolean);
-- creates interface for class (internal usage only)
    procedure create$interface(
                  cs  class_utils.CLASS_DEFINITION,
                  col class_utils.COLUMN_INFO_TABLE,
                  struct class_utils.STRUCT_INFO_TABLE,
                  stypes class_utils.TYPES_TABLE,
                  btypes class_utils.TYPES_TABLE,
                  fields class_utils.FIELDS_INFO,
                  owners class_utils.OWNERS_TABLE,
                  body_only boolean);
--
end;
/
show err

