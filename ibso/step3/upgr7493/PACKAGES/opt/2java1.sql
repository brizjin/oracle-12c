prompt  package plp2java
create or replace
package plp2java is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/2java1.sql $
 *  $Author: VKazakov $
 *  $Revision: 44837 $
 *  $Date:: 2014-04-17 13:19:10 #$
 */
--
    subtype code_tbl_t is plib.java_code_tbl_t;
--
    function get_version return varchar2;
--
    function var4sql (p_idx    IN     pls_integer,
                      p_decl   in out nocopy varchar2,
                      p_prog   in out nocopy varchar2,
                      p_text   in out nocopy varchar2,
                      p_mgn    IN     varchar2,
                      p_calc   IN     boolean,
                      p_index  IN     boolean
                    ) return boolean;
--
    procedure ir2java (
                p_idx  IN     pls_integer,
                p_l    IN     pls_integer,
                p_text in out nocopy code_tbl_t
    );
--
    procedure put_cache_flush(p_text in out nocopy varchar2, p_mgn varchar2);
    procedure put_save_this(p_text in out nocopy varchar2, p_mgn varchar2);
    function  check_save return boolean;
--
    function  add_bind(p_tmpidx in out nocopy pls_integer,
                       p_name   varchar2, p_type plib.plp_class_t,
                       p_value  varchar2, p_find boolean, p_conv pls_integer) return varchar2;
    function  add$bind(p_tmpidx in out nocopy pls_integer, p_prog in out nocopy varchar2,
                       p_name   varchar2, p_type plib.plp_class_t,
                       p_value  varchar2, p_find boolean, p_mgn varchar2) return varchar2;
    procedure add_sync(p_class varchar2, p_cached boolean);
    procedure add_cursor_used(p_cursor pls_integer);
            
    function gen_DAO return boolean;
    procedure take_tbls_in_request(p_tbls_in_request varchar2);
    
    function  dbclass2java( p_class  varchar2,
                            p_kernel boolean,
                            p_mgn    varchar2,
                            p_idx    pls_integer,
                            p_all    pls_integer,
                            objid    in out nocopy varchar2,
                            edecl    in out nocopy varchar2,
                            etext    in out nocopy varchar2,
                            tmpprog  in out nocopy varchar2,
                            tmpidx   in out nocopy pls_integer,
                            p_gen_calc_id boolean default false
                          ) return boolean;
    function check_java_supported(p_method varchar2, p_name varchar2, p_type varchar2, p_features varchar2) return pls_integer;
--
    procedure get_imports(p_buf in out nocopy plib.java_code_tbl_t,p_check_buf boolean default true);

end plp2java;
/
sho err

