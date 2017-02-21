prompt num_interface
create or replace package
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/num_interface1.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
num_interface
  is
  type num_info_t is record
    (id varchar2(30),
     code varchar2(50),
     name varchar2(128),
     step number,
     start_value  number,
     min_value number,
     max_value number,
     cache_size number,
     order_flag varchar2(1),
     cycle_flag varchar2(1),
     restart_on_max varchar2(1),
     system varchar2(1),
     seqname varchar2(30),
     seq_grp number);

  type num_info_tbl_c is table of num_info_t index by varchar2(30);

  E_NUM_ERROR exception;
  pragma EXCEPTION_INIT (E_NUM_ERROR, -20090);
  E_NUM_NOT_EXIST  exception;
  pragma EXCEPTION_INIT (E_NUM_NOT_EXIST, -20091);
  E_SEQ_LIMIT_VALUE exception;
  pragma exception_init(E_SEQ_LIMIT_VALUE, -8004);
  E_INC_TOO_BIG exception;
  pragma exception_init(E_INC_TOO_BIG, -4003);
  E_VAL_TOO_BIG exception;
  pragma exception_init(E_VAL_TOO_BIG, -12899);
  E_SEQ_NOT_EXISTS exception;
  pragma exception_init(E_SEQ_NOT_EXISTS, -2289);
  MAXVALUE_DEFAULT constant number :=  999999999999999999999999999;
  MINVALUE_DEFAULT constant number :=   -99999999999999999999999999;


  procedure num_exist (p_id in varchar2, p_num_info in out nocopy num_info_t, p_class_id in varchar2 default null, p_attr_id in varchar2 default null);

  procedure reset_numerator  (p_id in varchar2);

  function next$ (p_class_id in varchar2, p_attr_id in varchar2, p_id in varchar2, p_maxlen in pls_integer default null) return number;
  pragma restrict_references (next$, wnds, wnps, TRUST);

  function get_num_sequence (p_id in varchar2) return varchar2;

  procedure send_event (p_id in varchar2);

  procedure get_num_info(p_id in varchar2, p_num_info out num_info_t);

  function get_num_id (p_code in varchar2 default null, p_class_id in varchar2 default null, p_attr_id in varchar2 default null,
    p_raise in boolean default true) return varchar2;

  function is_close_to_max (p_id in varchar2, p_percent in number default 10) return boolean;

  procedure restart_numerator(p_id in varchar2, p_start_value in number);

  function get_property(p_id in varchar2, p_property in varchar2) return varchar2;

end;
/
show err
