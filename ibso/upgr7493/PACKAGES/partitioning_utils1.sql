prompt package partitioning_utils
create or replace package partitioning_utils is
  /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/partitioning_utils1.sql $
  *  $Author: vzhukov $
  *  $Revision: 113802 $
  *  $Date:: 2016-07-07 14:43:25 #$
  */

  /* ����� ������� ������� PARTITIONING_MGR � PARTITIONING_VIEW */

  DATE_FORMAT  constant varchar2(10) := 'DD/MM/YYYY';
  
  PROFILE_NOT_ASSIGNED constant varchar2(12) := 'NOT_ASSIGNED';
  PROFILE_ASSIGNED     constant varchar2(8)  := 'ASSIGNED';
  PROFILE_APPLIED      constant varchar2(7)  := 'APPLIED';
  PROFILE_MODIFIED     constant varchar2(8)  := 'MODIFIED';
  UNKNOWN_STATE        constant varchar2(13) := 'UNKNOWN_STATE';

  PROFILE_VALID        constant varchar2(5)  := 'VALID';
  PROFILE_INVALID      constant varchar2(7)  := 'INVALID';
  
  -- ����������� �������� ������� ������
  COMMA         constant varchar2(2) := ', ';
  -- ����� ����������� �������� ������� ������
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

  -- ��������� ��������� ���������� ������ ������� ��� LIST
  function get_dba_cond_tbl_for_list(
    p_table_name    varchar2
  ) return tbl_of_part_cond_values_tbl;
  
  -- ��������� ��������� ���������� ��������� ������� ��� LIST
  function get_dba_subcond_tbl_for_list(
    p_table_name  varchar2
  ) return part_subpart_cond_value_tbl;
  
    -- ���������� ������� ��������� �������� ������� ��� LIST 
  function get_profile_condition_for_list(p_profile_id varchar2) return tbl_of_part_cond_values_tbl;
  
  -- ���������� ������� ��������� �������� ���������� ��� LIST
  function get_subprof_condition_for_list(p_subprofile_id varchar2) return tbl_of_part_cond_values_tbl;

  -- ���������� ������� �������� ���������� ��� RANGE
  function get_subprof_cond_for_range(p_subprofile_id varchar2, p_subprof_attr_base_class_id  varchar2) return subpart_cond_values_tbl;

  -- ���������� �������������� ������� ������ LIST
  function get_not_applied_cond_list (
    p_table_name         varchar2,
    p_profile_id         varchar2
  ) return tbl_of_part_cond_values_tbl;
  
  -- ���������� �������������� ������� ��������� LIST
  function get_not_applied_subcond_list(
    p_table_name varchar2,
    p_subprofile_id varchar2) return subpart_cond_values_for_list;

  -- ���������� �������������� ������� ������ RANGE
  function get_not_applied_cond_range (
    p_table_name         varchar2,
    p_profile_id         varchar2,
    p_attr_base_class_id varchar2) return part_cond_values_tbl;

  -- ���������� �������������� ������� ��������� RANGE
  function get_not_applied_subcond_range(
    p_table_name varchar2,
    p_subprofile_id varchar2,
    p_attr_base_class_id varchar2) return subpart_cond_values_for_range;

  -- ���������� ������ �������� ������� �� ���������� ���������
  function get_cond_values_string(p_cond_values part_cond_values_tbl) return clob;

  -- ���������� ��������� ��������, ���������� �� ������, �������� �� ', ' (COMMA)
  function split_cond_values(p_values_str clob) return part_cond_values_tbl;
  
  /*���������� ������, ���� ��������� p_col ������� 
    ����� �� ��������� ��������� p_multy_cols */
  function are_col_incl_to_multy_col(
    p_col         part_cond_values_tbl,
    p_multy_cols  tbl_of_part_cond_values_tbl
  ) return boolean;
  
  /*���������� ������, ���� ���������� ��������� 
    � �� �������� � ���������� ����� */
  function are_collections_equal(
    col1 part_cond_values_tbl,
    col2 part_cond_values_tbl
  ) return boolean;

  -- ���������� �������� ��������� ��� RANGE-�������
  function get_interval_str(
    p_attr_base_class_id  varchar2,
    p_interval_value      pls_integer,
    p_interval_unit       varchar2
  ) return varchar2 deterministic;

  -- ���������� ������� �������� ��������� ��� ������� ���, ���������������� �� RANGE
  function get_range_interval_for_table(
    p_table_name         varchar2
  ) return varchar2;

  -- �������� �������� ���� LONG � CLOB ���������� �������
  function cast_long_to_clob_val_for_cur(
    p_csr         in pls_integer, 
    p_column_num  in pls_integer
  ) return clob;  

  /*�������� ��������� ��� ��������� �������� ������� �� dba_tab_partitions 
    � ������� ������� (�� ��������� � DATE_FORMAT)*/
  function cast_dba_cond_date_value(
    p_dba_date             clob,
    p_cast_to_date_format  varchar2 := DATE_FORMAT
  ) return varchar2 deterministic;
  
  -- �������� ��������� ��� ��������� �������� ������� �� dba_tab_partitions
  function cast_dba_cond_number_value(
    p_dba_number                 clob
  ) return varchar2 deterministic;  
end partitioning_utils;
/
show errors
