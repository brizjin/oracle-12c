prompt plp2java body
create or replace
package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/2java2.sql $
 *  $Author: VKazakov $
 *  $Revision: 44837 $
 *  $Date:: 2014-04-17 13:19:10 #$
*/
plp2java is
--
function get_version return varchar2 is
begin
    return null;
end;
--
procedure ir2java (
            p_idx  IN     pls_integer,
            p_l    IN     pls_integer,
            p_text in out nocopy code_tbl_t) is
begin
  p_text.delete;
  raise rtl.no_privileges;
end;
--
function var4sql (p_idx    IN     pls_integer,
                  p_decl   in out nocopy varchar2,
                  p_prog   in out nocopy varchar2,
                  p_text   in out nocopy varchar2,
                  p_mgn    IN     varchar2,
                  p_calc   IN     boolean,
                  p_index  IN     boolean
                ) return boolean is
begin
  raise rtl.no_privileges;
end;
--
procedure put_cache_flush(p_text in out nocopy varchar2, p_mgn varchar2) is
begin
  null;
end;
--
procedure put_save_this(p_text in out nocopy varchar2, p_mgn varchar2) is
begin
  null;
end;
--
function  check_save return boolean is
begin
  return false;
end;
--
function  add_bind(p_tmpidx in out nocopy pls_integer,
                   p_name   varchar2, p_type plib.plp_class_t,
                   p_value  varchar2, p_find boolean, p_conv pls_integer) return varchar2 is
begin
  raise rtl.no_privileges;
end;
--
function  add$bind(p_tmpidx in out nocopy pls_integer, p_prog in out nocopy varchar2,
                   p_name   varchar2, p_type plib.plp_class_t,
                   p_value  varchar2, p_find boolean, p_mgn varchar2) return varchar2 is
begin
  raise rtl.no_privileges;
end;
--
procedure add_sync(p_class varchar2, p_cached boolean) is
begin
  raise rtl.no_privileges;
end;
procedure add_cursor_used(p_cursor pls_integer) is
begin
  raise rtl.no_privileges;
end;
--
function gen_DAO return boolean is
begin
  raise rtl.no_privileges;
end;
procedure take_tbls_in_request(p_tbls_in_request varchar2) is
begin
  raise rtl.no_privileges;
end;
--
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
                      ) return boolean is
begin
  raise rtl.no_privileges;
end;
--

procedure get_imports(p_buf in out nocopy plib.java_code_tbl_t,p_check_buf boolean default true) is
begin
  p_buf.delete;	
  raise rtl.no_privileges;
end;
--

function check_java_supported(p_method varchar2, p_name varchar2, p_type varchar2, p_features varchar2) return pls_integer is
begin
	return 1;
end;	
--


end plp2java;
/
sho err package body plp2java

