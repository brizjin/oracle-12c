prompt session_initialization_service
create or replace
package session_initialization_service is
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/session_initialization_service1.sql $<br/>
 *  $Author: kurkin $<br/>
 *  $Revision: 56851 $<br/>
 *  $Date:: 2014-12-02 16:50:03 #$<br/>
 *  @headcom
 */

/**
 * Возвращает значение настройки инициализации NLS и Alter_Session параметров
*/
function is_NLS_init return boolean;

/**
 * Versioning.
 * @return            Версию сервиса.
 */
function get_version return varchar2;

/**
 * Динамически финализирует сессию пользователя.
 */
procedure finit_session_immediate;

/**
 * Устанавливает пользовательский и системный контекст.
 * @param   p_class   Уровень инициализации контекста.
 */
procedure set_context(p_class varchar2 default null);

/**
 * Лёгкая инициализация сессии.
 * @param   p_id                     Идентификатор сессии.
 * @param   p_user                   Пользователь.
 * @param   p_mode                   Уровни инициализации соединений.
 * @param   p_attr_mapping_service   Режим работы сервиса дублированных реквизитов.
 */
procedure init_session_light(p_id pls_integer, p_user varchar2,
                             p_mode varchar2 := null, p_attr_mapping_service varchar2 := null, p_nls_init boolean:=false);

/**
 * Тяжелая инициализация сессии.
 * @param   p_id                     Идентификатор сессии.
 * @param   p_os_user                Пользователь.
 * @param   p_domain                 Домен пользователя.
 * @param   p_class                  Уровень инициализации контекста.
 */
procedure init_session_heavy(p_id pls_integer, p_os_user varchar2, p_domain varchar2, p_class varchar2 default null, p_nls_init boolean:=false);

/**
 * Финализация сессии.
 * @param   p_reset   Режимы работы с пользовательским и системным контекстом.
 */
procedure finit_session(p_reset varchar2 default null);

/**
 * Лёгкая финализация сессии.
 * @param   p_reset   Режимы работы с пользовательским и системным контекстом.
 */
procedure finit_session_light(p_reset varchar2 default null);

end session_initialization_service;
/
show errors

