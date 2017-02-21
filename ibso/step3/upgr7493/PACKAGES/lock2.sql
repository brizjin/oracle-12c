prompt lock_info body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/lock2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
lock_info is
--
function  rtl_node  return number is
begin
    return rtl.rtl0;
end;
--
function  rtl_nodes return number is
begin
    return rtl.rtl_nodes;
end;
--
procedure read(p_wait number default 0) is
begin
    rtl.read(p_wait);
end;
--
procedure clear(p_all   boolean default FALSE,
                p_user_id pls_integer default NULL) is
begin
    rtl.lock_clear(p_all,p_user_id);
end;
--
procedure close(p_user_id pls_integer default NULL) is
begin
    rtl.close(p_user_id);
end;
--
procedure touch(p_user_id pls_integer default NULL) is
begin
    rtl.lock_touch(p_user_id);
end;
--
function  read_answer(p_wait number default 1,
                      p_get  boolean default true) return boolean is
begin
    return rtl.read_answer(p_wait,p_get);
end;
--
function submit_job( p_submit in out nocopy boolean, p_commit  boolean default true ) return varchar2 is
begin
    return rtl.submit_job(p_submit,p_commit);
end;
--
function open(p_name varchar2 default NULL,
              p_info varchar2 default NULL,
              p_user_id pls_integer default NULL,
              p_commit  boolean default true
             ) return pls_integer is
begin
    return rtl.open(p_name,p_info,p_user_id,p_commit);
end;
--
function  hold ( p_hold boolean, p_instance pls_integer default null, p_node pls_integer default null ) return varchar2 is
begin
    return rtl.lock_hold(p_hold,p_instance,p_node);
end;
--
function  session_exists(p_uid pls_integer, p_sid pls_integer) return boolean  is
begin
    return rtl.session_exists(p_uid,p_sid);
end;
--
function  session_status(p_uid pls_integer, p_sid pls_integer) return varchar2 is
begin
    return rtl.session_status(p_uid,p_sid);
end;
--
function  init_user(p_user in out nocopy users_info) return boolean is
begin
    return rtl.init_user(p_user);
end;
--
procedure check_obj(p_object varchar2, p_get boolean default true, p_class varchar2 default null) is
begin
    rtl.check_obj(p_object, p_get, p_class);
end;
--
procedure set_ids(p_id type_number_table, p_frm boolean default false) is
begin
    rtl.set_ids(p_id,p_frm);
end;
--
procedure set_ids(p_id type_refstring_table, p_frm boolean default false) is
begin
    rtl.set_ids(p_id,p_frm);
end;
--
procedure set_ids(p_id rtl.refstring_table, p_frm boolean default false) is
begin
    rtl.set_ids(p_id,p_frm);
end;
--
function fill_ids(p_list varchar2, p_frm boolean default false) return boolean is
begin
    return rtl.fill_ids(p_list,p_frm);
end;
--
procedure put(p_object  varchar2,
              p_subject varchar2 default NULL,
              p_info    varchar2 default NULL,
              p_user_id pls_integer default NULL) is
begin
    rtl.lock_put(p_object,p_subject,p_info,p_user_id);
end;
--
procedure put_get(p_object  varchar2,
                  p_subject varchar2 default NULL,
                  p_info    varchar2 default NULL) is
begin
    rtl.lock_put_get(p_object,p_subject,p_info);
end;
--
procedure put_push(p_object  varchar2,
                   p_subject varchar2 default NULL,
                   p_info    varchar2 default NULL) is
begin
    rtl.lock_put_push(p_object,p_subject,p_info);
end;
--
procedure get(p_object  varchar2,
              p_subject varchar2 default NULL) is
begin
    rtl.lock_get(p_object,p_subject);
end;
--
procedure get_push(p_object  varchar2,
                   p_subject varchar2 default NULL) is
begin
    rtl.lock_get_push(p_object,p_subject);
end;
--
procedure del(p_object  varchar2,
              p_subject varchar2 default NULL) is
begin
    rtl.lock_del(p_object,p_subject);
end;
--
function get_info( p_object  in out nocopy varchar2,
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
                 ) return boolean is
begin
    return rtl.get_info(p_object,p_subject,l_info,l_time,l_user,
                        u_ses,os_user,ora_user,username,u_info,p_wait);
end;
--
function info( l_info in out nocopy locks_info,
               u_info in out nocopy users_info
             ) return boolean is
begin
    return rtl.lock_info(l_info,u_info);
end;
--
function get_user_info( u_info in out nocopy users_info,
                        u_idx  pls_integer default null,
                        u_sid  pls_integer default null,
                        p_init boolean  default true
                       ) return boolean is
