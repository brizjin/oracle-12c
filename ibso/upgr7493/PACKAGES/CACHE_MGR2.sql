prompt cache_mgr body
create or replace package body
 /*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/CACHE_MGR2.sql $
 *  $Author: sasa $
 *  $Revision: 50609 $
 *  $Date:: 2014-08-27 16:44:23 #$
 */
cache_mgr is
--
function Hash_Id(p_num number) return pls_integer is
begin
    return cache_service.Hash_Id(p_num);
end;
--
function Hash_Id(p_str varchar2) return pls_integer is
begin
    return cache_service.Hash_Id(p_str);
end;
--
function Hash_Str(p_str varchar2) return pls_integer is
begin
    return cache_service.Hash_Str(p_str);
end;
--
function get_commit_disabled return boolean is
begin   
    return cache_service.get_commit_disabled;
end;
--
procedure set_commit_disabled(p_disable boolean) is
begin
    cache_service.set_commit_disabled(p_disable);
end;
--
procedure check_commit(p_commit_msg boolean default true) is
begin
    cache_service.check_commit(p_commit_msg);
end;
--
procedure cache_commit(p_autonom boolean default false) is
begin
    cache_service.cache_commit(p_autonom);
end;
--
procedure cache_set_savepoint(savepointname varchar2) is
begin
    cache_service.cache_set_savepoint(savepointname);
end;
--
procedure cache_rollback(savepointname varchar2 default null,p_autonom boolean default false) is
begin
    cache_service.cache_rollback(savepointname, p_autonom);
end;
--
procedure reg_obj_change(class_id varchar2, obj_id varchar2, cascade boolean) is
begin
    cache_service.reg_obj_change(class_id, obj_id, cascade);
end;
--
procedure reg_change(class_id varchar2, cascade boolean) is
begin
    cache_service.reg_change(class_id, cascade);
end;
--
procedure reg_event(p_code pls_integer, p_event varchar2, p_pipe varchar2 default null) is
begin
    cache_service.reg_event(p_code, p_event, p_pipe);
end;
--
procedure reg_clear (p_code pls_integer default null) is
begin
    cache_service.reg_clear(p_code);
end;
--
procedure write_cache is
begin
    null;
end;
--
procedure cache_flush(info varchar2 default null) is
begin
    null;
end;
--
procedure cache_clear(info varchar2 default null) is
begin
    cache_service.cache_clear(info);
end;
--
procedure cache_refresh_class(classId varchar2) is
begin
    null;
end;
--
procedure cache_refresh(id number) is
begin
    null;
end;
--
procedure cache_refresh(id varchar2) is
begin
    null;
end;
--
procedure lru_touch(idx varchar2, lru_list in out nocopy lru_list_t) is
begin
    cache_service.lru_touch(idx, lru_list);
end;
--
function lru_remove(lru_list in out nocopy lru_list_t) return varchar2 is
begin
    return cache_service.lru_remove(lru_list);
end;
--
procedure lru_remove(idx varchar2, lru_list in out nocopy lru_list_t) is
begin
    cache_service.lru_remove(idx, lru_list);
end;
--
procedure lru_clear(lru_list in out nocopy lru_list_t) is
begin
    cache_service.lru_clear(lru_list);
end;
--
procedure reg_pipe_events (p_pipe varchar2, p_add boolean) is
begin
    cache_service.reg_pipe_events(p_pipe, p_add);
end;
--
procedure send_pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2) is
begin
    cache_service.send_pipe_events(p_pipe, p_code, p_event);
end;
--
procedure refresh_cache_pipes(p_init_classes boolean default null) is
begin
    cache_service.refresh_cache_pipes(p_init_classes);
end;
--
procedure cache_reset(p_class in varchar2, p_cascade boolean, p_id in varchar2) is
begin
    cache_service.cache_reset(p_class, p_cascade, p_id);
end;
--
end cache_mgr;
/
show err package body cache_mgr
