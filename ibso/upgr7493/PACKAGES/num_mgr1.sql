prompt num_mgr
create or replace package
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/num_mgr1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
num_mgr
is
  CACHE_DEFAULT constant number := 20;
  INCREMENT_DEFAULT constant number := 1;
  ORDER_DEFAULT constant varchar2(1) := 'N';
  CYCLE_DEFAULT constant varchar2(1) := 'N';
  MAXVALUE_DEFAULT constant number :=  999999999999999999999999999;
  MINVALUE_DEFAULT constant number :=   -99999999999999999999999999;
  NL constant char(1) := chr(10);
  TB constant char(1) := chr(9);
  MIN_INCREMENT number := -99999999999999999999999999;
  MAX_INCREMENT number := 9999999999999999999999999999;
  SEQ_GROUPS_QTY integer := 10;

  e_seq_limit_value exception;
  pragma exception_init(e_seq_limit_value, -8004);
  e_inc_too_big exception;
  pragma exception_init(e_inc_too_big, -4003);
  e_val_too_big exception;
  pragma exception_init(e_val_too_big, -12899);
  e_seq_not_exists exception;
  pragma exception_init(e_seq_not_exists, -2289);

  function create_sys_numerator(p_class_id in varchar2, p_attr_id in varchar2, p_step in number default null,
    p_startval in number default null, p_min_value in number default null, p_max_value in number default null,
    p_cache in number default null, p_ordered in varchar2 default 'N', p_cycled in varchar2 default 'N',
    p_restart_on_max in varchar2 default 'N', p_seq in varchar2 default null, p_seq_only in boolean default false)
    return varchar2;

  procedure use_sys_numerator(p_class_id in varchar2, p_attr_id in varchar2, p_num_id in varchar2);

  procedure create_numerators(p_class_id in varchar2 default null, p_attr_id in varchar2 default null, p_rebuild in boolean default false);

  function create_user_numerator(p_code in varchar2, p_name in varchar2, p_step in number default null,
    p_startval in number default null, p_min_value in number default null, p_max_value in number default null,
    p_cache in number default 0, p_ordered in varchar2 default 'Y', p_cycled in varchar2 default 'N',
    p_restart_on_max in varchar2 default 'N',
    p_seqname in varchar2 default null)
    return varchar2;

  procedure restart_numerator(p_id in varchar2, p_start_value in number);

  procedure alter_numerator(p_id in varchar2, p_step in number default null, p_min_value in number default null,
    p_max_value in number default null, p_start_value in number default null, p_cache in number default null,
    p_ordered in varchar2 default null, p_cycled in varchar2 default null, p_restart_on_max in varchar2 default null, p_restart in number default null);

  procedure delete_numerator(p_id in varchar2, p_class_id in varchar2 default null, p_attr_id in varchar2 default null,
    p_force in boolean default false);

  procedure rename_numerator  (p_id in varchar2, p_new_code in varchar2, p_new_name in varchar2);

  procedure prepare_res_sequences;

  procedure set_property (p_id in varchar2, p_property in varchar2, p_value in varchar2);

  procedure generate_num_values_pkg;

  procedure num_to_sequence (p_id in varchar2, p_class_id in varchar2, p_attr_id in varchar2, p_rebuild in boolean default false);

  procedure create_seq(p_name in varchar2, p_sql in varchar2, p_grants_only boolean default false);

  procedure delete_seq(p_seqname in varchar2);

end;
/
show err

