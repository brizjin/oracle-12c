prompt lock_info
create or replace
package lock_info is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/lock1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--------------------------------------------------------------------
-- LOCK_INFO
subtype locks_info is rtl.locks_info;
subtype users_info is rtl.users_info;
subtype locks_tbl  is rtl.locks_tbl;
subtype users_tbl  is rtl.users_tbl;
--
    procedure run;
    procedure stop(p_instance pls_integer default null, p_node pls_integer default null, p_mode pls_integer default null);
--
    function  rtl_node  return number deterministic;
    pragma restrict_references ( rtl_node,  WNDS, WNPS );
    function  rtl_nodes return number deterministic;
    pragma restrict_references ( rtl_nodes, WNDS, WNPS );
--
    function  info_active return boolean;
    function  info_open   return boolean;
    function  server_test (p_instance pls_integer default null, p_node pls_integer default null) return boolean;
    procedure refresh(p_instance pls_integer default null, p_node pls_integer default null);
    procedure flash  (p_instance pls_integer default null, p_node pls_integer default null);
--
    function  open (p_name varchar2 default NULL,
                    p_info varchar2 default NULL,
                    p_user_id pls_integer default NULL,
                    p_commit  boolean default true
                   ) return pls_integer;
    procedure close(p_user_id pls_integer default NULL);
    procedure clear(p_all   boolean default FALSE,
                    p_user_id pls_integer default NULL);
    procedure touch(p_user_id pls_integer default null);
--
    procedure set_ids(p_id type_number_table, p_frm boolean default false);
    procedure set_ids(p_id type_refstring_table, p_frm boolean default false);
    procedure set_ids(p_id rtl.refstring_table, p_frm boolean default false);
    function  fill_ids(p_list varchar2, p_frm boolean default false) return boolean;
--
    procedure put(p_object  varchar2,
                  p_subject varchar2 default NULL,
                  p_info    varchar2 default NULL,
                  p_user_id pls_integer default NULL);
    procedure put_get( p_object  varchar2,
                       p_subject varchar2 default NULL,
                       p_info    varchar2 default NULL);
    procedure put_push(p_object  varchar2,
                       p_subject varchar2 default NULL,
                       p_info    varchar2 default NULL);
    procedure get(p_object  varchar2,
                  p_subject varchar2 default NULL);
    procedure get_push( p_object  varchar2,
                        p_subject varchar2 default NULL);
    procedure del(p_object  varchar2,
                  p_subject varchar2 default NULL);
--
    procedure check_obj(p_object  varchar2, p_get boolean default true, p_class varchar2 default null);
    procedure read(p_wait number default 0);
--
    function  read_answer(p_wait number default 1,
                          p_get  boolean default true) return boolean;
    function  info( l_info in out nocopy locks_info,
                    u_info in out nocopy users_info ) return boolean;
--
    function  get_info( p_object  in out nocopy varchar2,
                        p_subject in out nocopy varchar2,
                        l_info    out nocopy varchar2,
                        l_time    out nocopy date,
                        l_user    out nocopy varchar2,
                        u_ses     out nocopy varchar2,
                        os_user   out nocopy varchar2,
                        ora_user  out nocopy varchar2,
                        username  out nocopy varchar2,
                        u_info    out nocopy varchar2,
                        p_wait    number default 1
                      ) return boolean;
    function get_user_info( u_info in out nocopy users_info,
                            u_idx  pls_integer default null,
                            u_sid  pls_integer default null,
                            p_init boolean default true
                          ) return boolean;
    function get_lock_info( l_info in out nocopy locks_info,
                            l_idx  pls_integer default null
                          ) return boolean;
--
    function get_user_list( p_users  in out nocopy users_tbl,
                            ora_user varchar2 default null,
                            p_init   boolean  default true
                          ) return boolean;
    function get_lock_list( p_locks in out nocopy locks_tbl,
                            p_user_id   pls_integer default NULL,
                            p_time      date default NULL,
                            p_subject   varchar2 default NULL,
                            p_user_sid  pls_integer default NULL
                          ) return boolean;
    function get_lock_list( p_locks in out nocopy locks_tbl,
                            p_user  users_info default NULL,
                            p_time  date default NULL,
                            p_subject   varchar2 default NULL
                          ) return boolean;
--
    procedure clear_stack;
    procedure push_info;
    function  pop_info return boolean;
    function  stack_info(p_idx pls_integer default 0) return boolean;
--
    function  submit_job( p_submit in out nocopy  boolean, p_commit  boolean default true ) return varchar2;
    function  init_user ( p_user in out nocopy users_info ) return boolean;
    function  hold ( p_hold boolean, p_instance pls_integer default null, p_node pls_integer default null ) return varchar2;
    function  session_exists(p_uid pls_integer, p_sid pls_integer) return boolean;
    function  session_status(p_uid pls_integer, p_sid pls_integer) return varchar2;
--
    function  request(p_object  varchar2,
                      p_info    varchar2 default NULL,
                      p_wait    number   default NULL,
                      p_class   varchar2 default NULL
                     ) return varchar2;
--
    function  get_lock(p_lock in out nocopy locks_info, p_object varchar2) return boolean;
    function  get_user_locks( p_locks in out nocopy locks_tbl,
                              p_user_id   pls_integer default NULL,
                              p_time      date default NULL
                            ) return boolean;
    function  clear_locks( p_object  varchar2,
                           p_user_id pls_integer default null,
                           p_nowait  boolean default false
                         ) return pls_integer;
    function  request_lock( p_object  varchar2,
                            p_class   varchar2,
                            p_info    varchar2 default NULL
                          ) return varchar2;
    function  object_scn( p_object  varchar2,
                          p_class   varchar2
                        ) return number;
    procedure check_lock(p_object varchar2, p_class varchar2);
--
    procedure get_v$lock(p_id1 in out nocopy pls_integer, p_id2 in out nocopy pls_integer, p_sid pls_integer,
                         p_typ varchar2 default null, p_req boolean default null);
    function  get_v$lock_user(p_user in out nocopy users_info,
                              p_id1  pls_integer, p_id2 pls_integer,
                              p_typ  varchar2 default null) return pls_integer;
--
end lock_info;
/
show errors

