prompt method
create or replace
package method is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Method1.sql $
 *  $Author: VKazakov $
 *  $Revision: 43174 $
 *  $Date:: 2014-03-12 17:30:21 #$
 */
-- text types
	PLSQL_TEXT	constant integer := 0;
	PLPLUS_TEXT	constant integer := 1;
	JAVA_TEXT	constant integer := 2;
----------------------------------------------------------------------
    PARAMETERS_SECTION   constant varchar2(12) := 'PARAMS';
    PUBLIC_VARS_SECTION  constant varchar2(12) := 'PUBLIC_VARS';
    PUBLIC_SECTION       constant varchar2(12) := 'PUBLIC';
    PRIVATE_SECTION      constant varchar2(12) := 'PRIVATE';
    VALIDATE_SECTION     constant varchar2(12) := 'VALIDATE';
    VALIDATE_SYS_SECTION constant varchar2(12) := 'VALIDSYS';
    EXECUTE_SECTION      constant varchar2(12) := 'EXECUTE';
    EXECUTE_SYS_SECTION  constant varchar2(12) := 'EXECUTESYS';
    PACK_PREFIX  constant varchar2(2) := 'Z$';
    ARCH_PREFIX  constant varchar2(2) := 'Z_';
----------------------------------------------------------------------
    STANDALONE_EXTENSION_PROPERTY constant varchar2(30) := 'STANDALONE_EXTENSION';
    EXT_V2_OPTION constant varchar2(30) := 'CORE.PLP.EXT.V2';

    type method_ref_t is record (
            id          varchar2(16),
            class_id    varchar2(20),
            short_name  varchar2(40)
                                );
    type methods_cursor_t is ref cursor return method_ref_t;
    type method_ref_tbl_t is table of method_ref_t index by binary_integer;
