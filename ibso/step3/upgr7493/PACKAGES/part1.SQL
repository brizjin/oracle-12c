prompt part_mgr
create or replace package part_mgr as
/*
 *  $Revision: 65552 $
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/part1.SQL $
 *  $Author: zikov $
 *  $Date:: 2015-01-30 11:30:55 #$
 */
--
    prt_mode    boolean;
    cur_key     integer;
    cur_pos     integer;
--
    procedure clear_obj_del(p_class varchar2, p_qual varchar2);
    procedure obj_delete(p_id varchar2);
    function  get_delete return varchar2;
    procedure clear_obj_upd(p_class varchar2, p_qual varchar2);
    procedure obj_update(p_id varchar2, p_qual varchar2);
    function  get_update(p_qual out varchar2) return varchar2;
--
    procedure analyze_object(p_obj_name varchar2, p_subobject varchar2 default null,
                             p_option   varchar2 default null,
                             p_cascade  boolean  default null,
                             p_degree   pls_integer default null,
                             p_owner    varchar2 default null);
--
    function  get_description(p_class_id varchar2, p_position integer) return varchar2 deterministic;
    pragma restrict_references(get_description,wnds,wnps);
    procedure set_description(p_class_id varchar2, p_position integer, p_description varchar2);
    procedure refresh_description(p_class_id varchar2);
    procedure set_partition(p_class_id  varchar2,
                            p_position  integer  default null,
                            p_actstatus varchar2 default null,
                            p_arcstatus varchar2 default null);
    procedure reset_packages;
--
/**
 * Создание индекса
 * @return
 *  '3' - были ошибки при (пере)создании индекса, которые записаны в канал storage_utils.pipe_name
 *  Остальные значения относятся к последнему обработанному разделу индекса,
 *      либо к индексу последней обработанной таблицы partview, либо к индексу
 *      последнего обработанного mirror, либо ко всему индексу, если он был один:
 *    '0' - индекс (пере)создан,
 *    '1' - индекс для primary key (локальный, если есть разделы) и он не (пере)создавался
 *    '2' - индекс не для primary key, либо, если есть разделы, то для primary key,
 *          но глобальный. не (пере)создавался
 * @throw
 *  исключение с кодом -20100 при ошибке трансляции pl+ выражения
 *  исключения с кодом -6508,-4061 при сбросе пакетов
 */
function Create_Index(p_Name IN varchar2,
    p_rebuild       IN boolean  default false,
    p_ratio         IN number   default 1,
    p_tspacei       IN varchar2 default null,
    p_ini_trans     IN number   default null,
    p_max_trans     IN number   default null,
    p_pct_free      IN number   default null,
    p_init_extent   IN number   default null,
    p_next_extent   IN number   default null,
    p_min_extents   IN number   default null,
    p_max_extents   IN number   default null,
    p_pct_increase  IN number   default null,
    p_free_lists    IN number   default null,
    p_free_groups   IN number   default null,
    p_degree        IN number   default null,
    p_part_tspace   IN varchar2 default null,
    p_position      pls_integer default null,
    p_reverse       boolean     default false) RETURN VARCHAR2;
--
function  get_mirror_name(p_name varchar2,p_pref varchar2) return varchar2 deterministic;
pragma restrict_references(get_mirror_name,wnds,wnps,rnds,rnps);
function  reset_mirror_name(p_name varchar2,p_pref varchar2) return varchar2 deterministic;
pragma restrict_references(reset_mirror_name,wnds,wnps,rnds,rnps);
function  get_row_deps(p_name varchar2, p_class varchar2 default null) return varchar2 deterministic;
pragma restrict_references(get_row_deps,wnds,wnps);
function  make_class_table(p_class_id varchar2, p_table varchar2,
                           p_position integer default null) return varchar2;
procedure create_partition_views(p_class varchar2);
procedure synchronize_tables( p_table      varchar2,
                              p_mirror     varchar2,
                              p_position   integer,
                              p_tab_tspace varchar2 default null,
                              p_idx_tspace varchar2 default null);
procedure exchange_partition( p_class_id   varchar2,
                              p_position   integer,
                              p_tab_tspace varchar2 default null,
                              p_idx_tspace varchar2 default null,
                              p_synch      boolean  default true);
procedure synchronize_mirrors(p_class      varchar2,
                              p_tab_tspace varchar2 default null,
                              p_idx_tspace varchar2 default null,
                              p_view_only  boolean  default true);
procedure exchange_mirrors  ( p_class_id   varchar2,p_mirror varchar2,
                              p_position   integer  default null,
                              p_tab_tspace varchar2 default null,
                              p_idx_tspace varchar2 default null,
                              p_synch      boolean  default true);
