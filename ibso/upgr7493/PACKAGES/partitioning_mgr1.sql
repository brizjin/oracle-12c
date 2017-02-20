prompt package partitioning_mgr
create or replace package partitioning_mgr is
  /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/partitioning_mgr1.sql $
  *  $Author: vzhukov $
  *  $Revision: 124343 $
  *  $Date:: 2016-10-13 16:57:33 #$
  */

  LIST        constant varchar2(4) := 'LIST';
  RANGE       constant varchar2(5) := 'RANGE';
  REFER       constant varchar2(5) := 'REF';
  DEFAULT_VAL constant varchar2(7) := 'DEFAULT';
  MAXVALUE    constant varchar2(8) := 'MAXVALUE';
  ROW_MOVEMENT_ENABLED  constant varchar2(7) := 'ENABLED';
  ROW_MOVEMENT_DISABLED constant varchar2(8) := 'DISABLED';

  TYPE part_condition_rec IS RECORD (partition_number number , partition_name varchar2(4000), condition_values clob);
  TYPE part_condition_rec_tbl IS TABLE OF part_condition_rec;

  CANT_EDIT_APPLIED_PROF_NUMBER  constant integer := -20501;
  PROFILE_IS_NOT_EXIST_NUMBER    constant integer := -20502;
  CANT_EDIT_ASSIGNED_PROF_NUMBER constant integer := -20503;
  CANT_EDIT_APPLIED_COND_NUMBER  constant integer := -20504;
  ATTR_ID_MUST_N_BE_EMPTY_NUMBER constant integer := -20505;
  ATTR_CL_MUST_N_BE_EMPTY_NUMBER constant integer := -20506;
  CLASS_DOES_NOT_EXIST_NUMBER    constant integer := -20507;
  ATTR_CLS_MUST_BE_SMPL_LST_TYPE constant integer := -20508;
  PROF_COND_VALUE_ERROR_NUMBER   constant integer := -20509;
  COND_VALUE_CONVERT_ERR_NUMBER  constant integer := -20510;
  EN_ROW_MV_PRF_MST_HAVE_DEFPART constant integer := -20511;
  PROF_COND_VALUE_UNIQUE_NUMBER  constant integer := -20512;
  COND_VAL_MUST_N_BE_EMPT_NUMBER constant integer := -20513;
  PROFILE_ALREADY_EXISTS_NUMBER  constant integer := -20514;
  ATTR_CLS_MUST_BE_SMPL_RNG_TYPE constant integer := -20515;
  PRF_TYP_MUST_N_BE_EMPTY_NUMBER constant integer := -20516;
  CANT_DEL_ASSG_PROF_TO_OTH_PROF constant integer := -20517;
  DATA_TYPE_NOT_FOUND_ERR_NUMBER constant integer := -20518;
  SUBPROF_NOT_FOUND_ERR_NUMBER   constant integer := -20519;
  PROFILE_INVALID_NUMBER         constant integer := -20520;
  CLASS_HAS_NO_PROFILE_NUMBER    constant integer := -20521;
  NO_INSTANCES_NUMBER            constant integer := -20522;
  CLASS_NOT_FOUND_NUMBER         constant integer := -20523;
  UNACCEPT_DATE_FORMAT_NUMBER    constant integer := -20524;
  ERR_PROF_DATE_INTERVAL_PARAMS  constant integer := -20525;
  PROF_WITH_DEFPART_AND_INTERVAL constant integer := -20526;
  APPLY_PROFILE_ERROR_NUMBER     constant integer := -20527;
  ATTR_RATIO_MUST_BE_POSITIVE    constant integer := -20528;
  REF_PART_CAN_NOT_HAVE_COND     constant integer := -20529;
  REF_PART_CAN_NOT_HAVE_SUBPROFS constant integer := -20530;
  SUBPROF_TYPE_CAN_NOT_BE_REF    constant integer := -20531;
  CANT_ASSIGN_PROFILE_REF_PART   constant integer := -20532;
  PAR_CLASS_PROFILE_NOT_APPLIED  constant integer := -20533;
  PAR_CLASS_NO_PROFILE_ASSIGNED  constant integer := -20534;
  ATTR_MUST_BE_NOT_NULL          constant integer := -20535;
  ATTR_WITH_TYPE_NOT_EXISTS      constant integer := -20536;
  ATTR_CLS_MUST_BE_REF_TYPE      constant integer := -20537;
  ATTR_MUST_BE_NOT_INDEXED       constant integer := -20538;
  CANT_RECONC_REFPART_CH_EXISTS  constant integer := -20539;
  PAR_CLASS_INTERVAL_PROF_EXISTS constant integer := -20540;
  NO_TABLE_COLUMN                constant integer := -20541;
  PAR_CLASS_NOT_EXIST            constant integer := -20542;
  PAR_CLASS_NO_HAS_INSTANCE      constant integer := -20543;
  
  PART_SEPARATOR       constant varchar2(1)  := '#';
  SUBPART_SEPARATOR    constant varchar2(1)  := '_';
  
  -- ���������� ������ ������.
  function get_version return varchar2;

  -- ��������, ��� ��� ����� �������.
  function has_profile(p_class_id in varchar2) return boolean;
  
  -- ���������� id �������, ������������ ���
  function get_profile_id(p_class_id in varchar2) return classes.part_profile_id%type;
  
  -- �������� ������ �������, ������������ ��� ������������
  function get_part_columns(p_class_id      in varchar2,
                            p_profile_id    in varchar2 default null,
                            p_add_col_type  in boolean  default false,
                            p_get_real_cols in boolean  default false)
    return varchar2;

  -- ���������� ����� sql-������� �� ��������������� �������.
  function build_partitioning_sql(p_class_id in varchar2)
    return varchar2;

  function get_partitions_for_class(
    p_class_id            varchar2,
    p_part_prefix         varchar2,
    p_prof_type           varchar2,
    p_attr_base_class_id  varchar2,
    p_is_for_subpartition boolean default false
  ) return part_condition_rec_tbl;

  -- ���������� ������ ��� �������� �������.
  function get_part_sql(p_class_id varchar2)
    return varchar2;

  -- ���������� ������������� ������� ��� ������� 
  -- ���� �� ����� ������, ���� �� ����� �������
  function get_class_table_profile(
    p_class_id   varchar2 default null,
    p_table_name varchar2 default null
  ) return varchar2;

  -- �������� �� ������� �����-���� �������
  function is_profile_assigned(p_id in partitioning_profiles.id%type) return boolean;
  
  -- �������� �� ������� � �����-���� �������
  function is_profile_applied(p_id in partitioning_profiles.id%type) return boolean;

  -- ���������� ������ ���������� ������� ��� ���������� � ���
  function get_prof_applic_to_class_state(
    p_id       in partitioning_profiles.id%type, 
    p_class_id in classes.id%type
  ) return varchar2;

  -- �������� �� ������� ��� ����������� ���
  function is_profile_applied_to_class(p_id       in partitioning_profiles.id%type,
                                       p_class_id in classes.id%type)
    return boolean;

  -- �������� �� ������� "��������� DEFAULT ������" � �����-���� �������
  function is_has_default_part_applied(p_prof_id in partitioning_conditions.profile_id%type)
    return boolean;

  /* ������� ������� ������������
    p_id - �������������
    p_name - ������������
    p_type - ��� ������������
    p_attr_id - ������� ���
    p_self_class_id - ��� �������� �������� ���
    p_has_default_part - ������� �������� DEFAULT ��������
    p_row_movement - ������� ����������� �����
    p_subprofile_id - ������������� ������� ���������
    p_ratio - ����������� ������
  */
  procedure create_profile(
    p_id               in partitioning_profiles.id%type,
    p_name             in partitioning_profiles.name%type,
    p_type             in partitioning_profiles.type%type,
    p_attr_id          in partitioning_profiles.attr_id%type,
    p_self_class_id    in partitioning_profiles.self_class_id%type,
    p_has_default_part in partitioning_profiles.has_default_part%type default '1',
    p_row_movement     in partitioning_profiles.row_movement%type default '0',
    p_subprofile_id    in partitioning_profiles.subprofile_id%type default null,
    p_interval_value   in partitioning_profiles.interval_value%type default null,
    p_interval_unit    in partitioning_profiles.interval_unit%type default null,
    p_ratio            in partitioning_profiles.ratio%type default 1
  );

  /* �������� ������� ������������
    p_id - �������������
    p_new_name - ������������
    p_new_type - ��� ������������
    p_new_attr_id - ������� ���
    p_new_self_class_id - ��� �������� �������� �������� ������� ���
    p_new_has_default_part - ������� �������� DEFAULT ��������
    p_new_row_movement - ������� ���������� �������������� �������� �������� ���
    p_new_subprofile_id - ������������� ������� ���������
  */
  procedure edit_profile(
    p_id                   in partitioning_profiles.id%type,
    p_new_name             in partitioning_profiles.name%type,
    p_new_type             in partitioning_profiles.type%type,
    p_new_attr_id          in partitioning_profiles.attr_id%type,
    p_new_self_class_id    in partitioning_profiles.self_class_id%type,
    p_new_has_default_part in partitioning_profiles.has_default_part%type,
    p_new_row_movement     in partitioning_profiles.row_movement%type,
    p_new_subprofile_id    in partitioning_profiles.subprofile_id%type default null,
    p_interval_value       in partitioning_profiles.interval_value%type default null,
    p_interval_unit        in partitioning_profiles.interval_unit%type default null,
    p_new_ratio            in partitioning_profiles.ratio%type default 1
  );
  
  /* ������� ������� ������������
    p_id - �������������
  */
  procedure delete_profile(p_id in partitioning_profiles.id%type);

  /* ��������� �������� ��� �� ������������� ������� ������� ������������
     � ���������� ID ����� ������ �������
    p_prof_id - ������������� �������
    p_cond_id - ������������� �������
  */
  function add_profile_condition(p_prof_id    in partitioning_conditions.profile_id%type,
                                 p_cond_value in partitioning_conditions.condition_value%type) return pls_integer;

  /* ��������� �������� ������������� ������� ������� ������������
    p_prof_id - ������������� �������
    p_cond_id - ������������� �������
    p_cond_value - �������� �������
    p_chk_cond_appl - ���������, ��������� �� �������
  */
  procedure add_profile_condition_value(p_prof_id    in partitioning_conditions.profile_id%type,
                                        p_cond_id    in partitioning_conditions.condition_id%type,
                                        p_cond_value in partitioning_conditions.condition_value%type,
                                        p_chk_cond_appl in boolean default true);

  /* ������� �������� ������� ������� ������������
    p_prof_id - ������������� �������
    p_cond_id - ������������� �������
    p_cond_value - �������� �������
  */
  procedure delete_profile_condition_value(p_prof_id    in partitioning_conditions.profile_id%type,
                                           p_cond_id    in partitioning_conditions.condition_id%type,
                                           p_cond_value in partitioning_conditions.condition_value%type);

  /* ������� ������� ������� ������������ (��� �������� �������)
    p_prof_id - ������������� �������
    p_cond_id - ������������� �������
  */
  procedure delete_profile_condition(p_prof_id in partitioning_conditions.profile_id%type,
                                     p_cond_id in partitioning_conditions.condition_id%type);

  /* ������������ �������� ���������� ������������� �������� ������� � ���������� ��������������� ��������
    p_prof_id - ������������� �������
    p_cond_value - �������� �������
  */
  function get_normalized_value(p_prof_id varchar2, p_cond_value varchar2) return varchar2;

  /* ������������� ������� ���
    p_id - ������������� �������
    p_class_id - ������������� ���
  */
  procedure set_profile(p_id       in classes.part_profile_id%type,
                        p_class_id in classes.id%type);

  /* �������� �� ������� ��� 
    p_id - ������������� �������
    p_class_id - ������������� ���
  */
  function is_profile_applicable(p_id       in classes.part_profile_id%type,
                                 p_class_id in classes.id%type) return pls_integer;

  -- �������� �� ������� ������������������
  function is_subprofile_assigned(p_id part_subprofs.id%type) return boolean;

  -- �������� �� ������� ������������������
  function is_subprofile_applied(p_id in part_subprofs.id%type) return boolean;

  -- ���� �� ����������� ������ �� ������ ����� �� REFERENCE PARTITIONING
  function is_class_has_ref_part(p_class in varchar2) return boolean;

  -- ������� ������� ������������������
  procedure create_subprofile(
    p_id               in part_subprofs.id%type,
    p_name             in part_subprofs.name%type,
    p_type             in part_subprofs.type%type,
    p_attr_id          in part_subprofs.attr_id%type,
    p_self_class_id    in part_subprofs.self_class_id%type,
    p_has_default_part in part_subprofs.has_default_part%type default '1'
  );

  -- �������� ������� ������������������
  procedure edit_subprofile(
    p_id                   in part_subprofs.id%type,
    p_new_name             in part_subprofs.name%type,
    p_new_type             in part_subprofs.type%type,
    p_new_attr_id          in part_subprofs.attr_id%type,
    p_new_self_class_id    in part_subprofs.self_class_id%type,
    p_new_has_default_part in part_subprofs.has_default_part%type
  );

  -- ������� ������� ������������������
  procedure delete_subprofile(p_id in part_subprofs.id%type);

  -- ��������� �������� ������� ������������������
  procedure add_subprof_cond_value(
    p_subprof_id    in part_subprof_conds.subprofile_id%type,
    p_cond_id       in part_subprof_conds.condition_id%type,
    p_cond_value    in part_subprof_conds.condition_value%type,
    p_chk_cond_appl in boolean default true
  );

  -- ��������� �������� ��� �� ������������� ������� ������� ���������
  -- � ���������� ID ����� �������
  function add_subprof_cond(
    p_subprof_id in part_subprof_conds.subprofile_id%type,
    p_cond_value in part_subprof_conds.condition_value%type
  ) return pls_integer;

  -- ������� ��� ������� ��������� ������� ������������������
  procedure delete_subprof_cond(
    p_subprof_id in part_subprof_conds.subprofile_id%type,
    p_cond_id    in part_subprof_conds.condition_id%type);

  -- ������� �������� ������� ������� ������������������
  procedure delete_subprof_cond_value(
    p_subprof_id in part_subprof_conds.subprofile_id%type,
    p_cond_id    in part_subprof_conds.condition_id%type,
    p_cond_value in part_subprof_conds.condition_value%type);

  /*��������� ������� � ���: 
      ���� ������� ��������, �� �� �������, � ��� ����� ����� ���������� - ������� ��� ���������������
      ���� � ������� ��������� ����� �������, � ������� ��� ��� �������������� �� ������� - ������� ��� ���������������,
       �� ����������� LIST, RANGE, LIST-LIST, RANGE-LIST
      ���� � ������� �������� �������� ROW MOVEMENT - ������ �������� ROW MOVEMENT ����������� � ������� ��� (������� �� ���������������)
      ���� ������� ��������, �� ��� �� ����� ����� ����������� - ���������� NO_INSTANCES_NUMBER*/
  procedure apply_profile_to_class(
    p_class_id   classes.id%type,
    p_verbose    boolean  default false,
    p_pipe_name  varchar2 default 'DEBUG');

  -- ��������������� FOREIGN KEY, �� ������� �������� REFERENCE PARTITIONING
  procedure rename_ref_part_fk(p_class_id varchar2);

  -- ��� ��������� ������� ����������������� ��� ���������� ������� � ���� ��������� (reference partitioning)
  -- ��� (������� ������������� ����������� �� reference partitioning)
  procedure reset_dependent_profiles(p_class_id in varchar2);

end partitioning_mgr;
/
show errors
