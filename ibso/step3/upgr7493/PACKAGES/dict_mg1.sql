prompt dict_mgr
create or replace package dict_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/dict_mg1.sql $
 *  $Author: sasa $
 *  $Revision: 97771 $
 *  $Date:: 2016-03-21 17:36:19 #$
 */
--
    procedure rename_class(p_class_id varchar2, p_new_id varchar2,
                           p_cascade    boolean default null,
                           p_update_src boolean default null);
    procedure rename_class_state(p_class_id varchar2,p_state_id varchar2,p_new_state_id varchar2);

    procedure delete_class(p_class_id varchar2);
    function  delete_class_state(p_class_id varchar2,p_state_id varchar2) return integer;
    function  delete_transition (p_class_id varchar2,p_trans_id varchar2,p_short varchar2 default null) return integer;

    procedure drop_unused_columns (p_class varchar2 default null);
    procedure build_type_dependent(p_class varchar2,p_pipe varchar2,p_build boolean default true,p_drop boolean default false);

    procedure update_class_relations(p_class_id varchar2);

    procedure delete_class_entirely(p_class_id varchar2, p_pipe_name varchar2 default 'DEBUG');
    procedure class_dependencies(p_cl_id varchar2,p_pipe_name varchar2 default 'DEBUG',lev_ in number default 1);

    procedure set_init_method(p_class_id varchar2, p_method_id varchar2);
--
    function  get_obj_list(p_table varchar2, p_type varchar2 default null, p_owner varchar2 default null, p_get_owner varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_obj_list,wnds,wnps);
    function  get_constraint(p_name varchar2,p_table varchar2, p_owner varchar2 default null) return varchar2 deterministic;
    pragma restrict_references(get_constraint,wnds,wnps);
    procedure get_constraint(p_name   varchar2,
                             p_table  varchar2,
                             p_status out nocopy varchar2,
                             p_type   out nocopy varchar2,
                             p_list   out nocopy varchar2,
                             p_cond   out nocopy varchar2,
                             p_owner  varchar2 default null );
    pragma restrict_references(get_constraint,wnds,wnps);
    procedure set_constraint(p_name varchar2,p_table varchar2,p_text varchar2,p_owner  varchar2 default null);
    procedure get_trigger(p_name   varchar2,
                          p_table  varchar2,
                          p_status out nocopy varchar2,
                          p_type   out nocopy varchar2,
                          p_event  out nocopy varchar2,
                          p_list   out nocopy varchar2,
                          p_text   out nocopy clob,
                          p_owner  varchar2 default null );
    --pragma restrict_references(get_trigger,wnds,wnps); PLATFORM-2112
    procedure set_trigger(p_name   varchar2,
                          p_table  varchar2,
                          p_type   varchar2,
                          p_event  varchar2,
                          p_list   varchar2,
                          p_text   varchar2,
                          p_owner  varchar2 default null );
    procedure get_optimal_params ( initial_extent  OUT nocopy number,
                                   next_extent     OUT nocopy number,
                                   p_name    varchar2,
                                   p_subname varchar2 default null,
                                   p_owner   varchar2 default null );
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
                            degree          OUT nocopy number,
                            p_name    varchar2,
                            p_type    varchar2 default null,
                            p_subname varchar2 default null,
                            p_owner   varchar2 default null );
    pragma restrict_references(get_storage,wnds,wnps);
    procedure set_storage ( tablespace_name varchar2,
                            ini_trans       number,
                            max_trans       number,
                            initial_extent  number,
                            next_extent     number,
                            min_extents     number,
                            max_extents     number,
                            pct_increase    number,
                            pct_free        number,
                            pct_used        number,
                            free_lists      number,
                            free_groups     number,
                            degree          number,
                            p_name    varchar2,
                            p_type    varchar2 default null,
                            p_subname varchar2 default null,
                            p_owner   varchar2 default null );
