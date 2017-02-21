prompt package partitioning_view
create or replace package partitioning_view is
  /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/partitioning_view1.sql $
  *  $Author: zikov $
  *  $Revision: 66709 $
  *  $Date:: 2015-02-19 11:49:53 #$
  */
  
  /* ��������������� ������� ��� �������������, ����������� � PARTITIONING_MGR */
  
  -- ���������� ������ �������� ������� �� ����������� id �������
  function get_cond_values_string(
    p_profile_id   varchar2,
    p_condition_id varchar2
  ) return clob;
  
  /*���������� 1, ���� ������ �� ��������� ����������
    � �����-���� �������, �������� �� ������� �������*/
  function is_default_condition_used(
    p_profile_id varchar2
  ) return varchar2;
  
  /*���������� 1, ���� ��������� �� ��������� ��������������
  � �����-���� �������, �������� �� ������� ���������� */
  function is_default_subcondition_used(
    p_profile_id varchar2
  ) return varchar2;
  
  /*���������� 1, ���� ������ ������������
    � �����-���� �������, �������� �� ������� ������� ��� ���������� */
  function is_condition_used_for_range(
    p_profile_id          varchar2, 
    p_attr_base_class_id  varchar2, 
    p_condition_value     varchar2
  ) return varchar2;

  /*���������� 1, ���� ������ ������������
    � �����-���� �������, �������� �� ������� ������� ��� ���������� */
  function is_condition_used_for_list(
    p_profile_id          varchar2, 
    p_condition_id        varchar2
  ) return varchar2;
  
  /*���������� 1, ���� ������ ������������
    � �����-���� �������, �������� �� ������� ������� ��� ���������� */
  function is_subcondition_used_for_range(
    p_profile_id          varchar2, 
    p_attr_base_class_id  varchar2, 
    p_condition_value     varchar2
  ) return varchar2;
  
  /*���������� 1, ���� ������ ������������
    � �����-���� �������, �������� �� ������� ������� ��� ���������� */
  function is_subcondition_used_for_list(
    p_profile_id          varchar2, 
    p_condition_id        varchar2
  ) return varchar2;
    
  -- ���������� ������� ��������� ������ � CLOB
  function get_dba_partition_cond(
    p_table_name         in varchar2,
    p_partition_name     in varchar2,
    p_prof_attr_base_cls in varchar2 := null
  ) return clob;
  
  -- ���������� ������� ��������� ��������� � CLOB
  function get_dba_subpartition_cond(
    p_table_name         in varchar2,
    p_partition_name     in varchar2,
    p_subpartition_name  in varchar2,
    p_prof_attr_base_cls in varchar2 := null
  ) return clob;

  -- ���������� ������� ��������� ������ ������� � CLOB
  function get_dba_index_cond(
    p_index_name         in varchar2,
    p_partition_name     in varchar2,
    p_prof_attr_base_cls in varchar2
  ) return clob;
  
  -- ���������� ������� ��������� ��������� ������� � CLOB
  function get_dba_subindex_cond(
    p_index_name         in varchar2,
    p_partition_name     in varchar2,
    p_subpartition_name  in varchar2,    
    p_prof_attr_base_cls in varchar2
  ) return clob;
  
  -- ���������� ������ ���������� ������� ����������� ������� ��� ������� ���
  function get_table_applied_conds_state(
    p_table_name         varchar2,
    p_is_for_subprofile  varchar2 := 'NO'
  ) return varchar2;
  
end partitioning_view;
/
show errors
