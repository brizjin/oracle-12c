prompt class_utils
create or replace package class_utils as
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/cls_ut1.sql $
 *	$Author: vzhukov $
 *	$Revision: 94127 $
 *	$Date:: 2016-02-15 16:47:04 #$
 */
--
/*******************************************
 * Information about class columns
 * (for Add_Columns universal procedure)
 */
--
TYPE ATTRS_REC_T IS RECORD (
  position number,
  attr_id  varchar2(16),
  class_id varchar2(16),
  required varchar2(1),
  self_class_id varchar2(16),
  sequenced     varchar2(30),
  name     varchar2(128),
  distance number);
--
TYPE ATTRS_CURSOR_T IS REF CURSOR RETURN ATTRS_REC_T;
--
TYPE COLUMN_DEFINITION IS RECORD (
    qual   varchar2(700), -- Квалификатор колонки
    name   varchar2(30), -- Имя колонки
    owner  varchar2(16), -- Класс-владелец колонки
    base   varchar2(16), -- Базовый тип
    self   varchar2(16), -- Свой тип
    target varchar2(16), -- Target class id
    sqltyp varchar2(60), -- SqlType
    seq    varchar2(30), -- Sequenced
    flags  varchar2(30), -- Column flags (Primary,Functional)
    len    pls_integer,
    prec   pls_integer,
    logging     pls_integer,  -- Признак журналирования --
    mapped      pls_integer,  -- Мапируется ли колонка
    mapped_from varchar2(16), -- Класс, из которого мапируется колонка
    static      varchar2(1),  -- Имеет ли статические значени
    checked     varchar2(1),  -- Модификация в связке с триггером
    kernel      varchar2(1),
    indexed     varchar2(1),  -- Ограничения целостности
    deleted     varchar2(1),  -- Удаленная колонка
    table_name  varchar2(30),
	prev_base   varchar2(16) , -- Базовый тип до модификации
	prev_self   varchar2(16) , -- Собственный тип реквизита до модификации
    prev_target varchar2(16),  -- Target class id  до модификации
    targ_kernel varchar2(1),   -- Cсылаемый тип - системный
    targ_temp   varchar2(1),   -- Cсылаемый тип - временный
    not_cached  varchar2(1),   -- Признак отключения кэширования колонки
	nullable    varchar2(1),   -- Флаг сброса значений колонок в reconcile_class_table
	prev_kernel varchar2(1),   -- Флаг kernel до модификации (для дат)
	not_null    varchar2(1),   -- Флаг ограничения целостности [null|not null]
	func_id     varchar2(16),
    func_class  varchar2(16),
    qual_name   varchar2(4000), -- Полное имя реквизита-колонки (для комментария)
    distance    pls_integer,
    has_num     pls_integer,
	hard_coll	boolean
);
--
TYPE STRUCT_INFO IS RECORD (
	owner varchar2(16) ,   -- Класс-владелец колонки
    qual  varchar2(700),   -- Квалификатор колонки
    class varchar2(16) ,   -- Класс структуры
    pref  varchar2(31)     -- Owner class interface prefix
);
--
TYPE TYPE_INFO IS RECORD (
    class varchar2(16),   -- Класс
    stype varchar2(60),   -- SQL type
    prec  varchar2(16),   -- Precision
    suff  varchar2(20)    -- Suffix in procedure call
);
--
type OWNER_INFO is record (
    owner varchar2(16),   -- Класс
    tname varchar2(30),   -- table name
    town  varchar2(30),   -- table name owner
    tkey  varchar2(10),   -- key var definition
    tprt  boolean,   -- флаг архивации. Не партификация по профилям
    class boolean,   -- class_id column
    state boolean,   -- state_id column
    coll  boolean,   -- collection_id column
    scn   boolean    -- scn column
);
--
TYPE COLUMN_INFO_TABLE IS TABLE OF COLUMN_DEFINITION INDEX BY BINARY_INTEGER;
TYPE STRUCT_INFO_TABLE IS TABLE OF STRUCT_INFO INDEX BY BINARY_INTEGER;
TYPE TYPES_TABLE  IS TABLE OF TYPE_INFO  INDEX BY BINARY_INTEGER;
TYPE OWNERS_TABLE IS TABLE OF OWNER_INFO INDEX BY BINARY_INTEGER;
--
TYPE FIELDS_INFO IS RECORD (
    pos   "CONSTANT".integer_table,
    qual  "CONSTANT".varchar2_table,
    name  rtl.string40_table,
    self  rtl.string40_table,
    base  rtl.string40_table,
    targ  rtl.string40_table,
    flags rtl.string40_table);
