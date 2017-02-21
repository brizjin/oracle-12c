prompt plib
create or replace package plib is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/PLIB1.SQL $
 *  $Author: VKazakov $
 *  $Revision: 134094 $
 *  $Date:: 2017-01-24 12:59:25 #$
 */
--
    subtype string_tbl_t    is constant.DEFSTRING_TABLE;
    subtype java_code_tbl_t is constant.STRING_TABLE;
    subtype idx_tbl_t       is constant.INTEGER_TABLE;
    subtype string_stbl_t   is constant.DEFSTRING_TABLE_S;
    subtype integer_tbl_s   is constant.INTEGER_TABLE_S;
    subtype index_tbl_s     is constant.INDEX_TABLE_S;
--
	type string_rec_t is record (
		text1 varchar2(2000),
		text2 varchar2(2000),
		text3 varchar2(2000),
		text4 varchar2(2000)
	);
    type string_rec_tbl_t  is table of string_rec_t index by binary_integer;
    type string_rec_stbl_t is table of string_rec_t index by varchar2(128);
--
	type ir_node_t is record (
        node        pls_integer,
        right       pls_integer,
        down        pls_integer,
        left        pls_integer,
        line        pls_integer,
        pos         pls_integer,
        type        pls_integer,
        type1       pls_integer,
        text        varchar2(2000),
		text1       varchar2(1000),
        --
        einfo       pls_integer  -- extra info
	);
    type ir_tbl_t is table of ir_node_t index by binary_integer;
--
	type plp_class_t is record (
		is_udt         boolean,		-- user-defined type
        base_type      pls_integer,
        class_id       varchar2(40),-- definition index in repository
        parent_id      varchar2(16),
        base_id        varchar2(16),-- base class
        data_size      pls_integer, -- classes.data_size%type,
        data_precision pls_integer, -- classes.data_precision%type,
		is_collection  boolean,		-- class is collection
		is_reference   boolean,		-- class is reference
        elem_class_id  varchar2(16),
		kernel         boolean,     -- kernel class
        has_type       boolean      -- has oracle type
	);
    type plp_class_tbl_t is table of plp_class_t index by binary_integer;
--
	type expr_info_t is record (
        compatible  pls_integer,
        expand      pls_integer,
        conv_in     pls_integer,
        conv_out    pls_integer,
        param_dir   varchar2(1)
	);
    type expr_info_tbl_t is table of expr_info_t index by binary_integer;
--
    type column_rec_t is record (
      column_id number,
      column_name varchar2(30),
      data_type_owner varchar2(30),
      data_type_mod varchar2(10),
      data_type varchar2(200),
      data_length number,
      data_precision number,
      data_scale number
      );
    type column_rec_tbl_t is table of column_rec_t index by binary_integer;
--
	THIS          constant varchar2(15) := 'THIS';
	IS_NULL       constant varchar2(7)  := 'is NULL';
	IS_NOT_NULL   constant varchar2(11) := 'is not NULL';
