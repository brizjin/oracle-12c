prompt executor
create or replace
package executor is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Executor/Executr1.sql $
 *  $Author: kurkin $
 *  $Revision: 56847 $
 *  $Date:: 2014-12-02 16:43:41 #$
 */
--
-- This is the only user interface to methods
--
    DEBUG2NULL constant varchar2(1) := rtl.DEBUG2NULL;
    DEBUG2BUF  constant varchar2(1) := rtl.DEBUG2BUF;
    DEBUG2LOG  constant varchar2(1) := rtl.DEBUG2LOG;
    DEBUG2PIPE constant varchar2(1) := rtl.DEBUG2PIPE;
    DEBUGPIPESIZE   constant pls_integer := rtl.DEBUGPIPESIZE;
    DEBUGBUFFERSIZE constant pls_integer := rtl.DEBUGBUFFERSIZE;
--
    subtype AppCtxRecTyp  is dbms_session.AppCtxRecTyp;
    subtype AppCtxTabTyp  is dbms_session.AppCtxTabTyp;
/*
TYPE AppCtxRecTyp IS RECORD (
   namespace VARCHAR2(30),
   attribute VARCHAR2(30),
   value     VARCHAR2(256));
TYPE AppCtxTabTyp IS TABLE OF AppCtxRecTyp INDEX BY BINARY_INTEGER;
*/
--  Init
    PROCEDURE SetNlsParameters(p_raise  boolean default true);
    PROCEDURE set_NLS_params;
    procedure set_alter_session;
    procedure Dummy;
--  RTL
    procedure sn2id ( p_Class_ID    IN  varchar2,
                      p_Object_ID   IN  varchar2,
                      p_Method_Name IN  varchar2,
                      p_Method_ID   OUT varchar2
                    );
--
/* Change state of the object, validate/check/trans methods must have no params */
    procedure change_state ( p_Object_ID   IN  varchar2,
                             p_New_State   IN  varchar2 default NULL,
                             p_Method_Name IN  varchar2 default NULL,
                             p_Class_ID    IN  varchar2 default NULL,
                             p_Async       IN  boolean default False
                           );
/* procedure, that instructs if state should be changed or not*/
    procedure change_state_error(p_change    boolean default false,
                             p_stack_idx pls_integer default null);
    function  change_state_error_idx return pls_integer;
    procedure unwind_change_state_error(p_stack_idx pls_integer default 0);
--
    procedure def_destructor(p_obj_id   varchar2, p_constr_id varchar2,
                             p_class_id varchar2  default null,
                             p_arch     varchar2  default null );
--
    procedure set_debug(dlevel pls_integer default 0,
                        ddir   varchar2 default DEBUG2BUF,
                        buf_size pls_integer default NULL);
    procedure set_debug_pipe(pipe_name varchar2,
                             pipe_size pls_integer default null);
    procedure get_debug_info(dlevel out integer, buf_size out integer,
                             pipe_name out varchar2, pipe_size out integer);
    procedure debug ( msg varchar2,
                      dlevel pls_integer default 1,
                      p_put_time boolean default FALSE,
                      p_dir      varchar2 default DEBUG2BUF);
    function get_debug_text (ddir varchar2 default DEBUG2BUF,
                             p_clear boolean default TRUE) return varchar2;
    procedure write_log ( p_topic varchar2, p_text varchar2, p_id number default null, p_code varchar2 default null);
--  licensing
    function  get_system_id return varchar2;
    function  get_installation_id return varchar2;
    function  get_application_id(p_calc boolean default false) return varchar2;
    function  get_description(p_id varchar2) return varchar2;
    function  get_app_name return varchar2;
    function  get_limit(p_id varchar2) return varchar2;
    function  get_value(p_id varchar2) return varchar2;
    function  calc_value(p_id varchar2,p_force boolean default false) return varchar2;
    function  get_status(p_id varchar2,p_check boolean default false) return varchar2;
    function  check_status(p_id varchar2) return boolean;
    function option_enabled(p_id in varchar2) return boolean;
--  Pipes
    function receive_message(pipename in varchar2,
                             timeout  in integer default 0) return integer;
    function get_pipe_message( p_msg out varchar2 ) return integer;
    function get_pipe_text ( pipename in varchar2,
                             timeout  in integer default 0) return varchar2;
    procedure clear_pipes(p_locks boolean,p_clear boolean);