--
TYPE CLASS_DEFINITION IS RECORD (
    cnt       pls_integer,    -- Счетчик всех элементов
    self      pls_integer,    -- Счетчик своих элементов
    struct    pls_integer,    -- Счетчик всех структур
    stypes    pls_integer,    -- Счетчик типов структур
    btypes    pls_integer,    -- Счетчик базовых типов
    coll_dst  pls_integer,
    state_dst pls_integer,
    class_dst pls_integer,
    id_dst    pls_integer,
    cached    pls_integer,
    key_idx   pls_integer,
    part_key  pls_integer,
    insert_dist pls_integer,
    len       pls_integer,
    prec      pls_integer,
    --
    class_id  varchar2(16),
    parent    varchar2(16),
    target    varchar2(16),
    base_type varchar2(16),
    entity    varchar2(16),
    state     varchar2(16),
    name      varchar2(128),
    key_attr  varchar2(16),
    key_field varchar2(30),
    host_type varchar2(61),
    len_spec  varchar2(40),
    instances varchar2(1),
    temp_type varchar2(1),
    iface     varchar2(31),
    trig      varchar2(61),
    trig_event  varchar2(3),
    pass_state  varchar2(2),
    s_type_tbl  varchar2(30),
    s_tbl       varchar2(30),
    s_ref       varchar2(10),
    s_prec      varchar2(10),
    table_name  varchar2(40),
    log_table   varchar2(30),
    table_owner varchar2(30),
    log_owner   varchar2(30),
    parent_iface    varchar2(31),
    storage_group   varchar2(30),
    lob_storage     varchar2(30),
    old_flags       varchar2(30),
    tbl_flags       varchar2(30),
    old_has_type    varchar2(1),
    old_key_attr    varchar2(16),
    old_iface       varchar2(64),
    class_rowname   varchar2(30),
    table_rowname   varchar2(30),
    record_tables   varchar2(30),
    plsql_table     varchar2(30),
    kernel      boolean,
    is_struct   boolean,
    has_type	boolean,
    no_table	boolean,
    notable	    boolean,
    is_temp	    boolean,
    has_check		boolean,
    has_self_ole	boolean,
    has_collect		boolean,
    has_self_colls	boolean,
    has_self_state	boolean,
    has_self_seq	boolean,
    has_rights		boolean,
    has_ref_rights	boolean,
    notobj			boolean,
    has_insert		boolean,
    has_update		boolean,
    has_delete		boolean,
    has_ins_all		boolean,
    has_del_all		boolean,
    has_parent		boolean,
    has_no_childs	boolean,
    has_logging		boolean,
    has_archiving   boolean,
    has_static		boolean,
    has_partitions	  boolean,  -- Есть ли партиции
    has_part_view	    boolean,  -- Архивирование
    has_part_profile	boolean,  -- Партификация по профилю
    has_plsql_table boolean,
    has_obj_cache   boolean,
    has_cache       boolean,
    has_instances   boolean,
    has_func_attr   boolean,
    static_cached	boolean,
    object_cached   boolean,
    parents_cached  boolean,
    put_colls_logging     boolean,
    has_colls_logging     boolean,
    has_state_logging     boolean,
    has_self_static       boolean,
    has_delete_stmt       boolean,
    has_row_id	    boolean  -- идентификация по ROWID
    ,col_id          varchar2(10)    -- колонка, по которой выполняется идентификация записи в таблице /*ROWID в ТЯ1*/
  );
-- Список реквизитов типа
procedure get_class_cursor(attrs in out nocopy attrs_cursor_t, p_class_id varchar2);
-- Информация о типе
procedure get_class_info(p_class_id varchar2,cs in out nocopy CLASS_DEFINITION);
-- Информация о колонке типа
function get_column_info(p_class_id varchar2,p_qual varchar2,col in out nocopy COLUMN_DEFINITION) return boolean;
-- Информация о колонках типа
procedure add_columns(p_class_id varchar2,
                      cs  in out nocopy CLASS_DEFINITION,
                      col in out nocopy COLUMN_INFO_TABLE,
                      struct in out nocopy STRUCT_INFO_TABLE,
                      stypes in out nocopy TYPES_TABLE,
                      btypes in out nocopy TYPES_TABLE,
                      fields in out nocopy FIELDS_INFO,
                      owners in out nocopy OWNERS_TABLE,
                      p_chk_table boolean default null);
procedure update_object_columns(p_col varchar2, p_add boolean,
             cs  in out nocopy CLASS_DEFINITION,
             col in out nocopy COLUMN_INFO_TABLE,
             owners in out nocopy OWNERS_TABLE);
function mapped(p_table  out nocopy varchar2,
                p_column out nocopy varchar2,
                p_owner  out nocopy varchar2,
                p_class_id   varchar2, p_qual varchar2) return pls_integer;