--
	DEF_OPTIONS   constant varchar2(20) := '01111011100111FF00';
	ORIGIN_PRAGMA constant varchar2(11) := 'ORIGIN';
	HINT_PRAGMA   constant varchar2(11) := 'HINT';
	DEBUG_PRAGMA  constant varchar2(11) := 'DEBUG';
    SET_PRAGMA    constant varchar2(11) := 'SET_DEBUG';
    LOG_PRAGMA    constant varchar2(11) := 'WRITE_LOG';
    DUMP_PRAGMA   constant varchar2(11) := 'DUMP';
    LOCK_PRAGMA   constant varchar2(11) := 'LOCK_THIS';
    COMMIT_PRAGMA constant varchar2(11) := 'USE_COMMIT';
    CACHE_PRAGMA  constant varchar2(11) := 'CACHE';
    DEFINE_PRAGMA constant varchar2(11) := 'DEFINE';
    IF_DEF_PRAGMA constant varchar2(11) := 'IF_DEF';
    END_IF_PRAGMA constant varchar2(11) := 'END_IF';
    MACRO_PRAGMA  constant varchar2(11) := 'MACRO';
    ERROR_PRAGMA  constant varchar2(11) := 'ERROR';
    GET_PRAGMA    constant varchar2(11) := 'GET_THIS';
    THIS_PRAGMA   constant varchar2(11) := 'SET_THIS';
    CREATE_PRAGMA constant varchar2(11) := 'CREATE';
    PLSQL_PRAGMA  constant varchar2(11) := 'PL_SQL';
    SUBSTITUTE_PRAGMA constant varchar2(11) := 'SUBSTITUTE';
    DEFOPTIONS_PRAGMA constant varchar2(11) := 'DEFOPTIONS';
    CALCULATE_PRAGMA  constant varchar2(11) := 'CALCULATE';
    CHECKTYPE_PRAGMA  constant varchar2(11) := 'CHECK_TYPE';
    CHECKOBJ_PRAGMA   constant varchar2(11) := 'CHECK_OBJ';
    OPTIMIZE_PRAGMA   constant varchar2(11) := 'OPTIMIZE';
    INITIALIZE_PRAGMA constant varchar2(11) := 'INITIALIZE';
    INCLUDE_PRAGMA    constant varchar2(11) := 'INCLUDE';
    ARCHIVE_PRAGMA    constant varchar2(11) := 'ARCHIVE';
    ORDER_PRAGMA      constant varchar2(11) := 'TBL_ORDER';
    THISNULL_PRAGMA   constant varchar2(11) := 'THIS_NULL';
    TYPEDJOINS_PRAGMA constant varchar2(11) := 'TYPED_JOINS';
    ALLPARAMS_PRAGMA  constant varchar2(11) := 'ALL_PARAMS';
    SETCOLUMN_PRAGMA  constant varchar2(11) := 'SET_COLUMN';
    SQLOPTIONS_PRAGMA constant varchar2(16) := 'SQL_EXEC_OPTIONS';
        
    RESTRICT_REFERENCES_PRAGMA constant varchar2(21) := 'RESTRICT_REFERENCES';
    EXCEPTION_INIT_PRAGMA constant varchar2(14) := 'EXCEPTION_INIT';
    SERIALLY_REUSABLE_PRAGMA constant varchar2(17) := 'SERIALLY_REUSABLE';
--
    SECTION_COMMENT   constant varchar2(11) := '--#section ';
    ORIGIN_COMMENT    constant varchar2(5)  := '--# ';
    rtl_sql_idx       constant pls_integer  := 100;
--
    AUX_DEP_TYPE_MACRO     constant varchar2(1) := 'D';
    AUX_DEP_TYPE_INCLUDE   constant varchar2(1) := 'I';
--
    JAVA       constant varchar2(10):= 'JAVA';
--
    plp$errors      pls_integer;
    plp$warnings    pls_integer;
    plp$err_line    pls_integer;
    plp$err_pos     pls_integer;
    plp$line        pls_integer;
    plp$start_line  pls_integer;
    plp$start_pos   pls_integer;
    plp$pos         pls_integer;
    plp$prev_pos    pls_integer;
    plp$define      boolean default TRUE;
    plp$parsedef    boolean default TRUE;
    plp$check_line  boolean default TRUE;
--
	in_str		varchar2(32767);
	pack_header varchar2(32767);
    plp$err_text varchar2(2000);
    section     varchar2(30);
    in_tbl      "CONSTANT".STRING_TABLE;
    out_tbl     string_tbl_t;
--
    java_code   java_code_tbl_t;
--
	ir			ir_tbl_t;		-- intermediate representation
