prompt rtl_utils 
create or replace package 
/**
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/rtl_utils1.sql $<br/>
 *  $Author: kurkin $<br/>
 *  $Revision: 47795 $<br/>
 *  $Date:: 2014-06-24 15:04:06 #$<br/>
 *  @headcom
 */

rtl_utils is
    
    PREFIX        constant varchar2(30) := 'LOCKS$'||Inst_info.owner||'$';

/**
 * ”дал€ет физическую сессиию
 * @Param   p_session_id прикладной идентификатор сессии    
 */
procedure kill_session(p_session_id pls_integer);

/**
 * ¬озвращает статус физической сессии
 * @Param   p_uid        прикладной идентификатор сессии
 * @Param   p_sid        идентификатор сессии
 * @Param   p_instance   узел кластера сессии
 */
function session_status(p_uid pls_integer, p_sid pls_integer, p_rtl_instance pls_integer default null) return varchar2;

/**
 * ѕользовательским сесси€м, работающим в двухуровневой
 * архитектуре (клиент-сервер Ѕƒ), в качестве ID сеанса
 * присваиваетс€ значение AUDSID сессии (V$SESSION.AUDSID)
 * Oracle, в которой осуществлено соединение с сервером Oracle.
 */
function is_session_2l(p_session_id pls_integer) return boolean;

/**
 * ѕользовательским сесси€м, работающим в трехуровневой
 * архитектуре (клиент - сервер приложений, —ѕ, - сервер Ѕƒ),
 * в качестве ID сеанса присваиваетс€ генерируемое системой
 * значение в диапазоне -1073741824..-2147483647.
 */
function is_session_3l(p_session_id pls_integer) return boolean;

/**
 * ѕользовательским сесси€м, выполн€ющимс€ через очередь
 * заданий Oracle (DBA_JOBS), в качестве ID сеанса присваиваетс€
 * отрицательное значение номера задани€ в очереди заданий Oracle
 * (DBA_JOBS) - диапазон значений -1..-1073741823.
 */
function is_session_job(p_session_id pls_integer) return boolean;

function get_user_id(p_ses varchar2) return pls_integer;

/**
 * ”становка, получение и удаление сессионного свойства
 */
function get_rtl_users_props(p_id number, p_name varchar2) return varchar2;
pragma RESTRICT_REFERENCES ( get_rtl_users_props, WNDS, WNPS, RNDS, RNPS, TRUST );
procedure set_rtl_users_props(p_id number, p_name varchar2, p_value varchar2); 
function del_rtl_users_props(p_id number) return boolean;

end rtl_utils;
/
show errors package rtl_utils
