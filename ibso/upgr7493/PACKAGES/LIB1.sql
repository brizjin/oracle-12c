prompt lib
create or replace package lib is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/LIB1.sql $
 *  $Author: aavdeev $
 *  $Revision: 89205 $
 *  $Date:: 2015-12-22 17:48:48 #$
 */
--
	type class_info_t is record (
        class_id       varchar2(16),
        name           varchar2(128),
        entity_id      varchar2(16),
        parent_id      varchar2(16),
        base_id        varchar2(16),
        base_class_id  varchar2(16),
        class_ref      varchar2(16),
        key_attr       varchar2(16),
        method_id      varchar2(16),
        state_id       varchar2(16),
        has_instances  varchar2(1),
        flags          varchar2(30),
        interface      varchar2(64),
        data_size      pls_integer,
        data_precision pls_integer,
        hash_value     pls_integer,
		kernel         boolean,
		has_type       boolean,
		is_array       boolean,
		has_row_id     boolean,
		temp_type      varchar2(1)
	);
	type class_info_tbl_t is table of class_info_t index by binary_integer;
    type class_info_tbl_s is table of class_info_t index by varchar2(30);
--
	type table_info_t is record (
        class_id       varchar2(16),
        table_name     varchar2(30),
        param_group    varchar2(30),
        flags          varchar2(30),
        log_table      varchar2(30),
        table_owner    varchar2(30),
        log_owner      varchar2(30),
        cached         pls_integer,
        distance       pls_integer
	);
	type table_info_tbl_t is table of table_info_t index by binary_integer;
    type table_info_tbl_s is table of table_info_t index by varchar2(30);
--
	type attr_info_t is record (
        class_id       varchar2(16),
        attr_id        varchar2(16),
        self_class_id  varchar2(16),
        name           varchar2(128),
        method_id      varchar2(16),
        flags          varchar2(1),
        position       pls_integer,
        distance       pls_integer
	);
	type attr_info_tbl_t is table of attr_info_t index by binary_integer;
--
	type method_info_t is record (
        id         varchar2(16),
        name       varchar2(128),
        sname      varchar2(16),
        ext_id     varchar2(16),
        class_id   varchar2(16),
        base_id    varchar2(16),
        flags      varchar2(30),
        result_id  varchar2(16),
        interface  varchar2(64),
		is_array   boolean,					 -- result is collection
        class_ref  varchar2(16),             -- result is class ref
        package    varchar2(30),
        features   pls_integer
	);
	type method_info_tbl_t is table of method_info_t index by binary_integer;
	type method_info_tbl_s is table of method_info_t index by varchar2(30);
--
	type column_info_t is record (
        class_id       varchar2(16),
        tbl_name       varchar2(30),
        col_name       varchar2(30),
        qual           varchar2(500),
        self_class_id  varchar2(16),
        base_id        varchar2(16),
        target_id      varchar2(16),
        mapped_id      varchar2(16),
        features       varchar2(16),
        flags          varchar2(30),
        position       pls_integer
	);
	type column_info_tbl_t is table of column_info_t index by binary_integer;
--
    subtype string_tbl_s      is constant.string_tbl_s;
    subtype defstring_tbl_s   is constant.defstring_table_s;
    subtype integer_tbl_s     is constant.integer_table_s;
    subtype index_tbl_s       is constant.index_table_s;
	subtype archive_rec_t     is constant.archive_rec_t;
    subtype archive_rec_tbl_t is constant.archive_rec_tbl_t;