--
    g_class_id     varchar2(16);
    g_class_key    varchar2(16);
    g_crit_id      varchar2(16);
    g_base_id      varchar2(16);
    g_class_flags  varchar2(40);
    g_method_id    varchar2(16);
    g_method_src   varchar2(16);
    g_method_result varchar2(16);
    g_method_flags varchar2(30);
    g_method_pack  varchar2(30);
    g_actual_pack  varchar2(30);
    g_method_sname varchar2(30);
    g_src_sname    varchar2(16);
    g_modified     date;
    context_flag   pls_integer;
    g_rtl_idx      pls_integer;
    g_method_log   pls_integer;
    g_method_upd   pls_integer;
    g_method_subst boolean;
    g_method_cache boolean;
    g_method_calc  boolean;
    g_calc_expr    boolean;
    g_calc_const   boolean;
    g_calc_attr    boolean;
    g_calc_class   boolean;
    g_method_lock  boolean;
    g_method_check boolean;
    g_method_cobj  boolean;
    g_method_optim boolean;
    g_optim_decl   boolean;
    g_optim_this   boolean;
    g_optim_code   boolean;
    g_optim_desc   boolean;
    g_method_commit boolean;
    g_method_text  boolean;
    g_method_arch  boolean;
    g_prt_actual   boolean;
    g_tbl_order    boolean;
    g_this_null    boolean;
    g_constructor  boolean;
    g_plsql        boolean;
    g_plptypes     boolean;
    g_typed_joins  boolean;
    g_parse_java   boolean;
    g_src_merge    boolean;
    g_for_f12      boolean;
    g_for_f12_ext  boolean;
    g_java_ext     pls_integer;
    g_compiler     varchar2(100);
    g_read_pipe    varchar2(100);
    g_write_pipe   varchar2(100);

    sql_options_lock_info_cur    boolean;
    sql_options_lock_info_buf    boolean;
    sql_options_autoflush_cur    boolean;
    sql_options_autoflush_buf    boolean;
--
    function  parse ( p_mid  varchar2, p_sql boolean default TRUE, p_tbl boolean default FALSE,
                      p_java boolean default false, p_arch boolean default null ) return pls_integer;
    function  parse$ ( p_mid  varchar2, p_sql boolean default TRUE, p_tbl boolean default FALSE,
                  p_java boolean default false, p_arch boolean default null ) return pls_integer;
    procedure parse_package ( p_name varchar2, p_owner varchar2 default NULL );
    procedure reset ( p_all boolean default true );
--
    function  input return varchar2 ;
	procedure unput( ch varchar2 );
    procedure get_comment( yytext in out nocopy varchar2, eoc IN varchar2 );
    procedure get_string ( yytext in out nocopy varchar2 );
    procedure insert_macro ( p_macro varchar2 );
    procedure parse_command( p_cmd varchar2 );
    function  time_interval( p_idx pls_integer ) return pls_integer;
--
    procedure set_local_app(p_type varchar2, p_class varchar2, p_short_name varchar2);
    procedure check_app_error_lic(p_idx       pls_integer,
                              p_code      varchar2,
                              p_type      varchar2,
                              p_class_id  varchar2,
                              p_shortname varchar2 default NULL,
                              p_method_id varchar2 default NULL);
--
    procedure plp_error ( p_idx    IN pls_integer,
                          p_code   IN varchar2,
                          p1       IN varchar2 default NULL,
                          p2       IN varchar2 default NULL,
                          p3       IN varchar2 default NULL,
                          is_error IN boolean  default TRUE
            );
   procedure plp_error_ext ( p_section IN varchar2,
                          p_line    IN pls_integer,
                          p_pos     IN pls_integer,
                          p_code    IN varchar2,
                          p1        IN varchar2 default NULL,
                          p2        IN varchar2 default NULL,
                          p3        IN varchar2 default NULL,
                          is_error  IN boolean  default TRUE
                        );
    procedure plp_warning ( p_idx  IN pls_integer,
                            p_code IN varchar2,
						    p1     IN varchar2 default NULL,
				            p2     IN varchar2 default NULL,
				            p3     IN varchar2 default NULL
						  );
    procedure write_errors(p_method_id varchar2 default null,p_type varchar2 default null);
--
    function  origin_text ( p_idx IN pls_integer ) return varchar2;