function check_type(col in out nocopy COLUMN_DEFINITION,
                    new_type  in out nocopy varchar2,
                    col_type  varchar2,
                    col_len   pls_integer,
                    col_prec  pls_integer,
                    col_scale pls_integer,
                    p_target  varchar2, p_num boolean, p_chk_targ boolean
                    ) return boolean;
/*******************************************
 * hard_coded pass_state
 */
procedure build_pass_state(p_class_id varchar2,p_flags varchar2,t in out nocopy dbms_sql.varchar2s);
--
/*******************************************
 * operations with internal list of classes
 */
--
type class_ref_t is record (
        id          varchar2(16),
        name        varchar2(128),
        base        varchar2(16),
        target      varchar2(16),
        parent      varchar2(16)
                            );
type class_cursor_t is ref cursor return class_ref_t;
--
type id_rec is record (
        id          varchar2(16),
        name        varchar2(128),
        clevel      pls_integer,
        refs        pls_integer
                      );
type id_tab  is table of id_rec index by binary_integer;
type ref_tab is table of varchar2(10000) index by binary_integer;

type ref_tab_ex is table of constant.REFSTRING_TABLE index by binary_integer;

--
-- clears internal list of classes to be compiled
procedure clear_class_list;
-- sorting routines (return scan level), tables must be filled properly
function  sort_scan(ctab   in out nocopy id_tab, rtab in out nocopy ref_tab,
                    p_pipe in boolean default false) return pls_integer;
function  sort_scan_ex(ctab   in out nocopy id_tab, rtab in out nocopy ref_tab_ex,
                    p_pipe in boolean default false) return pls_integer;
-- adds class to the internal list, returns index in the internal list if added
function  add_class_id(p_id varchar2) return pls_integer;
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
                           p_mode    in boolean  default false,-- flag for update_class_storage.p_build/create_class_interface.body_only
                           p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                            ); 
-- processes classes from the given cursor
procedure compile_classes( p_cursor  in out nocopy class_cursor_t,
                           p_pipe    in varchar2 default null,
                           p_compile in boolean  default false,
                           p_sort    in boolean  default true,
                           p_mode    in boolean  default false );
-- extracts id's from id table (p_idx is start number for output, returns index>0 if only part of list returned)
function  get_id_list(p_idx  in out nocopy pls_integer,
                      p_tbl  in id_tab) return varchar2;
-- extracts classes id's from internal table (after process_classes with p_compile=null)
function  get_class_list(p_idx    in out nocopy pls_integer,
                         p_clear  in boolean default true) return varchar2;
-- rearranges id table by level
procedure arrange_id_list(p_tbl in out nocopy id_tab, p_max_level pls_integer default null);
-- extracts internal buffer
procedure get_class_buf(p_tbl  in out nocopy id_tab);
--
/*******************************************
 * deleting self collections triggers
 */
function  check_hard_coll(achk_class varchar2, achk_target varchar2) return boolean;
--
/*******************************************
 * utilities
 */
function parse_plplus(P_TEXT varchar2, P_ERR in out nocopy varchar2,
    P_PLSQL in out nocopy varchar2, p_section varchar2 := 'PUBLIC') return varchar2;
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
procedure base2sql(base_type varchar2,
                   sql_type  out nocopy varchar2,
                   data_size out nocopy varchar2,
                   suffix    out nocopy varchar2,
                   p_class   varchar2, p_target varchar2,
                   p_sql boolean, p_kernel varchar2);
procedure  get_props( self_class in varchar2,
                      base_id    in varchar2,
                      target_id  in varchar2,
                      kernel     in boolean,
                      func       in out nocopy varchar2,
                      prefix     in out nocopy varchar2,
                      suffix     in out nocopy varchar2);
function attr_vals_field_name(p_base varchar2, p_value varchar2,
                              p_self in varchar2, p_krn in varchar2, p_target in varchar2,
                              p_resolve_ref  in boolean default false,
                              p_resolve_bool in boolean default false) return varchar2;
--
function  log_trigger_name(p_table varchar2) return varchar2 deterministic;
pragma RESTRICT_REFERENCES ( log_trigger_name, WNDS, WNPS, RNDS, RNPS );
function  arc_trigger_name(p_table varchar2) return varchar2 deterministic;
pragma RESTRICT_REFERENCES ( arc_trigger_name, WNDS, WNPS, RNDS, RNPS );
procedure drop_arc_trigger( p_class_id varchar2, p_table varchar2 default null );
procedure create_arc_trigger(cs CLASS_DEFINITION,col COLUMN_INFO_TABLE);
--
end;
/
show err
