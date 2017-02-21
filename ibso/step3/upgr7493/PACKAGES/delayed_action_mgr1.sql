prompt delayed_action_mgr
create or replace package delayed_action_mgr is
  -- ����� ��� ������ � ����������� ����������

  -- ������ ���������� ��������
  GROUP_FILL_SYSTEM_COLUMNS constant varchar2(20) := 'FILL_SYSTEM_COLUMNS'; -- ������ �������� �� ���������� ��������� �������
  GROUP_CREATE_RESTRICTIONS constant varchar2(20) := 'CREATE_RESTRICTIONS'; -- ������ �������� �� �������� �����������

  -- ��� ����������� ��������
  FILL_COLLECTION constant varchar2(20) := 'FILL_COLLECTION'; -- ���������� �������-�������
  FILL_DUPLICATE  constant varchar2(20) := 'FILL_DUPLICATE';  -- ���������� ������������� �������
  SET_NOT_NULL    constant varchar2(20) := 'SET_NOT_NULL';    -- �������� ����������� NOT_NULL
  CREATE_INDEX    constant varchar2(20) := 'CREATE_INDEX';    -- �������� �������

  -- ��������� ���������� ����������� ��������
  ADDED   constant number(1) := 0;  -- ���������, �� ���� ������� ��� ���������
  SUCCESS constant number(1) := 1;  -- �������� ���������� ����������� ��������
  ERROR   constant number(1) := -1; -- ������ ���������� ����������� ��������

  -- ���������� ���������� ��������
  PRIOR_SET_NOT_NULL     constant number(2) := 20;
  PRIOR_FILL_DUPLICATE   constant number(2) := 10;
  PRIOR_FILL_COLLECTION  constant number(2) := 10;
  PRIOR_ADD_UNIQUE_INDEX constant number(2) := 20;
  PRIOR_COLLECTION_SET_NOT_NULL constant number(2) := 20;


  -- ������ ������
  function get_version return varchar2;    
  
  -- ������� ������� ��������� �� ���������� ���������
  procedure clear_delayed_actions_log;

  -- ����� � ������� ����������������� ������ ��������� � ���������� ���������� ��������
  procedure show_delayed_actions_log(
      p_verbose boolean default false,     -- ������� ��������� � pipe
      p_pipe_name varchar2 default 'DEBUG' -- ��� ������
  );

  -- ��������� ������� � ������� ���������� ��������
  -- ���������� true, ���� ��� ���������� �������� ������� ���������, false - ���� ������ ����������
  function execute_delayed_actions(
      p_action_groups varchar2,             -- ������ ��������
      p_verbose boolean default false,      -- ������� ��������� � pipe
      p_pipe_name varchar2 default 'DEBUG', -- ��� ������
      p_error_msg out varchar2              -- ����� ������ ���������� ����������� ��������
  ) return boolean;

  -- �������� ������ �� ������� ���������� ��������
  procedure delete_delayed_action(
      p_action_type  varchar2,      -- ��� ��������
      p_class_id     varchar2,      -- �������� ��� ���
      p_class_column_qual varchar2, -- ������������ ������� ���
      p_index_name   varchar2       -- ������������ �������
  );
  
  -- ���������� ������ � ������ ���������� ��������
  procedure add_delayed_action(
      p_action_group varchar2,      -- ������ ��������
      p_action_type  varchar2,      -- ��� ��������
      p_priority     number,        -- ���������
      p_class_id     varchar2,      -- �������� ��� ���
      p_class_column_qual varchar2, -- ������������ ������� ���
      p_index_name   varchar2       -- ������������ �������
  );

  -- ���������� ������� ����������� ��������
  procedure update_delayed_action_status(
      p_action_type       varchar2, -- ��� ��������
      p_class_id          varchar2, -- �������� ��� ���
      p_class_column_qual varchar2, -- ������������ ������� ���
      p_index_name        varchar2, -- ������������ �������
      p_execute_success   number,   -- ��������� ����������
      p_execute_errors    varchar2  -- ����� ������
  );
  
  -- ���������� ���������� ���������� ��������, ������� �� ���������, ���� ��������� � �������
  function get_num_actions_to_perform return number;
  
end delayed_action_mgr;
/
sho err
