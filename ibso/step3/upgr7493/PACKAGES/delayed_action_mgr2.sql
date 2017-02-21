prompt delayed_action_mgr body
create or replace package body delayed_action_mgr is

-- ������ ���������� �������� ��� ������ � ������� ����������������� ������
delayed_actions_log "CONSTANT".STRING_TABLE;

-- ������ ������
function get_version return varchar2 is
begin
    return '1.0';
end;

-- ���������� ������� ����������� ��������
procedure update_delayed_action_status(
  p_action_type       varchar2,
  p_class_id          varchar2,
  p_class_column_qual varchar2,
  p_index_name        varchar2,
  p_execute_success   number,
  p_execute_errors    varchar2
  ) is
begin
    update delayed_actions 
        set execute_date    = sysdate,           -- ���� � ����� ���������� ��������
            execute_success = p_execute_success, -- ������� ���������� ���������� ��������
            execute_errors  = p_execute_errors   -- ������ ��� ���������� ��������
        where action_type       = p_action_type
        and   class_id          = p_class_id
        and   ((class_column_qual is null and p_class_column_qual is null) or (class_column_qual = p_class_column_qual))
        and   ((index_name is null and p_index_name is null) or (index_name = p_index_name));
end;

-- ������� ������� ��������� �� ���������� ���������
procedure clear_delayed_actions_log is
begin
  delayed_actions_log.delete;
end;

-- ����� � ������� ����������������� ������ ��������� � ���������� ���������� ��������
procedure show_delayed_actions_log(p_verbose boolean default false, p_pipe_name varchar2 default 'DEBUG') is
begin
    if delayed_actions_log.count = 0 then
        return;
    end if;
    storage_utils.verbose := p_verbose;
    storage_utils.pipe_name := p_pipe_name;
    storage_utils.ws(message.gettext('EXEC', 'DELAYED_ACTIONS_ADD_START'));
    for i in delayed_actions_log.first..delayed_actions_log.last loop
        storage_utils.ws(' '||delayed_actions_log(i));
    end loop;
    storage_utils.ws(message.gettext('EXEC', 'DELAYED_ACTIONS_ADD_END'));
    delayed_actions_log.delete;
end;

-- �������� ������ �� ������� ���������� ��������
procedure delete_delayed_action(p_action_type varchar2,p_class_id varchar2,p_class_column_qual varchar2,p_index_name varchar2) is
begin
    delete from delayed_actions 
        where action_type = p_action_type
        and   class_id    = p_class_id
        and   class_column_qual = p_class_column_qual
        and   index_name  = p_index_name;
end;

-- ���������� ������ � ������ ���������� ��������
procedure add_delayed_action(
    p_action_group varchar2,
    p_action_type  varchar2,
    p_priority     number,
    p_class_id     varchar2,
    p_class_column_qual varchar2,
    p_index_name   varchar2
) is
v_msg varchar2(1000);
begin
    begin
        insert into delayed_actions
            ( action_group,
              action_type,
              priority,
              class_id,
              class_column_qual,
              index_name,
              execute_date,
              execute_success,
              execute_errors
            ) 
          values
            ( p_action_group,
              p_action_type, 
              p_priority,
              p_class_id, 
              p_class_column_qual, 
              p_index_name,
              null, 
              ADDED, 
              null
            );
    exception when DUP_VAL_ON_INDEX then
        -- ���� ����� �������� ��� ���������� ���� ��� ���� - ������� ��� ��������������
        update delayed_actions 
            set action_group    = p_action_group,
                priority        = p_priority,
                execute_date    = null,
                execute_success = ADDED,
                execute_errors  = null
            where action_type = p_action_type
            and   class_id    = p_class_id
            and   class_column_qual = p_class_column_qual
            and   index_name  = p_index_name;
    end;
    
    if p_index_name is not null then
        v_msg := message.gettext('CLS', 'DELAYED_ACTION_ADD_INDEX', p_action_type, p_index_name, p_class_id);
    elsif p_class_column_qual is not null then
        v_msg := message.gettext('CLS', 'DELAYED_ACTION_ADD_QUAL', p_action_type, p_class_column_qual, p_class_id);
    end if;
    -- ������� ���������� �� ���������� �������� � ������ ��������� ��� �������� ����������������� ������
    delayed_actions_log(delayed_actions_log.count+1) := v_msg;
end;

-- ��������� ������� � ������� ���������� ��������
function execute_delayed_actions(p_action_groups varchar2, p_verbose boolean default false, p_pipe_name varchar2 default 'DEBUG', p_error_msg out varchar2) return boolean is
v_success        number;
v_errors         varchar2(4000);
v_record_count   pls_integer;
v_table_name     varchar2(30);
v_table_owner    varchar2(30);
v_invalid_action boolean; 
v_msg            varchar2(1000);
v_result         boolean;
v_action_groups  varchar2(32000);
v_column_info    class_utils.COLUMN_DEFINITION;

  procedure SetError(p_msg in varchar2) is
  begin
      v_success := ERROR;
      v_errors := substr(p_msg,1,4000);
  end;
  
