prompt javac_mgr
create or replace
package javac_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/javac_mgr1.sql $
 *  $Author: kirgintsev $
 *  $Revision: 19890 $
 *  $Date:: 2012-12-20 12:06:24 #$
 */
  -- Состояния java класса
  STATUS_NOT_EXISTS constant varchar2(12) := 'NOT EXISTS';
  STATUS_VALID      constant varchar2(12) := 'VALID';
  STATUS_INVALID    constant varchar2(12) := 'INVALID';
  STATUS_UPDATED    constant varchar2(12) := 'UPDATED';
  --
	type host_errors_cursor_t is ref cursor return host_errors%rowtype;
	
	/* Возвращает версию пакета */
	function get_version return varchar2;
	
  /* Возвращает текст java кода */
  function get_host_source(p_method_id varchar2) return clob;
  
	/* Возвращает список ошибок java кода операции*/
  procedure get_host_errors(p_method_id varchar2, p_host_errors in out nocopy host_errors_cursor_t);
  
  /* Возвращает статус java класса операции */
  function get_source_status(p_method_id varchar2) return varchar2;
end javac_mgr;
/
sho err
