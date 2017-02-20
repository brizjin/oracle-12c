prompt package partitioning_utils
create or replace package partitioning_utils is
  /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/partitioning_utils1.sql $
  *  $Author: vzhukov $
  *  $Revision: 113802 $
  *  $Date:: 2016-07-07 14:43:25 #$
  */

  /* Общие функции пакетов PARTITIONING_MGR и PARTITIONING_VIEW */

  DATE_FORMAT  constant varchar2(10) := 'DD/MM/YYYY';
  
  PROFILE_NOT_ASSIGNED constant varchar2(12) := 'NOT_ASSIGNED';
  PROFILE_ASSIGNED     constant varchar2(8)  := 'ASSIGNED';
  PROFILE_APPLIED      constant varchar2(7)  := 'APPLIED';
  PROFILE_MODIFIED     constant varchar2(8)  := 'MODIFIED';
  UNKNOWN_STATE        constant varchar2(13) := 'UNKNOWN_STATE';

  PROFILE_VALID        constant varchar2(5)  := 'VALID';
  PROFILE_INVALID      constant varchar2(7)  := 'INVALID';
  
  -- Разделитель значений условия секции
  COMMA         constant varchar2(2) := ', ';
  -- Длина разделителя значений условия секции
  COMMA_LENGTH  constant pls_integer := length(COMMA);
  
  type part_cond_values_tbl        is table of partitioning_conditions.condition_value%type;
  type tbl_of_part_cond_values_tbl is table of part_cond_values_tbl;
  
  type subpart_cond_values_tbl     is table of part_subprof_conds.condition_value%type;
  
  type subpart_cond_value is record (
    subpart_name   dba_tab_subpartitions.subpartition_name%type,
    subpart_values part_cond_values_tbl
  );  
  type subpart_cond_value_tbl is table of subpart_cond_value;
  
  
  type part_subpart_cond_value is record (
    partition_name dba_tab_subpartitions.partition_name%type,
    subpart_cond_values subpart_cond_value_tbl
  );  
  type part_subpart_cond_value_tbl is table of part_subpart_cond_value;
  
  type subpart_cond_value_for_list is record (
    partition_name   dba_tab_partitions.partition_name%type,
    cond_values      part_cond_values_tbl
  );
  type subpart_cond_values_for_list is table of subpart_cond_value_for_list;
  
  type subpart_cond_value_for_range is record (
    partition_name   dba_tab_partitions.partition_name%type,
    condition_value  part_subprof_conds.condition_value%type
  );
  type subpart_cond_values_for_range is table of subpart_cond_value_for_range;

  -- Заполняем коллекцию значениями секций таблицы для LIST
  function get_dba_cond_tbl_for_list(
    p_table_name    varchar2
  ) return tbl_of_part_cond_values_tbl;
  
  -- Заполняем коллекцию значениями подсекций таблицы для LIST
  function get_dba_subcond_tbl_for_list(
    p_table_name  varchar2
  ) return part_subpart_cond_value_tbl;
  
    -- Возвращает таблицу коллекций значений профиля для LIST 
  function get_profile_condition_for_list(p_profile_id varchar2) return tbl_of_part_cond_values_tbl;
  
  -- Возвращает таблицу коллекций значений подпрофиля для LIST
  function get_subprof_condition_for_list(p_subprofile_id varchar2) return tbl_of_part_cond_values_tbl;

  -- Возвращает таблицу значений подпрофиля для RANGE
  function get_subprof_cond_for_range(p_subprofile_id varchar2, p_subprof_attr_base_class_id  varchar2) return subpart_cond_values_tbl;

  -- Возвращает несуществующие условия секций LIST
  function get_not_applied_cond_list (
    p_table_name         varchar2,
    p_profile_id         varchar2
  ) return tbl_of_part_cond_values_tbl;
  
  -- Возвращает несуществующие условия подсекций LIST
  function get_not_applied_subcond_list(
    p_table_name varchar2,
    p_subprofile_id varchar2) return subpart_cond_values_for_list;

  -- Возвращает несуществующие условия секций RANGE
  function get_not_applied_cond_range (
    p_table_name         varchar2,
    p_profile_id         varchar2,
    p_attr_base_class_id varchar2) return part_cond_values_tbl;

  -- Возвращает несуществующие условия подсекций RANGE
  function get_not_applied_subcond_range(
    p_table_name varchar2,
    p_subprofile_id varchar2,
    p_attr_base_class_id varchar2) return subpart_cond_values_for_range;

  -- Возвращает строку значений условия по переданной коллекции
  function get_cond_values_string(p_cond_values part_cond_values_tbl) return clob;

  -- Возвращает коллекцию значений, полученной из строки, разбитой по ', ' (COMMA)
  function split_cond_values(p_values_str clob) return part_cond_values_tbl;
  
  /*Возвращает истину, если коллекция p_col явлется 
    одной из коллекций коллекции p_multy_cols */
  function are_col_incl_to_multy_col(
    p_col         part_cond_values_tbl,
    p_multy_cols  tbl_of_part_cond_values_tbl
  ) return boolean;
  
  /*Возвращает истину, если количество элементов 
    и их значения в коллекциях равны */
  function are_collections_equal(
    col1 part_cond_values_tbl,
    col2 part_cond_values_tbl
  ) return boolean;

  -- Возвращает значение интервала для RANGE-профиля
  function get_interval_str(
    p_attr_base_class_id  varchar2,
    p_interval_value      pls_integer,
    p_interval_unit       varchar2
  ) return varchar2 deterministic;

  -- Возвращает текущее значение интервала для таблицы ТБП, секционированной по RANGE
  function get_range_interval_for_table(
    p_table_name         varchar2
  ) return varchar2;

  -- Приводит значение типа LONG к CLOB указанного курсора
  function cast_long_to_clob_val_for_cur(
    p_csr         in pls_integer, 
    p_column_num  in pls_integer
  ) return clob;  

  /*Приводит выражение для получения значения условия из dba_tab_partitions 
    к нужному формату (по умолчанию к DATE_FORMAT)*/
  function cast_dba_cond_date_value(
    p_dba_date             clob,
    p_cast_to_date_format  varchar2 := DATE_FORMAT
  ) return varchar2 deterministic;
  
  -- Приводит выражение для получения значения условия из dba_tab_partitions
  function cast_dba_cond_number_value(
    p_dba_number                 clob
  ) return varchar2 deterministic;  
end partitioning_utils;
/
show errors
