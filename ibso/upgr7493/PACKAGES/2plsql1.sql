prompt plp2plsql
create or replace
package plp2plsql is
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/2plsql1.sql $
 *  $Author: vasiltsov $
 *  $Revision: 85998 $
 *  $Date:: 2015-11-13 12:30:42 #$
 */
--
	STR_PREC     constant varchar2(6)  := '('||constant.STR_PREC||')';
	NSTR_PREC    constant varchar2(6)  := '('||constant2.NSTR_PREC||')';
	REF_PREC     constant varchar2(6)  := '('||constant.REF_PREC||')';
	MEMO_PREC    constant varchar2(6)  := '('||constant.MEMO_PREC||')';
	NMEMO_PREC   constant varchar2(6)  := '('||constant2.NMEMO_PREC||')';
	BOOL_PREC    constant varchar2(6)  := '('||constant.BOOL_PREC||')';
    DECLARE_FORMAT_VARS  constant pls_integer := 0;
    DECLARE_FORMAT_LIST  constant pls_integer := 1;
    DECLARE_FORMAT_BLOCK constant pls_integer := 2;
--
    tmp_var_idx    pls_integer := 0;
    tmp_sos_idx    pls_integer := 0;
    tmp_expr_idx   pls_integer;
    ir_root        pls_integer;
    last_idx       pls_integer;
    lasttmp        varchar2(100);
    linfo_txt      varchar2(100);
    db_update      boolean default FALSE;
    db_context     boolean default FALSE;

    -- таблица, содержащая часть дерева разбора для колонки из select list PLPlus представления, идентифицируемая алиасом
    type select_crit_tree is table of varchar2(2000) index by varchar2(40);
    -- таблица, содержащая список колонок из select list, идентифицируемая идентификатором представления
    type table_crit_tree is table of select_crit_tree index by varchar2(40);
    t_crit_tree table_crit_tree;

    -- переменная = true, если мы компилируем базовое представление или расширение в режиме
    -- сохранения в узлах дерева разбора значений [ТАБЛИЦА].[ЗНАЧЕНИЕ], иначе = false
    crit_extension boolean default false;
--
    procedure init(p_java boolean);
    procedure init_counters(p_calls pls_integer default null,p_pipe varchar2 default null);
    procedure dump_counters(p_reset boolean default true);
    procedure inc_counter(p_typ pls_integer);
--
    function class2plsql ( p_class IN varchar2,
                           p_prec  IN boolean default TRUE,
                           p_idx   IN pls_integer default null,
                           p_row   IN boolean default FALSE
                         ) return varchar2;
    function get_ref_class(p_idx pls_integer) return varchar2;
    function is_variable(p_idx pls_integer) return boolean;
    function rtl_calc(p_func varchar2) return boolean;
--
    procedure ir2plsql ( p_idx  IN     pls_integer,
                         p_l    IN     pls_integer,
                         p_text in out nocopy plib.string_tbl_t
                     );
--
    function  expr2plsql ( p_idx   IN     pls_integer,
                           p_decl  in out nocopy varchar2,
                           p_prog  in out nocopy varchar2,
                           p_text  in out nocopy varchar2,
                           p_mgn   IN     varchar2 default NULL,
                           p_wipe  IN     boolean  default FALSE,
                           p_calc  IN     boolean  default TRUE,
                           p_bool  IN     boolean  default FALSE
                         ) return boolean;
--
    function  var2plsql ( p_idx    IN     pls_integer,
                          p_decl   in out nocopy varchar2,
                          p_prog   in out nocopy varchar2,
                          p_text   in out nocopy varchar2,
                          p_rvalue IN     varchar2 default NULL,
                          p_mgn    IN     varchar2 default NULL,
                          p_calc   IN     boolean  default TRUE,
                          p_bool   IN     boolean  default FALSE,
                          p_index  IN     boolean  default TRUE
                        ) return boolean;
--
    function  get_tmpvar ( p_idx pls_integer ) return varchar2;
    function  tmpvar( p_decl pls_integer,
                      p_name varchar2 default NULL,
                      p_text varchar2 default NULL,
                      p_type pls_integer default NULL
                    ) return boolean;
    procedure tmpvaredit ( p_idx pls_integer,
                           p_name varchar2,
                           p_text varchar2 default NULL,
                           p_type pls_integer default NULL
                           );
    procedure set_const_var ( p_const varchar2, p_idx in out nocopy pls_integer );
    procedure fill_overlapped( overlapped in out nocopy plib.string_rec_tbl_t,
                               p_idx pls_integer, p_sig varchar2, p_src_sig varchar2, p_getid boolean);
--
    function construct_cursor_text ( p_x      IN     varchar2,      -- set object prefix
                                     p_name   IN     varchar2,      -- cursor name
                                     p_select IN     pls_integer,   -- select list index
                                     p_set    IN     pls_integer,   -- base class/collection
                                     p_into   IN     pls_integer,   -- into list index
                                     p_where  IN     pls_integer,   -- where condition
                                     p_having IN     pls_integer,   -- having condition
                                     p_group  IN     pls_integer,   -- group by list index
                                     p_order  IN     pls_integer,   -- order by list index
                                     p_l      IN     pls_integer,   -- text indent
                                     p_all    IN     pls_integer,   -- all condition (lock)
                                     p_locks  in out nocopy pls_integer,   -- lock list index
                                     p_cursor in out nocopy pls_integer,
                                     p_decl   in out nocopy varchar2,         -- declarations
                                     p_text   in out nocopy varchar2,         -- p_prog
                                     str      in out nocopy varchar2,         -- select body
                                     p_hints  IN     varchar2 default NULL,
                                     p_dist   IN     varchar2 default NULL,
                                     p_wipe   IN     boolean  default TRUE
                                    ) return pls_integer; -- number of joined tables
--
    function  query2plsql (  p_idx  IN pls_integer,
                             p_decl in out nocopy varchar2,
                             p_prog in out nocopy varchar2,
                             p_text in out nocopy varchar2,
                             p_locks   out pls_integer,
                             p_wipe IN boolean  default false,
                             hints  IN varchar2 default null,
                             p_l    IN pls_integer default 0
                           ) return pls_integer;
--
    function collect_hints ( p_idx IN pls_integer, p_child boolean default false ) return varchar2;
    function check_alias ( p_alias varchar2,
                           p_als   in out nocopy plib.string_tbl_t,
                           p_idx pls_integer
                         ) return varchar2;
    function criteria2plsql( p_cr_id varchar2,
                             p_text  in out nocopy varchar2,
                             p_from  in out nocopy varchar2,
                             p_where in out nocopy varchar2,
                             p_next  in out nocopy varchar2
                           ) return pls_integer;
--
end plp2plsql;
/
show errors

