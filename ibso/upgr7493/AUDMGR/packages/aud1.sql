prompt aud_mgr
create or replace
package &&audmgr..aud_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUDM/aud1.sql $
 *  $Author: zikov $
 *  $Revision: 65552 $
 *  $Date:: 2015-01-30 11:30:55 #$
 */
--
	MSG_LOGON_ERROR constant pls_integer := 1;
	MSG_EXPIRE_ERROR constant pls_integer := 2;
	MSG_LOCK_ERROR constant pls_integer := 3;
	MSG_UNLOCK_ERROR constant pls_integer := 4;
	MSG_DELETE_ERROR constant pls_integer := 5;
	MSG_ACCOUNT_LOCKED constant pls_integer := 6;
	MSG_ACCOUNT_UNLOCKED constant pls_integer := 7;
	MSG_PASSWORD_EXPIRED constant pls_integer := 8;
	MSG_PASSWORD_CHANGED_EXPIRED constant pls_integer := 9;
	MSG_ACCOUNT_REFRESHED constant pls_integer := 10;
	MSG_USER_DELETED constant pls_integer := 11;
	MSG_ACCOUNT_LOCKED_EXT constant pls_integer := 12;
	MSG_PASSWORD_REFRESHED constant pls_integer := 13;
	MSG_PASSWORD_EXPIRED_EXT constant pls_integer := 14;
	MSG_ACCOUNT_UNLOCKED_EXT constant pls_integer := 15;
--
    NO_PRIVILEGES     exception;
    PRAGMA EXCEPTION_INIT( NO_PRIVILEGES   , -1031 ); -- ORA-01031: insufficient privileges
--
    procedure err(p_text varchar2);
    function  exec_sql(p_query varchar2) return varchar2;
--
    function  get_value(p_name varchar2) return varchar2;
    procedure set_value(p_name varchar2, p_value varchar2);
    procedure get_settings(p_init boolean default false);
    procedure get_prop(str varchar2, prop varchar2, pos out nocopy pls_integer, len out nocopy pls_integer );
--
    procedure add_owner(p_owner varchar2);
    procedure del_owner(p_owner varchar2);
    procedure chk_status(p_old varchar2,p_new varchar2,p_start date,p_end date,p_insert boolean);
    procedure chk_subject(p_name varchar2);
	function  chk_user(p_owner varchar2) return varchar2;
    function  user_exists(p_user varchar2) return pls_integer;
--
    function  server_test return boolean;
    procedure submit;
    procedure hold( p_hold boolean );
    procedure job ( p_job integer, p_date in out nocopy date, p_broken in out nocopy boolean );
    procedure stop;
    procedure run;
--
    procedure debug(p_text varchar2,p_level pls_integer default 1);
    procedure init_contexts;
    procedure logoff;
--
    function  is_supervisor(p_user varchar2, p_list varchar2) return boolean;
    procedure notify (p_owner varchar2, p_event varchar2,
                      p_user  varchar2, p_osusr varchar2,
                      p_term  varchar2, p_conn  varchar2,
                      p_time  date, p_ses number, p_err number);
    procedure notify1(p_owner varchar2, p_event varchar2);
--
	function get_msg(p_msg pls_integer,
                 p1    varchar2 default NULL,
                 p2    varchar2 default NULL,
                 p3    varchar2 default NULL,
                 p4    varchar2 default NULL,
                 p5    varchar2 default NULL,
                 p6    varchar2 default NULL,
                 p7    varchar2 default NULL,
                 p8    varchar2 default NULL,
                 p9    varchar2 default NULL
                ) return varchar2;
--
  procedure ora_user_password_set(
    p_user_name varchar2,
    p_password  varchar2);
--
end;
/
show errors