--
    function  find_string( p_table IN string_tbl_t,
                           p_text  IN varchar2,
                           p_start IN pls_integer default NULL
                         ) return pls_integer;
    function  find_record( p_table IN string_rec_tbl_t,
                           p_text1 IN varchar2,
                           p_text2 IN varchar2 default NULL,
                           p_text3 IN varchar2 default NULL,
                           p_text4 IN varchar2 default NULL,
                           p_start IN pls_integer default NULL
                         ) return pls_integer;
    function  add_unique( p_table in out nocopy string_rec_tbl_t,
                          p_text1 IN     varchar2,
                          p_text2 IN     varchar2 default NULL,
                          p_text3 IN     varchar2 default NULL,
                          p_text4 IN     varchar2 default NULL,
                          p_find  IN     boolean  default TRUE
                        ) return pls_integer;
    procedure add_unique( p_table in out nocopy string_rec_tbl_t,
                          p_text1 IN     varchar2,
                          p_text2 IN     varchar2 default NULL,
                          p_text3 IN     varchar2 default NULL,
                          p_text4 IN     varchar2 default NULL
                        );
--
    procedure add2comments ( p_line IN pls_integer,
                             p_pos  IN pls_integer,
							 p_text IN varchar2
						   );
    function  get_comments ( p_idx  IN pls_integer ) return varchar2;
--
	procedure clear_depends;
	procedure add2depends ( p_class_id IN varchar2,
						    p_type     IN varchar2,
						    p_qual     IN varchar2,
						    p_qclass   IN varchar2,
                            p_is_src_method boolean default false/*,
                            p_type0    IN pls_integer,
                            p_type1    IN pls_integer,
						    p_text0    IN varchar2(1000),
						    p_text1    IN varchar2(1000)*/
						  );
    procedure write_globals(p_id varchar2 default null);
    procedure write_dependencies(p_refcing varchar2 default null, p_type varchar2 default null);
--
    procedure write_cursors(p_id varchar2 default null);
    procedure add_cursor(p_text varchar2, p_idx pls_integer default null);
    function  get_cursor(p_idx  pls_integer) return varchar2;
    function  get_column_props(p_alias varchar2) return varchar2;
--
    procedure get_node ( p_idx  IN  pls_integer,
                         p_node OUT ir_node_t
					   );
    function  get_type( p_idx IN pls_integer,
						p_typ IN boolean default TRUE
                       ) return pls_integer;
--
    function  get_text( p_idx IN pls_integer,
						p_txt IN boolean default TRUE
					  ) return varchar2;
--
	procedure set_node ( p_node  OUT ir_node_t,
                         p_type  IN  pls_integer,
                         p_line  IN  pls_integer default NULL,
                         p_pos   IN  pls_integer default NULL,
						 p_text  IN  varchar2 default NULL,
						 p_text1 IN  varchar2 default NULL,
                         p_type1 IN  pls_integer default NULL
					   );
--
	procedure set2ir ( p_node IN ir_node_t,
                       p_idx  IN pls_integer
					 );
    procedure set_text ( p_idx   IN pls_integer,
						 p_text  IN varchar2,
						 p_text1 IN varchar2 default NULL
					   );
--
    procedure set_origin ( p_idx   IN pls_integer,
                           p_line  IN pls_integer,
                           p_pos   IN pls_integer
					     );
--
    function  collect_text( p_idx      pls_integer,
							p_separate boolean default TRUE,
							p_indexes  boolean default FALSE,
							p_ir_text  boolean default TRUE
						  ) return varchar2;
--
    function  add2ir( p_node   IN ir_node_t,
                      p_child1 IN pls_integer default NULL,
                      p_child2 IN pls_integer default NULL,
                      p_child3 IN pls_integer default NULL,
                      p_child4 IN pls_integer default NULL
                    ) return pls_integer;
--
    function  add2ir( p_type  IN pls_integer,
                      p_type1 IN pls_integer,
					  p_text  IN varchar2,
					  p_text1 IN varchar2,
                      p_child1 IN pls_integer default NULL,
                      p_child2 IN pls_integer default NULL
                    ) return pls_integer;
--
    procedure add_child ( p_parent IN pls_integer,
                          p_child  IN pls_integer,
						  p_last   IN boolean default TRUE
						);
--
    procedure add_child ( p_parent IN pls_integer,
	                      p_node   IN ir_node_t,
						  p_last   IN boolean default TRUE
						);
--
    procedure add_sibling ( p_node0 IN pls_integer,
                            p_node1 IN pls_integer
					      );