----------------------------------------------------------------------
    function class_signature ( p_class_id varchar2, p_base varchar2, p_upclass boolean) return varchar2 deterministic;
    function method_signature( p_method_id varchar2, p_flags varchar2, p_result varchar2,
                               p_parname boolean, p_upclass boolean ) return varchar2 deterministic;
    function rtl_signature ( p_method_id varchar2, p_flags varchar2, p_class varchar2,
                             p_parname boolean, p_upclass boolean ) return varchar2 deterministic;
    function get_method_hash ( method_id varchar2,
                               method_sname varchar2,
                               method_flags varchar2 default null,
                               method_class varchar2 default null,
                               method_result varchar2 default null
                             ) return varchar2;
    function make_pack_name ( p_class_id varchar2, p_short_name varchar2,
                              p_id    varchar2 default null,
                              p_arch  varchar2 default null
                            ) return varchar2;
    pragma RESTRICT_REFERENCES ( make_pack_name, WNDS, WNPS );
    function make_proc_name ( p_short_name IN varchar2, -- methods.short_name%type
                              p_validate   IN boolean  default false,
                              p_prefix     IN varchar2 default null
                            ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( make_proc_name, WNDS, WNPS );
    function conv_pack_name ( p_name varchar2, p_arch  boolean) return varchar2;
    pragma RESTRICT_REFERENCES ( conv_pack_name, WNDS, WNPS );
----------------------------------------------------------------------
    procedure set_source ( p_name    IN varchar2,
                           p_section IN varchar2,
                           p_text    IN varchar2,
                           p_last    IN boolean default true );
	function  get_source ( p_name    IN varchar2, --sources.name%type,
	                       p_section IN varchar2  --sources.type%type
						 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_source, TRUST, WNDS, WNPS );
    function get_source_line return integer deterministic;
    pragma RESTRICT_REFERENCES ( get_source_line, WNDS, WNPS );
	function add_brackets ( p_str IN varchar2,
	                        p_skip_first IN boolean default FALSE
						  ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( add_brackets, WNDS, WNPS );
    function  gather_plplus_text ( p_method_id IN varchar2 ) return varchar2 deterministic;
    function  custom_gather_plplus_text ( p_method_id IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( gather_plplus_text, TRUST, WNDS, WNPS );
    procedure gather_plplus_text ( p_method_id IN varchar2, p_text in out nocopy constant.STRING_TABLE );
    pragma RESTRICT_REFERENCES ( gather_plplus_text, TRUST, WNDS, WNPS );
    function get_plplus_gather_idx return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( get_plplus_gather_idx, WNDS, WNPS );
----------------------------------------------------------------------
    procedure set_owner(p_name in out nocopy varchar2,p_owner in out nocopy varchar2,p_def_owner varchar2);
    pragma RESTRICT_REFERENCES ( set_owner, WNDS, WNPS, RNDS, RNPS );
    function get_user_source_line return integer deterministic;
    pragma RESTRICT_REFERENCES ( get_user_source_line, WNDS, WNPS );
    function get_user_source ( p_name    IN varchar2,
                               p_type    IN varchar2 default NULL,
                               p_owner   IN varchar2 default NULL,
                               comments  IN varchar2 default NULL
                             ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_user_source, WNDS, TRUST );
    function  get_obj_status ( p_name   IN varchar2,
                               p_type   IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_obj_status, WNDS, WNPS );
    function  get_view_deps  ( p_name   IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_view_deps, WNDS, WNPS );
    function get_errors ( p_name    IN varchar2,
                          p_type    IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_errors, WNDS, WNPS );
    function get_tablespaces(p_status varchar2 default NULL) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_tablespaces, WNDS, WNPS );
    function check_index ( p_name  IN varchar2,
                           p_table IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( check_index, WNDS, WNPS );
    function get_constraint_type ( p_name  IN varchar2,
                                   p_table IN varchar2 ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_constraint_type, WNDS, WNPS );
    procedure get_storage ( tablespace_name OUT varchar2,
                            ini_trans       OUT number,
                            max_trans       OUT number,
                            initial_extent  OUT number,
                            next_extent     OUT number,
                            min_extents     OUT number,
                            max_extents     OUT number,
                            pct_increase    OUT number,
                            pct_free        OUT number,
                            pct_used        OUT number,
                            p_name    IN varchar2,
                            p_type    IN varchar2 default NULL);
    procedure set_storage ( ini_trans       IN number,
                            max_trans       IN number,
                            next_extent     IN number,
                            min_extents     IN number,
                            max_extents     IN number,
                            pct_increase    IN number,
                            pct_free        IN number,
                            pct_used        IN number,
                            p_name    IN varchar2,
                            p_type    IN varchar2 default NULL);
    procedure kill_session (p_session IN varchar2);
    procedure alter_compile(p_name    IN varchar2,
                            p_type    IN varchar2 default NULL);
    procedure Select_Cursor (CURSOR_NAME IN varchar2, P_CURSOR in out nocopy constant.REPORT_CURSOR);
    function  Get_Sql_Text  (V_SID IN number) return varchar2;
----------------------------------------------------------------------
    function  find_string(p_search varchar2,p_str1 varchar2,p_str2 varchar2,p_str3 varchar2,p_case varchar2 default null) return number;
    pragma RESTRICT_REFERENCES ( find_string, WNDS, WNPS );
    procedure update_sources(p_search  varchar2, p_replace varchar2,
                             p_comment varchar2 default null,
                             p_status  varchar2 default NULL,
                             p_method_id   varchar2 default NULL,
                             p_commit      boolean  default TRUE);
    function  change_short_name(p_method_id     IN varchar2,
                                p_short_name    IN varchar2,
                                p_compile       IN boolean default TRUE,
                                p_error         IN boolean default FALSE,
                                p_update_src    IN boolean default NULL
                               ) return integer;
    procedure check_parameters( p_form_id varchar2, p_method varchar2 default null,
                                p_compile boolean := false, p_binds varchar2 := '0' );
    function  correct_check_method( p_id varchar2, p_compile boolean := false ) return integer;
    procedure check_extension(p_ext_id varchar2,p_src_id varchar2,p_all varchar2 default null);
    procedure check_trigger_method( p_id varchar2 );
    function  form_referencing ( p_form_id varchar2, p_cnt number default null ) return integer deterministic;
    pragma RESTRICT_REFERENCES ( form_referencing, WNDS, WNPS );
    function  trans_referencing( p_class varchar2, p_short_name varchar2 ) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( trans_referencing, WNDS, WNPS );
    function  check_trans_method(p_id varchar2, p_class varchar2 default null, p_short_name varchar2 default null) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( check_trans_method, WNDS, WNPS );
    function  check_transitions( p_class varchar2, p_short_name varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( check_transitions, WNDS, WNPS );
----------------------------------------------------------------------
    function generate ( p_method_id     IN varchar2,
                        p_in_text_type  IN pls_integer  default null,
                        p_out_text_type IN pls_integer  default null,
                        p_recompile     IN boolean  default TRUE,
                        p_short_name    IN varchar2 default NULL,
                        p_update_src    IN boolean  default NULL
	              	  ) return integer;
    function drop_method ( p_method_id IN varchar2,
                           p_in_text_type  IN pls_integer default null,
                           p_out_text_type IN pls_integer default null,
                           p_recompile     IN boolean default TRUE
                         ) return integer;
    function generate_view ( p_text in out nocopy varchar2,
                             p_err_text out varchar2,
                             p_crit_id  varchar2 default null,
                             p_archmode boolean  default null
                           ) return integer;
----------------------------------------------------------------------
    procedure delete_java_source ( p_id varchar2, p_type varchar2);
    procedure set_java_source ( p_id   varchar2, p_type varchar2, p_module varchar2,
                                p_text in out nocopy plib.java_code_tbl_t);
    function gen_java ( p_method_id     IN varchar2,
                        p_recompile     IN boolean  default TRUE
                      ) return integer;
    procedure set_def_target(p_out_text_type IN pls_integer default PLSQL_TEXT);
    function get_def_target return pls_integer;
    function get_target(p_method_id in varchar2) return integer;
    function get_available_target return integer;
----------------------------------------------------------------------
    function recompile ( p_method_id IN varchar2,
                         p_recompile IN boolean default TRUE,
                         p_out_text_type IN pls_integer default null
                        ) return integer;
    procedure recompile ( p_method_id IN varchar2,
                          p_recompile IN boolean default TRUE,
                          p_error     IN boolean default TRUE,
                          p_out_text_type IN pls_integer default null
                        );
    procedure compile_parent ( p_method_sname  IN varchar2,
                               p_method_class  IN varchar2,
                               p_in_text_type  IN pls_integer default null,
                               p_out_text_type IN pls_integer default null,
                               from_parent     IN boolean default FALSE,
                               p_compile       IN boolean default TRUE,
                               p_commit        IN boolean default TRUE
                             );
    procedure compile_referenced( p_method_id     IN varchar2,
                                  p_in_text_type  IN pls_integer default null,
                                  p_out_text_type IN pls_integer default null,
                                  p_self          IN boolean default TRUE,
                                  p_compile       IN boolean default TRUE,
                                  p_commit        IN boolean default TRUE
                                );
    procedure compile_referencing( p_method_id     IN varchar2,
                                   p_in_text_type  IN pls_integer  default null,
                                   p_out_text_type IN pls_integer  default null,
                                   p_self          IN boolean  default TRUE,
                                   p_compile       IN boolean  default TRUE,
                                   p_old_sname     IN varchar2 default NULL,
                                   p_new_sname     IN varchar2 default NULL,
                                   p_update_src    IN boolean  default NULL,
                                   p_commit        IN boolean  default TRUE
                                 );
    procedure compile_dependence( p_class_id    IN  varchar2,
                                  p_qual        IN  varchar2,
                                  p_type        IN  varchar2 default NULL,
                                  p_compile     IN  boolean  default TRUE,
                                  p_error       IN  boolean  default TRUE,
                                  p_new_qual    IN  varchar2 default NULL,
                                  p_update_src  IN  boolean  default NULL,
                                  p_commit      IN  boolean  default TRUE
                                  );
    procedure compile_criteria_refcing_class(p_class_id varchar2, p_pipe_name varchar2);
    function  check_stop_flag(p_pipe varchar2 default null) return boolean;
    procedure set_stop_flag(p_pipe varchar2 default null);
----------------------------------------------------------------------
    function  normalize_properties(p_prop in varchar2, p_skip varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( normalize_properties, WNDS, WNPS );
    function  extract_property(p_string   in varchar2,
                               p_property in varchar2 default NULL) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( extract_property, WNDS, WNPS );
    procedure put_property(p_string in out nocopy varchar2,
                       p_property  in varchar2 default null,
                       p_value  in varchar2 default null);
    pragma RESTRICT_REFERENCES ( put_property, WNDS, WNPS );
    function  get_property(p_method_id in varchar2,
                           p_property  in varchar2 default null) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( get_property, WNDS, WNPS );
    procedure set_property(p_method_id in varchar2,
                           p_property  in varchar2 default null,
                           p_value  in varchar2 default null);
    function get_rtl_idx ( p_idx pls_integer default null) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( get_rtl_idx, WNDS, WNPS );
    procedure rebuild_rtlbase;
----------------------------------------------------------------------
	procedure add_depends ( p_refced   IN varchar2,
						    p_type     IN varchar2,
						    p_qual     IN varchar2 default null,
						    p_clear    IN varchar2 default null
						  );
    procedure write_dependencies(p_refcing varchar2, p_type varchar2);
----------------------------------------------------------------------
    procedure meth_errors ( p_method_id IN varchar2,
                            p_warn      IN boolean  default FALSE,
                            p_title     IN boolean  default FALSE,
                            p_dir       IN varchar2 default NULL );
    function  meth_errors ( p_method_id IN varchar2,
                            p_warn      IN boolean  default FALSE,
                            p_title     IN boolean  default TRUE
                          ) return varchar2 deterministic;
    pragma RESTRICT_REFERENCES ( meth_errors, WNDS, WNPS );
----------------------------------------------------------------------
    function hash_id(p_id varchar2) return pls_integer deterministic;
    pragma RESTRICT_REFERENCES ( hash_id, WNDS, WNPS );
    procedure clear_method_list;
    function  add_method_id(p_id varchar2) return pls_integer;
    procedure add_method_list(p_list    in varchar2,
                              p_clear   in boolean  default true,
                              p_char    in varchar2 default null);
    procedure add_method_cursor(p_cursor  in out nocopy methods_cursor_t,
                                p_clear   in boolean default false);
    procedure process_methods(p_pipe    in varchar2 default null,
                              p_compile in boolean  default true,
                              p_sort    in boolean  default true,
                              p_mode    in boolean  default false);
    procedure compile_methods(p_cursor  in out nocopy methods_cursor_t,
                              p_pipe    in varchar2 default null,
                              p_compile in boolean  default false,
                              p_sort    in boolean  default true,
                              p_mode    in boolean  default false);
    procedure compile_status( p_status  in varchar2 default 'UPDATED',
                              p_pipe    in varchar2 default 'COMPILE$',
                              p_compile in boolean  default true,
                              p_noflags in varchar2 default null,
                              p_mode    in boolean  default false);
    procedure process_plsql ( p_pipe    in varchar2 default null );
    function  get_method_list(p_idx    in out nocopy pls_integer,
                              p_clear  in boolean default true) return varchar2;
    procedure get_method_buf(p_tbl in out nocopy class_utils.id_tab);
    procedure process_pipe(p_pipe    in varchar2,
                           p_method  in boolean  default true,
                           p_compile in boolean  default false,
                           p_mode    in boolean  default false);
----------------------------------------------------------------------
    function get_object_list(p_list  varchar2,
                             p_obj_tbl in out nocopy rtl.reference_table,
                             p_cls_tbl in out nocopy rtl.refstring_table,
                             p_class varchar2 default NULL
                            ) return boolean;
    function check_method_rights( p_obj_tbl in rtl.reference_table,
                                  p_cls_tbl in rtl.refstring_table,
                                  p_User    in varchar2,
                                  p_Method  in varchar2,
                                  p_Access  in varchar2 default NULL
                                ) return boolean;
    function check_object_rights( p_obj_tbl in rtl.reference_table,
                                  p_User    in varchar2,
                                  p_Method  in varchar2,
                                  p_Access  in varchar2 default NULL,
                                  p_Class   in varchar2 default NULL,
                                  m_ACCESS  in number   default -1,
                                  p_Belong  in varchar2 default NULL
                                 )return boolean;
----------------------------------------------------------------------
    procedure translate_crit_formula(p_formula in out nocopy varchar2,
                                     p_crit_id in out nocopy varchar2,
                                     p_crit_class_id in out nocopy varchar2);
    procedure check_method_parameters(inserting boolean, deleting boolean,
                                      p_old method_parameters%rowtype,
                                      p_new method_parameters%rowtype);
    procedure check_method_variables (inserting boolean, deleting boolean,
                                      p_old method_variables%rowtype,
                                      p_new method_variables%rowtype);
    procedure check_methods(inserting boolean, deleting boolean,
                            p_old methods%rowtype,
                            p_new methods%rowtype);
----------------------------------------------------------------------
    -- creating synonym for method
	procedure set_synonym(amethod_id in varchar2, asynonym_name in varchar2);
    -- creating synonyms for report p_method_id (for all users from dependencies in report_objects)
    procedure CreateSynonyms(p_method_id varchar2);
    -- creating synonyms for reports having references in report_objects on object p_name/p_type
    procedure Create_Ref_Synonyms(p_name varchar2,p_type varchar2);
----------------------------------------------------------------------
	/* Возвращает версию пакета */
	function get_version return varchar2;
end method;
/
show errors
