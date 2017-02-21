prompt cache_service
CREATE OR REPLACE
package cache_service as
/**
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/cache_service1.sql $
 *	$Author: sasa $
 *	$Revision: 55024 $
 *  $Date:: 2014-11-11 15:53:50 #$
 */

function get_version return varchar2;

function Hash_Id (p_num number  ) return pls_integer;
function Hash_Str(p_str varchar2) return pls_integer;
function Hash_Id (p_str varchar2) return pls_integer;

procedure reg_obj_change(class_id varchar2, obj_id varchar2, cascade boolean);
procedure reg_change(class_id varchar2, cascade boolean);
procedure reg_event (p_code pls_integer, p_event varchar2, p_pipe varchar2 default null);
procedure reg_clear (p_code pls_integer default null);

procedure cache_commit(p_autonom boolean default false);
procedure cache_set_savepoint(savepointname varchar2);
procedure cache_rollback(savepointname varchar2 default null,p_autonom boolean default false);

procedure write_cache;
procedure cache_flush(info varchar2 default null);
procedure cache_clear(info varchar2 default null);

procedure lru_touch(idx varchar2, lru_list in out nocopy cache_mgr.lru_list_t);
pragma restrict_references(lru_touch, WNDS, WNPS, RNDS, RNPS);

function lru_remove(lru_list in out nocopy cache_mgr.lru_list_t) return varchar2;
pragma restrict_references(lru_remove, WNDS, WNPS, RNDS, RNPS);

procedure lru_remove(idx varchar2, lru_list in out nocopy cache_mgr.lru_list_t);
pragma restrict_references(lru_remove, WNDS, WNPS, RNDS, RNPS);

procedure lru_clear(lru_list in out nocopy cache_mgr.lru_list_t);
pragma restrict_references(lru_clear, WNDS, WNPS, RNDS, RNPS);

procedure reg_pipe_events (p_pipe varchar2, p_add boolean);
pragma restrict_references(reg_pipe_events, WNDS, WNPS, TRUST);

procedure send_reset_cache_events;
procedure send_pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2);
procedure refresh_cache_pipes(p_init_classes boolean default null);

procedure set_commit_disabled(p_disable boolean);
function  get_commit_disabled return boolean;

procedure check_commit(p_commit_msg boolean default true);

/*
 * Сброс кэша для экземпляра или всего ТБП
 * @param p_class - класс экземпляра
 * @param p_cascade - каскадное обновление кэшей ТБП от p_class до самого верхнего
 * @param p_id - идентификатор экземпляра
 */
procedure cache_reset(p_class in varchar2, p_cascade boolean, p_id in varchar2);
end cache_service;
/
show err