--
    procedure add_neighbour ( p_node0 IN pls_integer,
                              p_node1 IN pls_integer,
                              p_right IN boolean default TRUE
                            );
--
    procedure copy_info ( p_from IN pls_integer, p_to IN pls_integer );
    function  parent ( p_idx pls_integer ) return pls_integer;
--
    function  find_child( p_start IN pls_integer,
                          p_type  IN pls_integer,
                          p_text  IN varchar2 default NULL
                        ) return pls_integer;
--
    function find_node ( p_idx  pls_integer,
                         p_type pls_integer,
                         p_text varchar2,
                         p_sibling boolean,
                         p_only_type boolean default FALSE
                        ) return pls_integer;
--
    function  find_left( p_start IN pls_integer,
                         p_type  IN pls_integer,
                         p_text  IN varchar2 default NULL,
					     p_shift IN boolean  default TRUE,
                         p_text1 IN varchar2 default NULL
                       ) return pls_integer;
--
    function  last_child( p_idx pls_integer ) return pls_integer;
--
/*    procedure dump_node ( p_symbol IN ir_node_t,
                          l        IN pls_integer default 0,
                          p_dlevel IN pls_integer default 3
                        );*/
--
    procedure dump_node ( p_idx    IN pls_integer,
                        l        IN pls_integer default 0,
                        p_dlevel IN pls_integer default 3
						);
--
    procedure dump_type(p_class plp_class_t,p_dlevel  IN pls_integer default 3);
    procedure dump_ir ( i        IN pls_integer default NULL,
                        l        IN pls_integer default 0,
                        p_dlevel IN pls_integer default 3,
					    p_sibling IN boolean default TRUE
					  );
    function  type_name ( p_type IN pls_integer ) return varchar2;
--
    procedure dump_depends ( p_dlevel IN pls_integer default 2 );
	procedure dump_strings ( p_table  IN string_rec_tbl_t,
						 	 p_title  IN varchar2 default NULL,
                             p_dlevel IN pls_integer default 2
					   	   );
--
    function  correct_name(p_name varchar2) return varchar2;
    function  var ( name varchar2 ) return varchar2;
    function  ns( text varchar2 ) return varchar2;
    function  nn( p_prefix IN varchar2,
	              p_text IN varchar2,
			      p_suffix IN varchar2 default NULL
			    ) return varchar2;
--
    function  ne( p_prefix IN varchar2,
	              p_text IN varchar2,
			      p_suffix IN varchar2 default NULL
			    ) return varchar2;
--
    function  iif( p_bool  IN boolean,
	               p_true  IN varchar2,
				   p_false IN varchar2 default NULL
				 ) return varchar2;
--
    function  iif( p_bool  IN boolean,
                   p_true  IN pls_integer,
                   p_false IN pls_integer default NULL
                 ) return pls_integer;
--
    procedure set_type(p_idx pls_integer, var_info  plp_class_t, p_dbobj boolean );
    procedure set_type(p_idx pls_integer);
    function  table_type(p_type plp_class_t,p_tbl pls_integer,p_optim boolean) return varchar2;
--
    function  convert_base ( p_base IN varchar2 ) return pls_integer;
--
    procedure delete_branch ( p_idx IN pls_integer );
    procedure delete_node ( p_idx IN pls_integer );
    procedure delete_children( p_idx IN pls_integer );
    function  count_children ( p_parent IN pls_integer ) return pls_integer;