--
procedure partition_to_partview(p_class_id  varchar2,
                                p_pipe_name varchar2 default null,
                                p_build     boolean  default true);
--
procedure partview_to_partition(p_class_id  varchar2,
                                p_pipe_name varchar2 default null,
                                p_build     boolean  default true);
--
procedure add_partition(p_class_id  varchar2,
                        p_condition varchar2,
                        p_description varchar2 default null,
                        p_part_tspace varchar2 default null,
                        p_actual    varchar2 default null,
                        p_pipe_name varchar2 default null,
                        p_build     boolean  default false,
                        p_ratio     number   default 1,
                        p_tspace    varchar2 default null,
                        p_init_     number   default null,
                        p_next_     number   default null,
                        p_ini_trans number   default null,
                        p_max_trans number   default null,
                        p_pct_free  number   default null,
                        p_pct_used  number   default null,
                        p_min_exts  number   default null,
                        p_max_exts  number   default null,
                        p_pct_incr  number   default null,
                        p_lists     number   default null,
                        p_groups    number   default null,
                        p_degree    number   default null,
                        p_ipart_tspace varchar2 default null,
                        p_idx_tspace   varchar2 default null,
                        p_key       integer  default null,
                        p_part_mode boolean  default null);
--
    function get_new_stor(p_name  varchar2, p_tspace varchar2, p_stor varchar2, p_size number, p_pct_free number,
                          p_table boolean default false, p_init number default null, p_next number default null, p_compr pls_integer default null
                         ) return varchar2;
    procedure get_new_part(p_class varchar2, p_part varchar2, p_actual varchar2, p_owner varchar2);
    procedure map_column_data(src varchar2, dst varchar2, col varchar2, p_commit boolean default true);
--
    function get_definitions(p_old_table               varchar2,
                             p_new_table               in out nocopy varchar2,
                             stor                      in out nocopy varchar2,
                             idxs_nam                  in out nocopy "CONSTANT".DEFSTRING_TABLE,
                             idxs                      in out nocopy "CONSTANT".STRING_TABLE,
                             cons                      in out nocopy "CONSTANT".STRING_TABLE,
                             p_ratio                   number default 1,
                             p_tspace                  varchar2 default null,
                             p_init_                   number default null,
                             p_next_                   number default null,
                             p_ini_trans               number default null,
                             p_max_trans               number default null,
                             p_pct_free                number default null,
                             p_pct_used                number default null,
                             p_min_exts                number default null,
                             p_max_exts                number default null,
                             p_pct_incr                number default null,
                             p_lists                   number default null,
                             p_groups                  number default null,
                             p_degree                  number default null,
                             p_id                      integer default null,
                             p_idxtspace               varchar2 default null,
                             p_class                   varchar2 default null,
                             p_mode                    pls_integer default null,
                             p_part_profile            varchar2 default null)
      return number;
--
    function  get_subobj_list(p_name varchar2,p_nested boolean,p_owner varchar2) return varchar2 deterministic;
    pragma restrict_references(get_subobj_list,wnds,wnps);
    procedure get_optimal_params ( initial_extent  OUT nocopy number,
                                   next_extent     OUT nocopy number,
                                   p_name    varchar2,
                                   p_subname varchar2,
                                   p_owner   varchar2 );
    pragma restrict_references(get_optimal_params,wnds,wnps);
    procedure get_storage ( tablespace_name OUT nocopy varchar2,
                            ini_trans       OUT nocopy number,
                            max_trans       OUT nocopy number,
                            initial_extent  OUT nocopy number,
                            next_extent     OUT nocopy number,
                            min_extents     OUT nocopy number,
                            max_extents     OUT nocopy number,
                            pct_increase    OUT nocopy number,
                            pct_free        OUT nocopy number,
                            pct_used        OUT nocopy number,
                            free_lists      OUT nocopy number,
                            free_groups     OUT nocopy number,
                            degree_         OUT nocopy number,
                            p_name    varchar2,
                            p_type    varchar2,
                            p_subname varchar2,
                            p_owner   varchar2 );
    pragma restrict_references(get_storage,wnds,wnps);
--
    procedure check_indexes(p_class_id in varchar2 default null,
                            p_index_name in varchar2 default null);
--
    function get_index_cols(p_list  in out nocopy varchar2,
                            p_counter  in out nocopy pls_integer,
                            p_index varchar2, p_table varchar2, p_owner varchar2,
                            p_class varchar2, p_skip_col varchar2
                           ) return pls_integer;
    pragma restrict_references(get_index_cols,wnds,wnps);
    function get_ind_cols(p_index varchar2, p_table varchar2, p_owner varchar2) return varchar2 deterministic;
    pragma restrict_references(get_ind_cols,wnds,wnps);
--
end;
/
sho err