--
    CHAR0     constant varchar2(1) := chr(0);
    GRID_CHAR constant varchar2(1) := chr(0);
    V9_FLAG   constant varchar2(1) := '1';
    --
    function  class_exist( p_class_id   IN varchar2,
			               p_class_info IN OUT nocopy class_info_t
			             ) return boolean;
    function  table_exist( p_class_id   IN varchar2,
			               p_table_info IN OUT nocopy table_info_t,
                           p_log_table  boolean default false
			             ) return boolean;
    function  attr_exist( p_attr_id  IN varchar2,
			              p_dbtype   IN OUT nocopy class_info_t,
                          p_class_id IN varchar2
			            ) return boolean;
    function  find_attr ( p_attr_id  IN varchar2,
                          p_class_id IN varchar2,
			              p_attr     IN OUT nocopy attr_info_t,
     		              p_dbtype   IN OUT nocopy class_info_t
			            ) return boolean;
    function find_attr_by_pos (p_attr_pos pls_integer,
                          p_class_id IN varchar2,
			              p_attr     IN OUT nocopy attr_info_t,
     		              p_dbtype   IN OUT nocopy class_info_t
			            ) return boolean;
    function find_def_attr (
                          p_class_id varchar2,
                          p_attr     in out nocopy attr_info_t,
                          p_dbtype   in out nocopy class_info_t,
                          p_parents  boolean
                        ) return pls_integer;
    pragma RESTRICT_REFERENCES ( find_def_attr, WNDS, WNPS, TRUST );
    function get_def_qual(p_class_id varchar2,
                          p_dbtype   in out nocopy class_info_t,
                          p_parents  boolean
                         ) return varchar2;
    pragma RESTRICT_REFERENCES ( get_def_qual, WNDS, WNPS, TRUST );
    function  method_exist( p_sname     IN varchar2,
				            p_method    IN OUT nocopy method_info_t,
                            p_class_id  IN varchar2
			              ) return boolean;
    function  find_method ( p_id     IN varchar2,
	                        p_method IN OUT nocopy method_info_t
						  ) return boolean;
    procedure desc_method ( p_id     IN varchar2,
	                        p_method IN OUT nocopy method_info_t
						  );
    procedure class_table ( p_class_id IN  varchar2,
                            p_table    OUT nocopy varchar2,
                            p_group    OUT nocopy varchar2,
                            p_self varchar2 default null);
    pragma RESTRICT_REFERENCES ( class_table, WNDS, WNPS, TRUST );
    function  class_table ( p_class_id IN varchar2, p_self varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_table, WNDS, WNPS, TRUST );
    --
    function find_column ( p_class_id varchar2,
                           p_qual     varchar2,
                           p_mapped   pls_integer,
                           p_tbl      in out nocopy table_info_t,
                           p_col      in out nocopy column_info_t
                          ) return boolean;
    pragma RESTRICT_REFERENCES ( find_column, WNDS, WNPS, TRUST );
    function  qual_column( p_class_id IN  varchar2,
                           p_qual     IN  varchar2,
                           p_table    OUT nocopy varchar2,
                           p_column   OUT nocopy varchar2,
                           p_features OUT nocopy varchar2,
                           p_mapped   IN  varchar2 default null
                         ) return boolean;
    pragma RESTRICT_REFERENCES ( qual_column, WNDS, WNPS, TRUST );
    --
    procedure qual_column( p_class_id IN  varchar2,
                           p_qual     IN  varchar2,
                           p_table    OUT nocopy varchar2,
                           p_column   OUT nocopy varchar2,
                           p_features OUT nocopy varchar2,
                           p_mapped   IN  varchar2 default null
                         );
    pragma RESTRICT_REFERENCES ( qual_column, WNDS, WNPS, TRUST );
    --
    function  attr_column( p_class_id IN varchar2,
                           p_qual     IN varchar2,
						   p_table    IN boolean default FALSE
			             ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( attr_column, WNDS, WNPS );
    --
    procedure attr_column( p_class_id IN  varchar2,
                           p_qual     IN  varchar2,
                           p_table    OUT nocopy varchar2,
                           p_column   OUT nocopy varchar2,
                           p_mapped   IN  varchar2 default null
                         );
    pragma RESTRICT_REFERENCES ( attr_column, WNDS, WNPS );
    --
    procedure get_class_attrs(p_attrs in out nocopy attr_info_tbl_t, p_class varchar2, p_self boolean);
    procedure get_class_columns(p_cols in out nocopy column_info_tbl_t, p_class varchar2, p_self boolean);
    --
    function qual_exist( p_qual  IN OUT nocopy varchar2,
                         p_class IN varchar2,
                         p_self  IN boolean
                        ) return boolean;
    function field_exist( p_qual  IN OUT nocopy varchar2,
                          p_class IN varchar2,
                          p_tbl   IN boolean
                        ) return boolean;
    procedure get_fields( p_quals in out nocopy constant.varchar2_table,
                          p_types in out nocopy constant.refstring_table,
                          p_class varchar2,p_mode boolean default true,p_self number default 0);
    procedure correct_qual(p_class_id varchar2,p_qual in out nocopy varchar2);
    --
    procedure get_partition(p_name in out nocopy varchar2, p_key in out nocopy number,
                            p_class_id varchar2, p_position integer default null);
    pragma RESTRICT_REFERENCES ( get_partition, WNDS, WNPS, TRUST );
    function  partition_name(p_class_id varchar2, p_position integer default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( partition_name, WNDS, WNPS );
    function  partition_key (p_class_id varchar2, p_position integer default null) return number deterministic;
    pragma RESTRICT_REFERENCES ( partition_key, WNDS, WNPS );
    --
    /**
     * Замена подстроки без учета регистра. Аналог rtl.safe_replace,
     * только не заменяет вхождения, являющиеся частью другого идентификатора
     * (т.е. буквенно-цифровой последовательности).
     * Например: soft_replace('***SRCH***','srch','repl') вернет '***repl***',
     *   а soft_replace('***SRCH_1***','srch','repl') вернет '***SRCH_1***'
     * @param str исходная строка
     * @param str1 строка все вхождения, которой нужно найти в str
     *   Если пуста, то возвращается не модифицированная строка.
     * @param str2 строка на которую заменяются все вхождения str1 в str.
     *   Если пуста, то все вхождения str1 удаляются.
     * @param symb - набор символов, интерпретируемых в качестве идентификаторов
     *   Если пуста, то используются символы "#$'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_
     * @return Строка, полученная из str путем замены всех вхождений
     *   подстроки str1 на str2 (причем поиск и замена case insensitive).
     */
    function soft_replace(str  varchar2,
                          str1 varchar2 default null,
                          str2 varchar2 default null,
                          symb varchar2 default null) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( soft_replace, WNDS, WNPS );
    --
    /**
     * Проверка отношения наследования.
     * Принадлежит ли тип p_child_class иерархии типа
     * p_parent_class. Если p_start=TRUE, то проверка строгая - т.е.
     * сам тип не может быть родителем самому себе.
     */
    function is_parent ( p_parent_class IN varchar2,
                         p_child_class  IN varchar2,
                         p_start    IN boolean default FALSE
					   ) return boolean;
    PRAGMA RESTRICT_REFERENCES ( is_parent, WNDS, WNPS, TRUST );
    --
    /**
     * Возвращает верхнеуровневого родителя для заданного типа в p_class
     */
    function top_parent ( p_class IN varchar2 ) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( top_parent, WNDS, WNPS );
    /**
     * Возвращает ближнего общего родителя для заданных типов в p_class1, p_class2
     */
    function common_parent( p_class1 varchar2, p_class2 varchar2 ) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( common_parent, WNDS, WNPS );
    --
    /**
     * Возвращает список родительских типов для p_class в формате:
     * .<top parent>.<top-1 parent>. ... .<nearest parent>.
     * p_check_class - признак проверки существования типа p_class как такового
     */
    function get_parents( p_class IN varchar2, p_check_class boolean default true ) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( get_parents, WNDS, WNPS, TRUST );
    --
    /**
     * Проверка совместимости типов p_parent_class p_child_class.
     */
    function is_compatible ( p_parent_class IN varchar2,
                             p_child_class  IN varchar2
					       ) return boolean;
    PRAGMA RESTRICT_REFERENCES ( is_compatible, WNDS, WNPS, TRUST );
    --
    function is_kernel ( p_id    varchar2,
                         p_class boolean default TRUE
                       ) return boolean;
    PRAGMA RESTRICT_REFERENCES ( is_kernel, WNDS, WNPS, TRUST );
    --
    function has_instances ( p_id    varchar2,
                         p_class boolean default TRUE
                       ) return boolean;
    PRAGMA RESTRICT_REFERENCES ( has_instances, WNDS, WNPS, TRUST );
    --
    function is_reference ( p_referencing IN varchar2,
                            p_referenced  IN varchar2
					      ) return boolean;
    PRAGMA RESTRICT_REFERENCES ( is_reference, WNDS, WNPS, TRUST );
    --
    function has_stringkey ( p_class varchar2) return boolean;
    PRAGMA RESTRICT_REFERENCES ( has_stringkey, WNDS, WNPS, TRUST );
    --
    function pk_is_rowid ( p_class varchar2) return boolean;
    PRAGMA RESTRICT_REFERENCES ( pk_is_rowid, WNDS, WNPS, TRUST );
    --
    function process_types_with_rowid return boolean;
    PRAGMA RESTRICT_REFERENCES ( process_types_with_rowid, WNDS, WNPS, TRUST );
    --
    function check_class_flags(p_flag varchar2,p_self boolean) return boolean;
    PRAGMA RESTRICT_REFERENCES ( check_class_flags, WNDS, WNPS );
    --
    function has_childs ( p_class varchar2) return boolean;
    PRAGMA RESTRICT_REFERENCES ( has_childs, WNDS, WNPS, TRUST );
    --
    function has_state_id ( p_class varchar2, p_self boolean default true) return boolean;
    PRAGMA RESTRICT_REFERENCES ( has_state_id, WNDS, WNPS, TRUST );
    --
    function has_collection_id ( p_class varchar2, p_self boolean default true) return boolean;
    PRAGMA RESTRICT_REFERENCES ( has_collection_id, WNDS, WNPS, TRUST );
    --
    function has_partitions ( p_class varchar2) return varchar2 deterministic;
    PRAGMA RESTRICT_REFERENCES ( has_partitions, WNDS, WNPS, TRUST );
    --
    function  coll2class ( p_collect_id IN number ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( coll2class, WNDS );
    --
    /**
     * Является ли коллекция пустой,
     * @param p_collect_id Идентификатор коллекции.
     * @param p_class Тип объектов коллекции.
     */
    function  c_empty( p_collect_id number,
                       p_class      varchar2 default NULL  ) return boolean;
    --
    /**
     * Возвращает количество объектов в коллекции.
     * @param p_collect_id Идентификатор коллекции.
     * @param p_class Тип объектов коллекции.
     */
    function  c_count( p_collect_id number,
                       p_class      varchar2 default NULL ) return pls_integer deterministic;
    --
    procedure counter( p_collect_id number,
                       p_class      varchar2,
                       p_cnt in out nocopy number );
    --
    /**
     * Возвращает размер типа (в байтах).
     * Если тип является структурой, то размер рассчитывается по
     * сумме размеров всех его реквизитов.
     * @param p_class_id Короткое имя типа
     */
    function class_size ( p_class_id varchar2 ) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( class_size, WNDS, WNPS );
    --
    /**
     * Возвращает полное наименование реквизита.
     * @param p_attr_id Короткое имя реквизита.
     * @param p_class_id Короткое имя типа, которому принадлежит реквизит.
     */
    function attr_name ( p_attr_id  varchar2,
                         p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( attr_name, WNDS, WNPS, TRUST );
    --
    /**
     * Возвращает полное наименование реквизита.
     * @param p_attr_pos Позиция реквизита.
     * @param p_class_id Короткое имя типа, которому принадлежит реквизит.
     */
    function attr_name ( p_attr_pos pls_integer,
                         p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( attr_name, WNDS, WNPS, TRUST );
    --
    /**
     * Возвращает полное наименование состояния.
     * @param p_state_id Короткое имя состояния.
     * @param p_class_id Короткое имя типа, которому принадлежит состояние.
     */
    function state_name ( p_state_id varchar2,
                          p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( state_name, WNDS, WNPS );
    --
    /**
     * Возвращает полное наименование типа.
     * @param p_class_id Короткое имя типа.
     */
    function class_name ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_name, WNDS, WNPS, TRUST );
    --
    function class_base ( p_class_id varchar2, p_sql varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_name, WNDS, WNPS, TRUST );
    --
    function class_target ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_name, WNDS, WNPS, TRUST );
    --
    function class_entity ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_name, WNDS, WNPS, TRUST );
    --
    function class_parent ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_name, WNDS, WNPS, TRUST );
    --
    function class_state  ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_state, WNDS, WNPS, TRUST );
    --
    function class_flags  ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_flags, WNDS, WNPS, TRUST );
    --
    function class_temp_type ( p_class_id varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( class_temp_type, WNDS, WNPS, TRUST );
    --
    function qualprop(
    		p_class_id	in varchar2,
    		p_qual		in varchar2,
    		p_elem_class		out nocopy varchar2,
    		p_elem_base_class	out nocopy varchar2,
    		p_elem_target_class	out nocopy varchar2,
    		p_elem_name			in out nocopy varchar2,
            p_separator in varchar2) return varchar2;
    pragma RESTRICT_REFERENCES ( qualprop, WNDS, WNPS, TRUST );
    --
    function qual_class(p_class_id varchar2, p_qual varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( qual_class, WNDS, WNPS );
    --
    function qual_base (p_class_id varchar2, p_qual varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( qual_base, WNDS, WNPS );
    --
    function qual_name (p_class_id varchar2, p_qual varchar2, p_separator varchar2 default ' ') return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( qual_name, WNDS, WNPS );
    --
    function qual_target(p_class_id varchar2, p_qual varchar2) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( qual_target, WNDS, WNPS );
    --
    /**
     * Возвращает дату операционного дня.
     * @return
     * <ul>
     *   <li>Если <code>day(p_date) = day(sysdate)</code>, то <code>sysdate</code>
     *   <li>Если <code>day(p_date) < day(sysdate)</code>, то <code>day(sysdate)</code> и время 00:00:00
     *   <li>Если <code>day(p_date) > day(sysdate)</code>, то <code>day(sysdate)</code> и время 23:59:59
     * </ul>
     */
    function operating_date ( p_date IN date ) return date deterministic;
	pragma RESTRICT_REFERENCES ( operating_date, WNDS, WNPS );
    --
    /**
     * Возвращает имя исполняемой процедуры (секции EXECUTE).
     * @param p_method_id Идентификатор операции.
     */
	function plsql_exec_name ( p_method_id IN varchar2, p_validate varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( plsql_exec_name , WNDS, WNPS );
    --
    procedure set_index_list( p_list  varchar2,
                              p_tbl   in out nocopy   constant.integer_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_index_list , WNDS, WNPS );
    --
    procedure set_refs_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.reference_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_refs_list , WNDS, WNPS );
    --
    procedure set_refs_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.refstring_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_refs_list , WNDS, WNPS );
    --
    procedure set_defs_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.defstring_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_refs_list , WNDS, WNPS );
    --
    procedure set_string_list(p_list  varchar2,
                              p_tbl   in out nocopy   constant.string_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_string_list , WNDS, WNPS );
    --
    procedure set_number_list(p_list  varchar2,
                              p_tbl   in out nocopy   constant.number_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_number_list , WNDS, WNPS );
    --
    procedure set_date_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.date_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_date_list , WNDS, WNPS );
    --
    procedure set_bool_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.boolean_table,
                              p_clear boolean  default true,
                              p_char  varchar2 default null );
    pragma RESTRICT_REFERENCES ( set_bool_list , WNDS, WNPS );
    --
    function  get_index_list( p_tbl   in constant.integer_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_index_list , WNDS, WNPS );
    --
    function  get_refs_list ( p_tbl   in constant.reference_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_refs_list , WNDS, WNPS );
    --
    function  get_refs_list ( p_tbl   in constant.refstring_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_refs_list , WNDS, WNPS );
    --
    function  get_defs_list ( p_tbl   in constant.defstring_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_refs_list , WNDS, WNPS );
    --
    function  get_date_list ( p_tbl   in constant.date_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_date_list , WNDS, WNPS );
    --
    function  get_bool_list ( p_tbl   in constant.boolean_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_bool_list , WNDS, WNPS );
    --
    function  get_number_list(p_tbl   in constant.number_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  varchar2 default null ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_number_list , WNDS, WNPS );
    --
    function  get_string_list(p_tbl   in constant.string_table,
                              p_idx   in out nocopy pls_integer,
                              p_char  in varchar2 default null,
							  p_dch   in varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_string_list , WNDS, WNPS );
    --
    function  get_class ( p_object_id IN number ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_class , WNDS );
    function  get_class ( p_object_id IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_class , WNDS );
    --
    procedure get_parent ( p_collect number, p_object in out nocopy rtl.object_rec );
    pragma RESTRICT_REFERENCES ( get_parent, WNDS );
    --
    function grid_get(avalues in constant.string_table, aflags in out nocopy constant.defstring_table,
      aind in out nocopy pls_integer,
      acol_count in pls_integer,
      agrid_char in varchar2 default null, ares_char in varchar2 default null) return varchar2;
    --
    function grid_get_col(avalues in constant.string_table, aflags in out nocopy constant.defstring_table,
      aind in out pls_integer, acol in pls_integer, agrid_char in varchar2 default null) return varchar2;
    --
    procedure set_flag(aflags in out nocopy varchar2, aind in pls_integer,
      aaction in boolean default true);
    procedure set_flag(aflags in out nocopy varchar2, aind in pls_integer, avalue in char);
    function check_flag(aflags in varchar2, aind in pls_integer) return boolean;
    function flags_or(aflags in constant.defstring_table, acount in pls_integer) return varchar2;
    --
    function get_row_val(arow in varchar2, aind in pls_integer,
      achar in varchar2 default null) return varchar2;
    procedure set_row_val(arow in out nocopy varchar2, aind in pls_integer,
      avalue in varchar2, achar in varchar2 default null);
    procedure check_vals(abuf in out nocopy varchar2, apar in varchar2, aflags in out nocopy varchar2,
      acol_count in pls_integer, adep_flags in out nocopy varchar2,
      acheck_flags in varchar2 default null,
      achar in varchar2 default null);
    --
    procedure sorting(p_idx   in out nocopy constant.integer_table,
                      p_vals  in constant.integer_table,
                      p_left  in pls_integer,
                      p_right in pls_integer);
    pragma RESTRICT_REFERENCES ( sorting , WNDS, WNPS );
    --
    procedure sorting(p_idx   in out nocopy constant.integer_table,
                      p_vals  in constant.number_table,
                      p_left  in pls_integer,
                      p_right in pls_integer);
    pragma RESTRICT_REFERENCES ( sorting , WNDS, WNPS );
    --
    procedure sorting(p_idx   in out nocopy constant.integer_table,
                      p_vals  in constant.string_table,
                      p_left  in pls_integer,
                      p_right in pls_integer);
    pragma RESTRICT_REFERENCES ( sorting , WNDS, WNPS );
    --
    procedure sorting(p_idx   in out nocopy constant.integer_table,
                      p_vals  in constant.refstring_table,
                      p_left  in pls_integer,
                      p_right in pls_integer);
    pragma RESTRICT_REFERENCES ( sorting , WNDS, WNPS );
    --
    procedure sorting(p_idx   in out nocopy constant.integer_table,
                      p_vals  in constant.defstring_table,
                      p_left  in pls_integer,
                      p_right in pls_integer);
    pragma RESTRICT_REFERENCES ( sorting , WNDS, WNPS );
    --
    procedure sorting(p_idx   in out nocopy constant.integer_table,
                      p_vals  in constant.date_table,
                      p_left  in pls_integer,
                      p_right in pls_integer);
    pragma RESTRICT_REFERENCES ( sorting , WNDS, WNPS );
