prompt critical_lock_service
CREATE OR REPLACE
package critical_lock_service as 
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/critical_lock_service1.sql $
 *  $Author: verkhovskiy $
 *  $Revision: 56163 $
 *  $Date:: 2014-11-24 17:26:16 #$
 */

criticel_object        constant varchar2(7) := 'EXECUTE';
criticel_subject       constant varchar2(13) := 'CRITICAL_LOCK';

/**
 * Удаляем критическую блокировку-семафор
 * @Param   p_user_id идентификатор пользователя
 */
procedure del_critical_rtl_lock(p_user_id pls_integer);

/**
 * Устанавливаем критическую блокировку-семафор
 * @Param   p_user_id идентификатор пользователя
 */
procedure set_critical_rtl_lock(p_user_id pls_integer, p_lock_active pls_integer);

end critical_lock_service;
/
show err
