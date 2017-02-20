prompt session_service
create or replace
package session_service is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/session_service1.sql $<br/>
 *  $Author: kurkin $<br/>
 *  $Revision: 56855 $<br/>
 *  $Date:: 2014-12-02 17:01:22 #$<br/>
 *  @headcom
 */
/*У ПОЛЬЗОВАТЕЛЯ APP_ADM, ПОЯВИЛИСЬ ПРАВА НА ЭТОТ ПАКЕТ*/
NO_SUCH_SESSION exception;
PRAGMA EXCEPTION_INIT(NO_SUCH_SESSION, -20655);

/**
 * Versioning.
 * @return                         Версию сервиса.
 */
function get_version return varchar2;

/**
 * Регистрация 2L сессии.
 * @param   p_read_pipe_messages   Признак чтения и обработки сессионной пайпы.
 */
procedure open_session(p_read_pipe_messages boolean := true);

/**
 * Регистрация 3L сессии.
 * @param   p_os_user               Пользователь.
 * @param   p_domain                Домен пользователя.
 * @param   p_retry                 Признак удаления других сессий пользователя
 * @param   p_lock_touch_service    Признак регистрации сессии в глобальном контексте
 * @param   p_host_sid              Идентификатор http сессии.
 * @param   p_host_name             Имя хоста.
 */
function open_session_3L(p_os_user varchar2,
                         p_domain varchar2,
                         p_retry varchar2 := null,
                         p_lock_touch_service varchar2 := '1',
                         p_host_sid varchar2 := null,
                         p_host_name varchar2 := null) return pls_integer; 

/**
 * Закрытие сессии.
 * @param   p_id                   Идентификатор сессии (rtl_users).
 */
procedure close_session(p_id pls_integer);

/**
 * Удаление сессии.
 * @param   p_sid                  V$SESSION.SID.
 * @param   p_serial               V$SESSION.SERIAL#.
 */
procedure kill_session(p_sid pls_integer, p_serial pls_integer);

/**
 * Установка атрибутов для миграции.
 * @param   p_id                   Идентификатор сессии (rtl_users).
 * @param   p_host_sid             Идентификатор http сессии.
 * @param   p_host_name            Имя хоста.
 */
procedure set_host(p_id pls_integer, p_host_sid varchar2, p_host_name varchar2);

/**
 * Установка хоста после миграции.
 * @param   p_id                   Идентификатор сессии (rtl_users).
 * @param   p_host_sid             Идентификатор http сессии.
 * @param   p_host_name            Имя хоста.
 */
procedure set_host_name(p_id pls_integer, p_host_sid varchar2, p_host_name varchar2);

/**
 * Удаление сессии.
 * @param   host_id                   Имя хоста (rtl_users.host_name).
 */
procedure close_sessions(host_id varchar2);
end session_service;
/
show errors

