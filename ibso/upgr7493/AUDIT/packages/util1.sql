prompt utils
create or replace package utils is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/util1.sql $
 *  $Author: khaliljullova $
 *  $Revision: 76622 $
 *  $Date:: 2015-07-16 10:47:19 #$
 */
--
DIARY constant pls_integer := 0;
DIARY_PARAM constant pls_integer := 10;
VALUES_HISTORY constant pls_integer := 11;
OBJECT_STATE_HISTORY constant pls_integer := 12;
--
DIARY1 constant pls_integer := 1;
DIARY2 constant pls_integer := 2;
DIARY3 constant pls_integer := 3;
DIARY4 constant pls_integer := 4;
DIARY5 constant pls_integer := 5;
DIARY6 constant pls_integer := 6;
DIARY7 constant pls_integer := 7;
VALSH constant pls_integer := -1;
OSH constant pls_integer := -2;
OCH constant pls_integer := -3;
DP constant pls_integer := -4;
EDH constant pls_integer := -5;
--
SNAPSHOT_TOO_OLD exception;
pragma exception_init(SNAPSHOT_TOO_OLD, -01555);
EXEC_EXCEPTION   exception;
pragma exception_init(EXEC_EXCEPTION,   -20999);
NO_PRIVILEGES     exception;
pragma exception_init(NO_PRIVILEGES   , -1031 ); -- ORA-01031: insufficient privileges
--
procedure enable_buf ( p_size  IN pls_integer default null,
                       p_clear IN boolean default TRUE );
procedure disable_buf;
function  get_line ( p_text out nocopy varchar2 ) return integer;
function  get_buf return varchar2;
procedure put_line ( p_text IN varchar2,
                     p_nl   IN boolean default true
                   );
function  execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false, p_par varchar2 default null ) return integer;
procedure execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false );
--
function  AudOwner return varchar2;
function  AudPartitions return boolean;
--
function  get_value(p_owner varchar2, p_name varchar2) return varchar2;
procedure set_value(p_owner varchar2, p_name varchar2, p_value varchar2,
                    p_description varchar2 default null);
function  get_interval(p_owner varchar2, p_name varchar2) return number;
procedure set_interval(p_owner varchar2, p_name varchar2, p_interval number);
function  force_parallel(p_owner varchar2) return pls_integer;
--
function  check_role(p_user varchar2, p_role varchar2) return boolean;
--
procedure create_user(p_user varchar2, p_name varchar2);
procedure edit_user(p_user varchar2, p_name varchar2);
procedure user_grants(p_user varchar2 default null);
procedure delete_user(p_user varchar2);
--
procedure roles(dropping boolean default true);
procedure create_views;
procedure create_procedures;
procedure grants(p_owner varchar2 default null);
procedure del_owner(p_owner varchar2,p_only_grants boolean default true,p_data boolean default false);
--
function  table_name(p_owner varchar2,p_type pls_integer,p_select boolean default true) return varchar2;
function  table_exists(owner varchar2, tab_type pls_integer) return boolean;
function  table_partitioned(owner varchar2, tab_type pls_integer) return boolean;
function  get_column_type(p_table varchar2, p_column varchar2, p_prec varchar2 default null) return varchar2;
function  get_diary_step(p_owner varchar2, p_code pls_integer) return varchar2;
function  tableexists(p_table varchar2) return boolean;
procedure table_partitions(p_table varchar2,
                           p_part in out nocopy varchar2,
                           p_degr in out nocopy varchar2);
procedure get_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace out nocopy varchar2, p_idx_tablespace out nocopy varchar2);
procedure set_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace in varchar2, p_idx_tablespace in varchar2);
procedure get_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent out nocopy varchar2, p_next_extent out nocopy varchar2);
procedure set_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent varchar2, p_next_extent varchar2);
function  get_max_date(p_table varchar2,p_partition varchar2,p_where varchar2 default null) return date;
function  get_end_date(owner varchar2, p_code pls_integer) return date;
procedure nearest_trunc_date(owner varchar2, tab_type pls_integer, date_to in out nocopy date);
procedure create_table(owner varchar2, tab_type pls_integer, start_date date, end_date date,
                       p_table_name varchar2 default null);