--  lock_info
    function  db_readonly return boolean;
    function  info_active return boolean;
    function  info_open   return boolean;
    function  submit_job( p_submit in out nocopy boolean, p_commit boolean default true ) return varchar2;
    procedure lock_stop(p_instance pls_integer default null, p_node pls_integer default null, p_mode pls_integer default null);
    procedure lock_refresh(p_instance pls_integer default null, p_node pls_integer default null);
    procedure lock_flash  (p_instance pls_integer default null, p_node pls_integer default null);
    procedure lock_run;
    function  lock_hold(p_hold boolean) return varchar2;
    function  lock_open(p_name varchar2 default NULL,
                        p_info varchar2 default NULL,
                        p_commit  boolean default true
                       ) return pls_integer;
    function  lock_open_ligth(p_name varchar2 default NULL,
                              p_info varchar2 default NULL) return pls_integer;
    function  lockopen (p_name varchar2 default NULL,
                        p_info varchar2 default NULL
                       ) return pls_integer;
    procedure lock_close;
    procedure set_ids(p_id1 varchar2,p_id2 varchar2,p_id3 varchar2,p_id4 varchar2 default null);
    procedure set_ids(p_id1 varchar2,p_id2 varchar2,p_id3 "CONSTANT".varchar2s);
    function  check_ids(p_id1 varchar2,p_id2 varchar2,p_id3 varchar2 default null,p_id4 varchar2 default null) return boolean;
    function  get_info(p_name varchar2 default NULL) return varchar2;
    procedure Kill_Sessions;
    procedure lock_clear(p_all   boolean default TRUE);
    procedure lock_touch(p_user_id   pls_integer default null);
    procedure lock_read (p_check boolean default FALSE, p_wait number default 0 );
    function  lock_answer(p_wait number default 1,
                          p_get  boolean default true) return boolean;
    function  lock_get_info(p_object  in out nocopy varchar2,
                            p_subject in out nocopy varchar2,
                            l_info    out varchar2,
                            l_time    out date,
                            l_user    out varchar2,
                            u_ses     out varchar2,
                            os_user   out varchar2,
                            ora_user  out varchar2,
                            username  out varchar2,
                            u_info    out varchar2,
                            p_wait    number default 1
                           ) return boolean;
    procedure lock_get(p_object  varchar2,
                       p_subject varchar2 default NULL);
    procedure lock_put(p_object  varchar2,
                       p_subject varchar2 default NULL,
                       p_info    varchar2 default NULL);
    procedure put_get(p_object  varchar2,
                      p_subject varchar2 default NULL,
                      p_info    varchar2 default NULL);
    procedure lock_del(p_object  varchar2,
                       p_subject varchar2 default NULL);
    function  lock_request(p_object  varchar2,
                           p_info    varchar2 default NULL,
                           p_wait    number   default NULL,
                           p_class   varchar2 default NULL
                          ) return varchar2;
    procedure check_obj(p_object  varchar2, p_get boolean default true, p_class varchar2 default NULL);
--  LIB
    procedure set_index_list( p_list  varchar2,
                              p_tbl   in out nocopy   constant.integer_table,
                              p_char  varchar2 default null );
    procedure set_refs_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.reference_table,
                              p_char  varchar2 default null );
    procedure set_string_list(p_list  varchar2,
                              p_tbl   in out nocopy   constant.string_table,
                              p_char  varchar2 default null );
    procedure set_number_list(p_list  varchar2,
                              p_tbl   in out nocopy   constant.number_table,
                              p_char  varchar2 default null );
    procedure set_date_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.date_table,
                              p_char  varchar2 default null );
    procedure set_bool_list ( p_list  varchar2,
                              p_tbl   in out nocopy   constant.boolean_table,
                              p_char  varchar2 default null );
    function  get_index_list( p_tbl   in constant.integer_table,
                              p_char  varchar2 default null ) return varchar2;
    function  get_refs_list ( p_tbl   in constant.reference_table,
                              p_char  varchar2 default null ) return varchar2;
    function  get_date_list ( p_tbl   in constant.date_table,
                              p_char  varchar2 default null ) return varchar2;
    function  get_bool_list ( p_tbl   in constant.boolean_table,
                              p_char  varchar2 default null ) return varchar2;
    function  get_number_list(p_tbl   in constant.number_table,
                              p_char  varchar2 default null ) return varchar2;
    function  get_string_list(p_tbl   in constant.string_table,
                              p_char  varchar2 default null ) return varchar2;
--  Contexts
    function  get_context( p_list in out nocopy AppCtxTabTyp ) return pls_integer;
    procedure set_context( p_name varchar2, p_value varchar2 );
    procedure set_system_context(p_rights boolean default false,
                                 p_init   boolean default true,
                                 p_raise  boolean default true );
    procedure lock_context;
    procedure clear_user_context;
    procedure check_access_level(p_level varchar2, p_check varchar2 default null);
--  Notification emails
    function  check_notify_event(p_event varchar2) return boolean;
    procedure send_notify(p_event varchar2,
                          p_subj1 varchar2 default null,
                          p_subj2 varchar2 default null,
                          p_subj3 varchar2 default null,
                          p_mes1  varchar2 default null,
                          p_mes2  varchar2 default null,
                          p_mes3  varchar2 default null,
                          p_mes4  varchar2 default null,
                          p_mes5  varchar2 default null,
                          p_mes6  varchar2 default null,
                          p_mes7  varchar2 default null,
                          p_mes8  varchar2 default null,
                          p_mes9  varchar2 default null);
--
END Executor;
/
sho err