begin
    storage_utils.verbose := p_verbose;
    storage_utils.pipe_name := p_pipe_name;

    storage_utils.ws(message.gettext('EXEC', 'DELAYED_ACTIONS_EXEC_START'));
    storage_utils.ws('������ �� ������� ���������� ��������: '||nvl(p_action_groups, '�� �����'));

    v_record_count := 0;
    v_result := true;
    p_error_msg := null;

    -- ���������� ������ �� ������� ���������� ��������
    if p_action_groups is not null then
        v_action_groups := replace(p_action_groups,' ',''); -- ������ ��� �������
        v_action_groups := '#'||replace(v_action_groups,',','#')||'#'; 
    end if;
 
    for x in ( select (select max(t2.distance) from class_relations t2
                              where t2.child_id = t.class_id) distance,
                      t.action_type,t.class_id,t.class_column_qual,t.index_name, t.rowid
                      from delayed_actions t
                      where (p_action_groups is null or instr(v_action_groups,'#'||t.action_group||'#')>0 )
                      and (t.execute_success is null or t.execute_success<>SUCCESS)
                      order by 1, t.class_id, t.priority
    ) loop
      begin
          v_invalid_action := false;
          v_errors := null;
          v_success := SUCCESS;
          storage_mgr.class2table(v_table_name, v_table_owner, x.class_id, null);
      
          if v_table_name is null then
              -- ���� ��� ������� � ������ - �������� ��������� �� �����. ������ ������� ���, ��� ��� ������������
              v_invalid_action := true; 
            
          elsif x.action_type = FILL_COLLECTION then
              -- ���������� �������-������� 
              if class_utils.get_column_info(x.class_id, x.class_column_qual, v_column_info) then
                  if v_column_info.base = "CONSTANT".COLLECTION  then
                      storage_utils.update_empty_collections(v_table_name, v_column_info.name, x.class_id, true);
                  else
                      -- ���� ������� �� �������� �������� - �������� ��������� �� �����. ������ ������� ���, ��� ��� ������������
                      v_invalid_action := true; 
                  end if;
              else
                  -- ���� ��� ������� � ������� - �������� ��������� �� �����. ������ ������� ���, ��� ��� ������������
                  v_invalid_action := true; 
              end if;

          elsif x.action_type = FILL_DUPLICATE then
              -- ���������� ������������� �������
              if class_utils.get_column_info(x.class_id, x.class_column_qual, v_column_info) then
                  if v_column_info.mapped_from is not null then
                      storage_mgr.map_column_data_cons_indexes(v_column_info.mapped_from, v_table_owner, v_table_name, v_column_info.name);
                  else
                      -- ���� ������� �� �������� ������������� - �������� ��������� �� �����. ������ ������� ���, ��� ��� ������������
                      v_invalid_action := true; 
                  end if;
              end if;

          elsif x.action_type = SET_NOT_NULL then
              -- ����������� constraint NOT NULL
              if class_utils.get_column_info(x.class_id, x.class_column_qual, v_column_info) then
                  storage_utils.set_column_nullable(v_table_name, v_column_info.name, x.class_id, x.class_column_qual, false);
              end if;

          elsif x.action_type = CREATE_INDEX then
              -- ����������� ������
              if part_mgr.Create_Index(p_Name => x.index_name) = '3' then
                  SetError(message.gettext('CLS', 'DELAYED_ACTION_ERROR', '������ �������� ������� '||x.index_name));
              end if;
        
          else
              SetError(message.gettext('CLS', 'DELAYED_ACTION_UNKNOWN_TYPE', x.action_type));
          end if;

      exception when others then
          SetError(message.gettext('CLS', 'DELAYED_ACTION_ERROR', substr(sqlerrm,1,4000)));
      end;
      
      if v_invalid_action then
          -- ���� �������� ������������ (��� ������ ��������� �� ����������) - ������ ���
          delete from delayed_actions where rowid=x.rowid;
      else
          -- ������� ������ ����������� �������� � �������
          update_delayed_action_status(x.action_type, x.class_id, x.class_column_qual, x.index_name, v_success, v_errors);
          v_record_count := v_record_count + 1;

          -- ������� ���������� � ���������� � �������
          if v_success = SUCCESS then
              if x.index_name is not null then
                  v_msg := message.gettext('CLS', 'DELAYED_ACTION_SUCCESS_INDEX', x.action_type, x.index_name, x.class_id);
              elsif x.class_column_qual is not null then
                  v_msg := message.gettext('CLS', 'DELAYED_ACTION_SUCCESS_QUAL', x.action_type, x.class_column_qual, x.class_id);
              else
                  v_msg := null;
              end if;
              storage_utils.ws(v_msg);
          else
              v_result := false;
              p_error_msg := v_errors;
              storage_utils.ws(v_errors);
              exit;
          end if;
      end if;

    end loop;

    if v_record_count = 0 then
        storage_utils.ws(message.gettext('EXEC', 'DELAYED_ACTIONS_NO_RECORDS'));
    else
        storage_utils.ws(message.gettext('EXEC', 'DELAYED_ACTIONS_NUM_RECORDS', to_char(v_record_count)));
    end if;
    storage_utils.ws(message.gettext('EXEC', 'DELAYED_ACTIONS_EXEC_END'));
    return v_result;
  end;

  -- ���������� ���������� ���������� ��������, ������� �� ���������, ���� ��������� � �������
  function get_num_actions_to_perform return number is
  v_result number;
  begin
      select count(1) into v_result
             from delayed_actions t 
             where t.execute_success <> delayed_action_mgr.SUCCESS;
      return v_result;
  end;

end delayed_action_mgr;
/
sho err
