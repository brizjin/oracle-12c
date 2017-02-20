prompt repl_utils
create or replace package repl_utils as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/repl_ut1.sql $
 *  $Author: kuvardin $
 *  $Revision: 48615 $
 *  $Date:: 2014-07-11 10:04:38 #$
 */
--
    verbose boolean := false;
    pipe_name varchar2(30) := 'DEBUG';
    t INTERVAL DAY (1) TO SECOND (9); -- variable for test-only
--
    function  repl_setting(p_name varchar2) return varchar2;
    procedure lock_repl_setting(p_name varchar2);
    procedure put_repl_setting(p_name varchar2, p_value   varchar2);
--
    procedure WS(msg_str varchar2);
    function  execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false, p_name varchar2 default null ) return integer;
    procedure execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false );
--
    procedure create_kernel_triggers(p_pipe varchar2 default null);
    procedure drop_kernel_triggers(p_pipe varchar2 default null);
--
    function  show_errors ( p_name  IN varchar2,
                            p_title IN boolean default TRUE
                          ) return varchar2 deterministic;
--
    procedure save_sequences;
    procedure import_sequences;
--
    procedure set_trigger_status(p_name varchar2, p_status varchar2);
-- Для альтернативного сохранения в replication
    procedure reset;
    /*
    параметр p_table теперь не используется
    оставлено для совместимости
    */
    procedure init(p_table varchar2);
    /*
    парметр p_table теперь не используется
    оставлено для совместимости
    */
    procedure save(p_table varchar2);
    procedure add(p_table varchar2,p_id varchar2,p_event varchar2,p_type varchar2, p_qual varchar2,
                  p_value varchar2, p_old_value varchar2);

end;
/
show err

