prompt stat_lib
create or replace
package stat_lib is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/stat1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
--
  function get_version return varchar2;
--
  function  disabled return boolean;
  procedure set_statistics(p_disable boolean);
  function  check_run(p_obj_id varchar2, p_obj_type varchar2 default null) return pls_integer;
--
  function put_start1 ( p_run   in out nocopy number,
                        p_group in out nocopy number,
                        p_process      varchar2,
                        p_obj_id       varchar2,
                        p_obj_type     varchar2,
                        p_details      varchar2,
                        p_obj_class_id varchar2,
                        p_short_name   varchar2,
                        p_name         varchar2,
                        p_stat pls_integer default null,
                        p_prec varchar2 default null) return varchar2;
--
  function put_start2 ( p_run in out nocopy number,
                        p_group   number,
                        p_process varchar2,
                        p_stat pls_integer default null,
                        p_prec varchar2 default null) return varchar2;
--
  function put_stop(p_run number) return varchar2;
--
  function get_group_id( p_obj_id       varchar2,
                         p_obj_type     varchar2,
                         p_details      varchar2) return number;
--
  function set_group_id( p_obj_id       varchar2,
                         p_obj_type     varchar2,
                         p_details      varchar2,
                         p_obj_class_id varchar2,
                         p_short_name   varchar2,
                         p_name         varchar2) return number;
--
  procedure start_report_job(p_job number,p_pos number);
--
  procedure stop_report_job (p_job number,p_pos number);
--
  function  start_prec(p_group number) return varchar2;
--
  procedure stop_prec;
--
  function  set_dict_object(p_obj_id	varchar2,	
                			p_obj_type	varchar2,
                			p_enable	boolean default null,
                			p_flags		pls_integer	default null,
                			p_add 		boolean default null) return number;
--
end stat_lib;
/
show errors