--
    procedure replace_prefix ( p_idx     IN pls_integer,
							   p_text0   IN varchar2,
                               p_text1   IN varchar2,
                               p_skip    IN boolean default FALSE,
                               p_info    IN pls_integer default NULL
	                         );
    procedure replace_var_prefix (p_idx   in out nocopy pls_integer,
                                  p_srch  pls_integer,
                                  p_repl  pls_integer,
                                  p_sibling boolean );
    function  load_node ( p_meth varchar2,    p_name varchar2,
                          p_line pls_integer, p_pos pls_integer
                        ) return pls_integer;
    function  copy_node ( p_idx  pls_integer, p_left pls_integer,
                          p_child boolean, p_right boolean
                        ) return pls_integer;
    procedure replace_node ( p_node0 IN pls_integer, p_node1 IN pls_integer );
    procedure replace_nodes( p_idx   IN pls_integer,
                             p_node  IN pls_integer,
                             p_type  IN pls_integer,
                             p_text  IN varchar2,
                             p_type1 IN pls_integer default NULL,
                             p_text1 IN varchar2 default NULL,
                             p_sibling IN boolean default FALSE
                            );
    procedure delete_prefix( p_idx   IN pls_integer,
                             p_type  IN pls_integer,
                             p_text  IN varchar2,
                             p_type1 IN pls_integer default NULL,
                             p_text1 IN varchar2 default NULL,
                             p_sibling IN boolean default FALSE );
    function  glob_defined( p_idx pls_integer, p_name varchar2 ) return pls_integer;
--
    procedure fill_rowtype(p_class in out nocopy plp_class_t,
                           cls varchar2, typ pls_integer, col boolean);
    procedure fill_class_info( p_class    in out nocopy plp_class_t,
                               p_class_id in varchar2 default NULL,
                               p_clear    in boolean  default true
                             );
    procedure expr_class ( p_idx   IN  pls_integer,
                           p_class in out nocopy plp_class_t,
                           p_clear IN  boolean default TRUE,
                           p_type  IN  boolean default FALSE
                         );
    function  num_const_type(p_text varchar2) return varchar2;
    function  collection_element_class( p_idx   in pls_integer,
                                        p_table in out nocopy varchar2,
                                        p_udt   in out nocopy boolean
                                       ) return varchar2;
    function  types_compatible( l_value  IN plp_class_t,
                                r_value  IN plp_class_t,
                                p_struct IN boolean default FALSE
                              ) return pls_integer;
    function  check_lvalue( p_idx pls_integer, par_name varchar2,
                            p_ok  in out nocopy pls_integer,
                            p_value in out nocopy plp_class_t ) return boolean;
    function  fill_attrs(p_attrs in out nocopy string_rec_tbl_t,
                         p_obj_attrs  boolean default false,
                         p_func_attrs boolean default true) return boolean;
--
    procedure set_function ( p_idx pls_integer, p_flags pls_integer );
    procedure use_pragma ( p_idx in out nocopy pls_integer );
    function  pragma_text( p_idx IN pls_integer ) return varchar2;
    function  is_method  ( p_idx pls_integer ) return boolean;
--
    procedure add_buf( p_text in out nocopy string_tbl_t,
                       p_buf  in out nocopy string_tbl_t,
                       p_end  boolean default true,
                       p_del  boolean default false
                     );
    procedure put_buf( p_text varchar2,
                       p_buf  in out nocopy string_tbl_t,
                       p_end  boolean default true
                     );
    function  get_buf( p_text in out nocopy varchar2,
                       p_buf  in out nocopy string_tbl_t,
                       p_end  boolean default true,
                       p_del  boolean default false,
                       p_idx  pls_integer default null
                     ) return pls_integer;
    procedure instr_buf( p_idx in out nocopy pls_integer, p_pos in out nocopy pls_integer,
                         p_buf string_tbl_t, p_search varchar2 );
    procedure replace_buf( p_buf  in out nocopy string_tbl_t,
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
    function  is_defined(p_define varchar2) return boolean;
    function  get_new_name (p_idx pls_integer) return varchar2;
    function  get_expr_type(p_idx pls_integer, p_type in out nocopy plp_class_t) return boolean;
    function  pop_expr_info(p_idx pls_integer, p_info in out nocopy expr_info_t) return boolean;
    procedure put_expr_info(p_idx pls_integer, p_info expr_info_t);
--
    function ir_top(p_mas ir_tbl_t) return pls_integer;
--
    procedure change_declare_level;
    procedure process_declare_level;
    procedure process_public_modifier ( p_idx in out nocopy pls_integer  );
    procedure process_spec_pragma_for_public ( p_idx pls_integer );
    function is_new_format return boolean;
		
--
	
end plib;
/
show errors
