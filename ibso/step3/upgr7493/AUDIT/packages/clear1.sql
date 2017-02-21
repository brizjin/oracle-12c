column xxx new_value oyyy noprint
select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') xxx from dual;

prompt clear
create or replace package clear is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/clear1.sql $
 *  $Author: VKazakov $
 *  $Revision: 65816 $
 *  $Date:: 2015-02-04 11:41:55 #$
 */

--
MIN_INTERVAL constant pls_integer := &&D_MIN_INTERVAL;
MAX_INTERVAL constant pls_integer := 365000;

--
DATE_FORMAT constant varchar2(21):= 'YYYY-MM-DD HH24:MI:SS';
TIMESTAMP_FORMAT constant varchar2(30):= &&D_TIMESTAMP_FORMAT;

-- Работа с версией
BUILD_DATE constant varchar2(30):='&oyyy';
VERSION constant varchar2(10):= '7.4';

function build return pls_integer;
pragma restrict_references ( build, wnds, wnps, rnds  );

function revision return pls_integer;
pragma restrict_references ( revision, wnds, wnps, rnds );

function full_version return varchar2;
pragma restrict_references ( full_version, wnds, wnps, rnds );

-- Работа с правами
function  procs_and_grants(p_owner varchar2 default null) return varchar2;
function  check_role(p_user varchar2, p_role varchar2) return boolean;

-- Пользователи
procedure create_user(p_user varchar2, p_name varchar2);
procedure edit_user(p_user varchar2, p_name varchar2);
procedure user_grants(p_user varchar2 default null);
procedure delete_user(p_user varchar2);
procedure del_owner(p_owner varchar2,p_only_grants boolean default true,p_data boolean default false);

-- Сессии
procedure open_ses (p_owner varchar2);
procedure close_ses(p_owner varchar2);
function  get_buf return varchar2;

-- Журналирование
procedure write_log(p_owner varchar2, p_topic varchar2, p_code varchar2, p_text varchar2);

-- Работа с настройками
function  AudPartitions return boolean;
function  get_value(p_owner varchar2, p_name varchar2) return varchar2;
procedure set_value(p_owner varchar2, p_name varchar2, p_value varchar2,
                    p_description varchar2 default null);
function  get_interval(p_owner varchar2, p_name varchar2) return number;
procedure set_interval(p_owner varchar2, p_name varchar2, p_interval number);

-- Работа с email
procedure set_notification(p_owner   varchar2, p_event   varchar2,
                           p_subject varchar2, p_message varchar2,
                           p_sender  varchar2, p_sender_name varchar2,
                           p_description varchar2);
procedure set_notification_status(p_owner varchar2, p_event varchar2, p_status varchar2);
procedure set_recipient(p_owner varchar2, p_event varchar2,
                        p_email varchar2, p_name  varchar2);
procedure set_recipient_status(p_owner varchar2, p_event  varchar2,
                               p_email varchar2, p_status varchar2);
procedure set_message (p_topic varchar2, p_code  varchar2, p_text varchar2);

-- Работа с разделами (партификация)
function  get_diary_step(p_owner varchar2, p_code pls_integer) return varchar2;
procedure get_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace out nocopy varchar2, p_idx_tablespace out nocopy varchar2);
procedure set_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace in varchar2, p_idx_tablespace in varchar2);
function  get_end_date(owner varchar2, p_code pls_integer) return date;
procedure get_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent out nocopy varchar2, p_next_extent out nocopy varchar2);
procedure set_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent varchar2, p_next_extent varchar2);
procedure add_partitions(owner varchar2, p_code pls_integer, end_date date);
procedure drop_partitions(owner varchar2, p_code pls_integer, p_date date);

-- Очистка журнала(ов)
function  diary (p_owner varchar2, p_code pls_integer default null, p_date date default null) return varchar2;
function  diarys(p_owner varchar2, p_diary boolean default TRUE, p_osh boolean default TRUE,
                 p_vals  boolean default TRUE, p_date date default NULL, p_och boolean default TRUE
                ) return varchar2;

-- Максимальная дата для экспорта/очистки
function date_to(p_owner varchar2, p_code pls_integer, p_date date default null) return date;

-- Проверка существования файла
function check_file (location  in varchar2, filename  in varchar2) return integer;

-- Экспорт журнала(ов)
function exp(p_owner    varchar2, p_FilePath varchar2 default null,
             p_FileName varchar2 default null, p_append boolean default FALSE,
             p_code  pls_integer default null, p_date   date default null,
             p_make_date_safe boolean default true,
             p_debug boolean default false) return varchar2;
function export(p_owner    varchar2, p_FilePath varchar2 default null,
                p_FileName varchar2 default null, p_append boolean default FALSE,
                p_diary boolean default TRUE, p_osh  boolean default TRUE,
                p_vals  boolean default TRUE, p_date date default null,
                p_och   boolean default TRUE,
                p_make_date_safe boolean default true) return varchar2;

-- Импорт журнала(ов)
function imp(p_owner    varchar2, p_FilePath  varchar2 default null,
             p_FileName varchar2 default null, p_codes varchar2 default null,
             p_date     date default null, p_destowner varchar2 default null,
             p_debug boolean default false) return varchar2;
function import(p_owner    varchar2, p_FilePath varchar2 default null,
                p_FileName varchar2 default null, p_diary boolean default TRUE,
                p_osh  boolean default TRUE, p_vals  boolean default TRUE,
                p_och  boolean default TRUE) return varchar2;
--
end;
/
show err