procedure upgrade_table(owner varchar2, tab_type pls_integer);
procedure create_indexes(owner varchar2, tab_type pls_integer);
procedure drop_indexes(owner varchar2, tab_type pls_integer);
procedure add_partitions(owner varchar2, tab_type pls_integer, end_date date,
                         p_table out nocopy varchar2, p_ok_parts out nocopy varchar2);
procedure truncate_partitions(owner varchar2, tab_type pls_integer, date_to date,
                              p_table out nocopy varchar2, p_ok_parts out nocopy varchar2, p_faild_parts out nocopy varchar2);
procedure drop_partitions(owner varchar2, tab_type pls_integer, date_to date,
                          p_table out nocopy varchar2, p_ok_parts out nocopy varchar2, p_faild_parts out nocopy varchar2);
procedure rebuild_indexes(owner varchar2, tab_type pls_integer, start_date date default null);
function check_table_columns(owner varchar2, tab_type pls_integer) return varchar2;
procedure delete_data(p_table varchar2, p_date date,  p_nrows pls_integer,
                      p_count out nocopy pls_integer, p_error out nocopy varchar2);
--
procedure inituser(p_audsid  out nocopy pls_integer,
                   p_orauser out nocopy varchar2,
                   p_osuser  out nocopy varchar2,
                   p_machine out nocopy varchar2,
                   p_module  out nocopy varchar2,
                   p_program out nocopy varchar2,
                   p_sid pls_integer default null
                  );
procedure open_ses (p_owner varchar2);
procedure close_ses(p_owner varchar2);
procedure write_log(p_owner varchar2, p_topic varchar2, p_code varchar2, p_text varchar2);
--
function  set_message (p_topic varchar2, p_code  varchar2, p_text varchar2) return boolean;
procedure reset_message (p_topic varchar2, p_code  varchar2);
procedure error( p_msg varchar2,
                 p1    varchar2 default NULL,
                 p2    varchar2 default NULL,
                 p3    varchar2 default NULL,
                 p4    varchar2 default NULL,
                 p5    varchar2 default NULL,
                 p6    varchar2 default NULL,
                 p7    varchar2 default NULL,
                 p8    varchar2 default NULL,
                 p9    varchar2 default NULL
                );
function  get_msg(p_msg varchar2,
                  p1    varchar2 default NULL,
                  p2    varchar2 default NULL,
                  p3    varchar2 default NULL,
                  p4    varchar2 default NULL,
                  p5    varchar2 default NULL,
                  p6    varchar2 default NULL,
                  p7    varchar2 default NULL,
                  p8    varchar2 default NULL,
                  p9    varchar2 default NULL) return varchar2;
function  gettext ( p_topic varchar2,
                    p_code  varchar2,
                    p1      varchar2 default NULL,
                    p2      varchar2 default NULL,
                    p3      varchar2 default NULL,
                    p4      varchar2 default NULL,
                    p5      varchar2 default NULL,
                    p6      varchar2 default NULL,
                    p7      varchar2 default NULL,
                    p8      varchar2 default NULL,
                    p9      varchar2 default NULL
                  ) return varchar2;
function  get_text( p_topic varchar2,
                    p_code  varchar2,
                    p1      varchar2 default NULL,
                    p2      varchar2 default NULL,
                    p3      varchar2 default NULL,
                    p4      varchar2 default NULL,
                    p5      varchar2 default NULL,
                    p6      varchar2 default NULL,
                    p7      varchar2 default NULL,
                    p8      varchar2 default NULL,
                    p9      varchar2 default NULL
                  ) return varchar2;
function  get_error_stack(p_backtrace boolean default true) return varchar2;
--
end;
/
show err