-- Partitioning interface
    function  get_description(p_class_id varchar2, p_position integer) return varchar2;
    pragma restrict_references(get_description,wnds,wnps);
    procedure set_description(p_class_id varchar2, p_position integer, p_description varchar2);
    procedure refresh_description(p_class_id varchar2);
    procedure add_partition(p_class_id  varchar2,
                            p_condition varchar2,
                            p_new_name  varchar2 default null,
                            p_act_name  varchar2 default null,
                            p_pipe_name varchar2 default null,
                            p_part_ts   varchar2 default null,
                            p_tspace    varchar2 default null,
                            p_build     boolean  default false,
                            p_ratio     number   default 1,
                            p_ipart_ts  varchar2 default null,
                            p_idx_ts    varchar2 default null,
                            p_part_mode boolean  default null
                            );
    procedure convert_partition(p_class_id  varchar2, p_to_partition boolean,
                                p_pipe_name varchar2 default null,
                                p_build     boolean  default true);
    procedure set_partition(p_class_id  varchar2,
                            p_position  integer  default null,
                            p_actstatus varchar2 default null,
                            p_arcstatus varchar2 default null);
    procedure activate_archive(p_tablespace varchar2,
                               p_actstatus  varchar2 default null,
                               p_arcstatus  varchar2 default null,
                               p_activate   boolean  default true);
    procedure create_mirror_table(p_class varchar2, p_position integer);
    procedure exchange_partition (p_class varchar2, p_position integer,
                                  p_tab_tspace varchar2 default null,
                                  p_idx_tspace varchar2 default null);
    procedure exchange_mirrors  ( p_class_id   varchar2,p_mirror varchar2,
                                  p_position   integer  default null,
                                  p_tab_tspace varchar2 default null,
                                  p_idx_tspace varchar2 default null,
                                  p_synch      boolean  default true);
--
    procedure check_class_tab_columns(inserting boolean, deleting boolean,
                                 p_old class_tab_columns%rowtype,
                                 p_new class_tab_columns%rowtype);
    procedure check_class_tables(inserting boolean, deleting boolean,
                                 p_old class_tables%rowtype,
                                 p_new class_tables%rowtype);
    procedure check_class_attributes(inserting boolean, deleting boolean,
                                     p_old class_attributes%rowtype,
                                     p_new class_attributes%rowtype);
    procedure check_states(inserting boolean, deleting boolean,
                           p_old states%rowtype,
                           p_new states%rowtype);
    procedure check_transitions(inserting boolean, deleting boolean,
                                p_old transitions%rowtype,
                                p_new transitions%rowtype);
    procedure check_classes(inserting boolean, deleting boolean,
                            p_old classes%rowtype,
                            p_new classes%rowtype);
    function  make_table_name(p_class_id varchar2) return varchar2 deterministic;
--
    function  get_cached(p_class_id varchar2) return number;
    procedure set_cached(p_class_id varchar2, p_cached number);
    function  get_ind_cols(p_index_name in varchar2,p_owner  varchar2 default null) return varchar2;
    function  table2class(p_table varchar2) return varchar2;
    pragma restrict_references(table2class,wnds,wnps);
-- blob in table LRAW
    function open_lob(p_id in varchar2, p_mode in number default 0) return number;
    function get_lob_data(p_handle in number, p_data out raw, p_size pls_integer default null,
                          p_pos pls_integer default null) return pls_integer;
    function set_lob_data(p_handle in number, p_data in raw, p_size pls_integer default null,
                        p_pos pls_integer default null) return pls_integer;
    function clear_lob_data(p_handle pls_integer, p_size pls_integer default null) return pls_integer;
    function close_lob(p_handle pls_integer, p_commit boolean default true) return number;
-- licensing
    function option_enabled(p_option varchar2) return boolean;
    function is_allow_create_rowid(p_class_id varchar2, p_rowid boolean) return boolean;
    procedure is_allow_create_rowid(p_class_id varchar2, p_properties varchar2);

    -- –азрешено ли создавать типы с базовым типом NSTRING/NMEMO
    procedure is_allow_nvarchar2(p_class_id varchar2, p_base_class_id varchar2);
end;
/
show err