--
    procedure add_buf( p_text in out nocopy constant.DEFSTRING_TABLE,
                       p_buf  in out nocopy constant.DEFSTRING_TABLE,
                       p_end  boolean default true,
                       p_del  boolean default false
                     );
    procedure put_buf( p_text varchar2,
                       p_buf  in out nocopy constant.DEFSTRING_TABLE,
                       p_end  boolean default true
                     );
    function  get_buf( p_text in out nocopy varchar2,
                       p_buf  in out nocopy constant.DEFSTRING_TABLE,
                       p_end  boolean default true,
                       p_del  boolean default false,
                       p_idx  pls_integer default null
                     ) return pls_integer;
    function  equal_buf(p_buf1 in constant.DEFSTRING_TABLE,
                        p_buf2 in constant.DEFSTRING_TABLE
                       ) return boolean;
    procedure instr_buf( p_idx in out nocopy pls_integer, p_pos in out nocopy pls_integer,
                         p_buf in constant.DEFSTRING_TABLE, p_search varchar2 );
    procedure replace_buf( p_buf  in out nocopy constant.DEFSTRING_TABLE,
                           p_search varchar2, p_replace varchar2 default null );
    procedure add_buf( p_text in out nocopy constant.STRING_TABLE,
                       p_buf  in out nocopy constant.STRING_TABLE,
                       p_end  boolean default true,
                       p_del  boolean default false
                     );
    procedure put_buf( p_text varchar2,
                       p_buf  in out nocopy constant.STRING_TABLE,
                       p_end  boolean default true
                     );
    function  get_buf( p_text in out nocopy varchar2,
                       p_buf  in out nocopy constant.STRING_TABLE,
                       p_end  boolean default true,
                       p_del  boolean default false,
                       p_idx  pls_integer default null
                     ) return pls_integer;
    procedure instr_buf( p_idx in out nocopy pls_integer, p_pos in out nocopy pls_integer,
                         p_buf in constant.STRING_TABLE, p_search varchar2 );
    procedure replace_buf( p_buf  in out nocopy constant.STRING_TABLE,
                           p_search varchar2, p_replace varchar2 default null );
    --
    procedure reset_class(p_class varchar2);
    --
    function  normalize_properties(p_prop in varchar2, p_skip varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( normalize_properties, WNDS, WNPS );
    function  extract_property(p_string   in varchar2,
                               p_property in varchar2 default NULL) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( extract_property, WNDS, WNPS );
    procedure put_property(p_string in out nocopy varchar2,
                       p_property  in varchar2 default null,
                       p_value  in varchar2 default null);
    pragma RESTRICT_REFERENCES ( put_property, WNDS, WNPS );
    procedure remove_property(p_string in out nocopy varchar2,
                       p_property  in varchar2 default null);
    pragma RESTRICT_REFERENCES ( remove_property, WNDS, WNPS );
    --
    function has_rowid(properties varchar2, p_class_id varchar2:=null) return varchar2;
    --
    function encode_national_string(national_string nvarchar2) return varchar2;
    function decode_national_string(national_string varchar2) return nvarchar2;
    function is_nvarchar_based(base_class varchar2) return boolean;
    --
end lib;
/
show errors