begin
    return rtl.get_user_info(u_info,u_idx,u_sid,p_init);
end;
--
function get_lock_info( l_info in out nocopy locks_info,
                        l_idx  pls_integer default null
                       ) return boolean is
begin
    return rtl.get_lock_info(l_info,l_idx);
end;
--
function get_user_list( p_users  in out nocopy users_tbl,
                        ora_user varchar2 default null,
                        p_init   boolean  default true
                      ) return boolean is
begin
    return rtl.get_user_list(p_users,ora_user,p_init);
end;
--
function get_lock_list( p_locks in out nocopy locks_tbl,
                        p_user_id   pls_integer default NULL,
                        p_time      date default NULL,
                        p_subject   varchar2 default NULL,
                        p_user_sid  pls_integer default NULL
                      ) return boolean is
begin
    return rtl.get_lock_list(p_locks,p_user_id,p_time,p_subject,p_user_sid);
end;
--
function get_lock_list( p_locks in out nocopy locks_tbl,
                        p_user  users_info default NULL,
                        p_time  date default NULL,
                        p_subject   varchar2 default NULL
                      ) return boolean is
begin
    return rtl.get_lock_list(p_locks,p_user,p_time,p_subject);
end;
--
procedure refresh(p_instance pls_integer default null, p_node pls_integer default null) is
begin
    rtl.lock_refresh(p_instance,p_node);
end;
--
procedure flash  (p_instance pls_integer default null, p_node pls_integer default null) is
begin
    rtl.lock_flash(p_instance,p_node);
end;
--
procedure stop(p_instance pls_integer default null, p_node pls_integer default null, p_mode pls_integer default null) is
begin
    rtl.lock_stop(p_instance,p_node,p_mode);
end;
--
procedure run is
begin
    rtl.lock_run;
end;
--
procedure clear_stack is
begin
    rtl.clear_stack;
end;
--
procedure push_info is
begin
    rtl.push_info;
end;
--
function  pop_info return boolean is
begin
    return rtl.pop_info;
end;
--
function  stack_info(p_idx pls_integer default 0) return boolean is
begin
    return rtl.stack_info(p_idx);
end;
--
function  info_active return boolean is
begin
    return rtl.info_active;
end;
--
function  info_open   return boolean is
begin
    return rtl.info_open;
end;
--
function  server_test (p_instance pls_integer default null, p_node pls_integer default null) return boolean is
begin
    return rtl.server_test(p_instance,p_node);
end;
--
function  request(p_object  varchar2,
                  p_info    varchar2 default NULL,
                  p_wait    number   default NULL,
                  p_class   varchar2 default NULL
                 ) return varchar2 is
begin
    return rtl.lock_request(p_object,p_info,p_wait,p_class);
end;
--
function  get_lock(p_lock in out nocopy locks_info, p_object varchar2) return boolean is
begin
    return rtl.get_lock(p_lock,p_object);
end;
--
function  get_user_locks( p_locks in out nocopy locks_tbl,
                          p_user_id   pls_integer default NULL,
                          p_time      date default NULL
                        ) return boolean is
begin
    return rtl.get_user_locks(p_locks,p_user_id,p_time);
end;
--
function  clear_locks( p_object  varchar2,
                       p_user_id pls_integer default null,
                       p_nowait  boolean default false
                     ) return pls_integer is
begin
    return rtl.clear_locks(p_object,p_user_id,p_nowait);
end;
--
function  request_lock( p_object  varchar2,
                        p_class   varchar2,
                        p_info    varchar2 default NULL
                      ) return varchar2 is
begin
    return rtl.request_lock(p_object,p_class,p_info);
end;
--
function  object_scn( p_object  varchar2,
                      p_class   varchar2
                    ) return number is
begin
    return rtl.object_scn(p_object,p_class);
end;
--
procedure check_lock(p_object varchar2, p_class varchar2) is
begin
    rtl.check_lock(p_object,p_class);
end;
--
procedure get_v$lock(p_id1 in out nocopy pls_integer, p_id2 in out nocopy pls_integer, p_sid pls_integer,
                     p_typ varchar2 default null, p_req boolean default null) is
begin
    rtl.get_v$lock(p_id1,p_id2,p_sid,nvl(p_typ,'TX'),p_req);
end;
--
function  get_v$lock_user(p_user in out nocopy users_info,
                          p_id1  pls_integer, p_id2 pls_integer,
                          p_typ  varchar2 default null) return pls_integer is
begin
    return rtl.get_v$lock_user(p_user,p_id1,p_id2,p_typ);
end;
--
end lock_info;
/
show errors package body lock_info

