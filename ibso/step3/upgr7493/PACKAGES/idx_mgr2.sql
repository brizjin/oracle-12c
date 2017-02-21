prompt INDEX_MGR body
CREATE OR REPLACE
Package Body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/idx_mgr2.sql $
 *  $Author: vzhukov $
 *  $Revision: 94127 $
 *  $Date:: 2016-02-15 16:47:04 #$
 */
INDEX_MGR IS
/*------------------------------------------------
-- Регистрация первичного ключа
------------------------------------------------*/
PROCEDURE Register_Primary_Key(ClassId IN varchar2)
    IS
IndexName VARCHAR2(30);
BEGIN
   SELECT 'PK_'||Table_Name||'_ID' INTO IndexName
     FROM Class_Tables WHERE Class_Id = ClassId;
   DELETE Class_Indexes WHERE Class_Id = ClassId AND Primary_Key = '1';
   DELETE Class_Indexes WHERE Name = IndexName;
   INSERT INTO Class_Indexes (Name, Class_Id, Uniqueness, Primary_Key)
         VALUES(IndexName, ClassId, 'UNIQUE', '1');
   INSERT INTO Class_Ind_Columns (Index_Name, Qual, Position)
         VALUES (IndexName, 'ID', 1);
   COMMIT;
EXCEPTION WHEN OTHERS THEN
   ROLLBACK;
   RAISE;
END Register_Primary_Key;
/*------------------------------------------------
-- Создание индекса
------------------------------------------------*/
FUNCTION Create_Index(p_Name IN varchar2,
    p_rebuild       IN boolean  default false,
    p_ratio         IN number   default 1,
    p_tspacei       IN varchar2 default null,
    p_ini_trans     IN number   default null,
    p_max_trans     IN number   default null,
    p_pct_free      IN number   default null,
    p_init_extent   IN number   default null,
    p_next_extent   IN number   default null,
    p_min_extents   IN number   default null,
    p_max_extents   IN number   default null,
    p_pct_increase  IN number   default null,
    p_free_lists    IN number   default null,
    p_free_groups   IN number   default null,
    p_degree        IN number   default null,
    p_part_tspace   IN varchar2 default null,
    p_position      pls_integer default null,
    p_reverse       boolean     default false,
    p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
   )RETURN VARCHAR2 IS

v_uniqueness varchar2(16);
v_class_id   varchar2(16);   
BEGIN
    begin
        select Uniqueness, Class_Id into v_uniqueness, v_class_id from Class_Indexes where Name = p_Name;
    exception when NO_DATA_FOUND then null;
    end;
    
    if p_delayed_actions_mode and v_uniqueness='UNIQUE' then
        delayed_action_mgr.add_delayed_action(
                        p_action_group => delayed_action_mgr.GROUP_CREATE_RESTRICTIONS, -- Группа действий
                        p_action_type  => delayed_action_mgr.CREATE_INDEX,              -- Тип действия
                        p_priority     => delayed_action_mgr.PRIOR_ADD_UNIQUE_INDEX,    -- Приоритет
                        p_class_id     => v_class_id, -- Короткое имя ТБП
                        p_class_column_qual => null,  -- Квалификатор колонки ТБП
                        p_index_name   => p_Name      -- Наименование индекса
        );
        return '0';
    else
        return part_mgr.create_index(p_Name,p_rebuild,p_ratio,p_tspacei,
                p_ini_trans,p_max_trans,p_pct_free,p_init_extent,p_next_extent,
                p_min_extents,p_max_extents,p_pct_increase,p_free_lists,p_free_groups,
                p_degree,p_part_tspace,p_position,p_reverse);
    end if;
END Create_Index;
/*------------------------------------------------
-- Удаление индекса
------------------------------------------------*/
PROCEDURE Delete_Index(IndexName IN varchar2, p_position pls_integer default null)
    IS
Unq    varchar2(16);
Query  VARCHAR2(200);
v_qual varchar2(700);
TableName  VARCHAR2(30);
v_towner   VARCHAR2(30);
v_iowner   VARCHAR2(30);
ClassId    VARCHAR2(16);
IndexName_ VARCHAR2(30);
v_position  pls_integer;
BEGIN
    SELECT Class_Id,Qual INTO ClassId,v_qual FROM Class_Indexes WHERE Name = IndexName;
    class_mgr.check_changes_access(class_mgr.DCOT_CLASSES, ClassId, class_mgr.DCCT_CLASSES);
    if v_qual is null then
      storage_mgr.class2table(TableName,v_towner,ClassId,null);
    else
      begin
        select cc.nt_table,ct.owner into TableName, v_towner
          from class_tab_columns cc, class_tables ct
         where cc.class_id=ClassId and cc.qual=v_qual and ct.class_id=cc.class_id;
        if v_towner is null then
          v_towner := inst_info.gowner;
        end if;
      exception when no_data_found then
        null;
      end;
    end if;
    IndexName_:= IndexName;
    if p_position>0 then
      if v_qual is null then
        for c in (select mirror, partition_position, mirror_owner
                    from class_partitions
                   where class_id=ClassId and mirror<>TableName
                     and partition_position=p_position)
        loop
          v_towner  := nvl(c.mirror_owner,inst_info.gowner);
          TableName := c.mirror;
          v_position:= c.partition_position;
          IndexName_:= part_mgr.get_mirror_name(IndexName,lpad(to_char(v_position),3,'0'));
        end loop;
      else
        for c in (select cc.nt_table, cp.partition_position, cp.mirror_owner
                    from class_part_columns cc, class_partitions cp
                   where cc.class_id=ClassId and cc.partition_position=p_position and cc.qual=v_qual
                     and cp.class_id=cc.class_id and cp.partition_position=cc.partition_position and cp.mirror<>TableName
        ) loop
          v_towner  := nvl(c.mirror_owner,inst_info.gowner);
          TableName := c.nt_table;
          v_position:= c.partition_position;
          IndexName_:= part_mgr.get_mirror_name(IndexName,lpad(to_char(v_position),3,'0'));
        end loop;
      end if;
    end if;
    LOOP
      begin
        select 'UNIQUE' into Unq from dba_constraints
         where table_name=TableName and owner=v_towner and constraint_name=IndexName_;
      exception when NO_DATA_FOUND then
        Unq := null;
      end;
      IF Unq = 'UNIQUE' THEN -- drop constraint
        Query := 'ALTER TABLE '|| TableName || ' DROP CONSTRAINT ' || IndexName_;
        if storage_mgr.v10_flag then
          Query := Query||' DROP INDEX';
        end if;
        v_iowner := v_towner;
      ELSE -- drop index
        begin
          select owner into v_iowner from dba_indexes
           where table_name=TableName and table_owner=v_towner and index_name=IndexName_;
          Query := 'DROP INDEX ' || IndexName_;
        exception when NO_DATA_FOUND then
          v_iowner := null;
        end;
      END IF;
      if v_iowner is not null then
        begin
          Storage_Utils.Execute_Sql(Query,message.gettext('EXEC','DELETING',IndexName_),false,v_iowner);
        exception when others then
          if sqlcode in (-6508,-4061) then raise; end if;
        end;
      end if;
      rtl.write_log('X','DROP: '||IndexName_,null,ClassId);
      IndexName_:= null;
      if p_position=0 then
        v_position := nvl(v_position,10000);
        if v_qual is null then
          for c in (select mirror, partition_position, mirror_owner
                      from class_partitions
                     where class_id=ClassId and mirror<>TableName
                       and partition_position<v_position
                     order by partition_position desc)
          loop
            v_towner  := nvl(c.mirror_owner,inst_info.gowner);
            TableName := c.mirror;
            v_position:= c.partition_position;
            IndexName_:= part_mgr.get_mirror_name(IndexName,lpad(to_char(v_position),3,'0'));
            exit;
          end loop;
        else
          for c in (select cc.nt_table, cp.partition_position, cp.mirror_owner
                      from class_part_columns cc, class_partitions cp
                     where cc.class_id=ClassId and cc.partition_position<v_position and cc.qual=v_qual
                       and cp.class_id=cc.class_id and cp.partition_position=cc.partition_position and cp.mirror<>TableName
                     order by partition_position desc)
          loop
            v_towner  := nvl(c.mirror_owner,inst_info.gowner);
            TableName := c.nt_table;
            v_position:= c.partition_position;
            IndexName_:= part_mgr.get_mirror_name(IndexName,lpad(to_char(v_position),3,'0'));
          end loop;
        end if;
      end if;
      exit when IndexName_ is null;
    END LOOP;
    if nvl(p_position,0)=0 then
      DELETE Class_Ind_Columns WHERE Index_Name = IndexName;
      DELETE Class_Indexes WHERE Name = IndexName;
      delete from delayed_actions where index_name = IndexName;
      class_mgr.write_changes(class_mgr.DCOT_INDEXES, IndexName, ClassId, true);
    end if;
    COMMIT;
EXCEPTION  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END Delete_Index;
/*------------------------------------------------
-- Заполнение таблицы индексов на основании реальных данных
------------------------------------------------*/
procedure Retrofit(p_class_id   in varchar2 default null,
                   p_index_name in varchar2 default null) is
  claz VARCHAR2(40);
  v_ix rtl.STRING40_TABLE;
  n    pls_integer;
begin
  if p_class_id is null then
    claz := '%';
    storage_utils.ws(message.gettext('EXEC',
                                     'DELETING',
                                     'CLASS_IND_COLUMNS...'));
    delete from class_ind_columns cic
     where (nvl(descending, 'A') in ('A', 'D', 'S', 'T') or not exists
            (select 1
               from dba_ind_columns uic, class_tables ct, class_indexes ci
              where uic.index_name = cic.index_name
                and uic.column_position = cic.position
                and uic.column_name like 'SYS%'
                and uic.table_name = ct.table_name
                and uic.table_owner = nvl(ct.owner, inst_info.gowner)
                and ct.class_id = ci.class_id
                and ci.name = cic.index_name))
       and (cic.index_name = p_index_name or p_index_name is null);
    storage_utils.ws(message.gettext('EXEC',
                                     'DELETED',
                                     sql%rowcount,
                                     'CLASS_IND_COLUMNS:'));
    storage_utils.ws(message.gettext('EXEC',
                                     'DELETING',
                                     'CLASS_INDEXES...'));
    select ci.name bulk collect
      into v_ix
      from class_indexes ci
     where ci.primary_key = '2'
       and (ci.name = p_index_name or p_index_name is null);
    delete from class_indexes ci
     where (ci.name = p_index_name or p_index_name is null)
       and not exists (select 1
              from class_ind_columns cic
             where cic.index_name = ci.name);
  else
    claz := p_class_id;
    storage_utils.ws(message.gettext('EXEC',
                                     'DELETING',
                                     'CLASS_IND_COLUMNS (' || claz || ')'));
    delete from class_ind_columns cic
     where (nvl(descending, 'A') in ('A', 'D', 'S', 'T') or not exists
            (select 1
               from dba_ind_columns uic, class_tables ct, class_indexes ci
              where uic.index_name = cic.index_name
                and uic.column_position = cic.position
                and uic.column_name like 'SYS%'
                and uic.table_name = ct.table_name
                and uic.table_owner = nvl(ct.owner, inst_info.gowner)
                and ct.class_id = ci.class_id
                and ci.name = cic.index_name))
       and index_name in
           (select name
              from class_indexes ci
             where ci.class_id like claz
               and (ci.name = p_index_name or p_index_name is null));
    storage_utils.ws(message.gettext('EXEC',
                                     'DELETED',
                                     sql%rowcount,
                                     'CLASS_IND_COLUMNS:'));
    storage_utils.ws(message.gettext('EXEC',
                                     'DELETING',
                                     'CLASS_INDEXES (' || claz || ')'));
    select name bulk collect
      into v_ix
      from class_indexes ci
     where ci.class_id like claz
       and ci.primary_key = '2'
       and (ci.name = p_index_name or p_index_name is null);
    delete from class_indexes ci
     where class_id like claz
       and (ci.name = p_index_name or p_index_name is null)
       and not exists (select 1
              from class_ind_columns cic
             where cic.index_name = ci.name);
  end if;
  storage_utils.ws(message.gettext('EXEC',
                                   'DELETED',
                                   sql%rowcount,
                                   'CLASS_INDEXES:'));
  -- LOAD INDEXES FROM user_indexes
  storage_utils.ws(message.gettext('EXEC',
                                   'CREATING',
                                   'CLASS_INDEXES (' || claz || ')'));
  insert into class_indexes
    (name, class_id, uniqueness, primary_key)
    select
     ui.index_name,
     ct.class_id,
     ui.uniqueness,
     decode(uc.constraint_type, 'P', '1', '0')
      from dba_constraints uc, dba_indexes ui, class_tables ct
     where uc.constraint_name(+) = ui.index_name
       and uc.table_name(+) = ui.table_name
       and uc.owner(+) = ui.table_owner
       and not exists
     (select 1 from class_indexes ci where ci.name = ui.index_name)
       and (ui.index_name not like 'SYS\_FK%' escape '\')
       and ui.index_name not like 'Z#I%'
       and (ui.index_name = p_index_name or p_index_name is null)
       and ui.generated = 'N'
       and ui.table_name = ct.table_name
       and ui.table_owner = nvl(ct.owner, inst_info.gowner)
       and ct.class_id like claz;
  storage_utils.ws(message.gettext('EXEC',
                                   'CREATED',
                                   sql%rowcount,
                                   'CLASS_INDEXES:'));
  -- LOAD INDEX COLUMNS
  storage_utils.ws(message.gettext('EXEC',
                                   'CREATING',
                                   'CLASS_IND_COLUMNS (' || claz || ')'));
  insert into class_ind_columns
    (index_name, qual, position)
    select
     uic.index_name,
     nvl((select qual
           from class_tab_columns ctc
          where ctc.column_name = uic.column_name
            and ctc.table_name = uic.table_name
            and ctc.class_id = ci.class_id
            and deleted = '0'
            and rownum = 1),
         uic.column_name) column_name,
     uic.column_position
      from dba_ind_columns uic, class_tables ct, class_indexes ci
     where uic.index_name = ci.name
       and uic.column_name not like 'SYS%'
       and uic.table_name = ct.table_name
       and uic.table_owner = nvl(ct.owner, inst_info.gowner)
       and ct.class_id = ci.class_id
       and ci.qual is null
       and ci.class_id like claz
       and (ci.name = p_index_name or p_index_name is null);
  storage_utils.ws(message.gettext('EXEC',
                                   'CREATED',
                                   sql%rowcount,
                                   'CLASS_IND_COLUMNS:'));
  -- LOAD GLOBAL INDEXES AND INDEX COLUMN EXPRESSIONS
  part_mgr.check_indexes(claz, p_index_name);
  n := v_ix.count;
  if n > 0 then
    forall i in 1 .. n
      update class_indexes
         set primary_key = '2'
       where name = v_ix(i)
         and primary_key = '0';
    v_ix.delete;
  end if;
  commit;
exception
  when others then
    rollback;
    raise;
end Retrofit;
-- Построение индексов
procedure Create_Indexes(p_class_id in varchar2 default null,
                         p_rebuild  in boolean  default false,
                         p_pipe     in varchar2 default null,
                         p_start    in varchar2 default null,
                         p_ratio    in number   default 1,
                         p_tspacei  in varchar2 default null,
                         p_parttspace  varchar2 default null,
                         p_position pls_integer default null,
                         p_delayed_actions_mode  boolean default false -- Признак включенного режима отложенных действий
                         ) is
    claz VARCHAR2(30) := nvl(p_class_id,'%');
    cls  varchar2(16) := nvl(p_start,chr(1));
    idx  varchar2(30) := chr(1);
    str  varchar2(16);
    v_ix rtl.STRING40_TABLE;
    v_cl rtl.STRING40_TABLE;
    v_uniqueness rtl.STRING40_TABLE;
begin
  if not p_pipe is null then
    storage_mgr.verbose := true;
    storage_mgr.pipe_name := p_pipe;
    storage_utils.verbose := true;
    storage_utils.pipe_name := p_pipe;
  end if;
  -- PLATFORM-2634
  select ci.name, ci.class_id, ci.uniqueness 
      bulk collect into v_ix, v_cl, v_uniqueness
      from class_indexes ci, classes cl
      where cl.id like claz and cl.id = ci.class_id and (ci.class_id>cls or (ci.class_id=cls and ci.name>idx))
      and not (nvl(ci.primary_key,'0') = '1' and lib.has_rowid(cl.properties)='1' )
      order by ci.class_id,decode(ci.primary_key,'1','*',ci.primary_key),ci.name;
  cls := chr(1);
  for i in 1..v_ix.count loop
    if cls<>v_cl(i) then
      cls := v_cl(i);
      storage_utils.ws(message.gettext('EXEC', 'INDEXES_FOR', cls));
    end if;
    begin
      str := create_index(v_ix(i),p_rebuild,p_ratio,p_tspacei,p_part_tspace=>p_parttspace,p_position=>p_position,p_delayed_actions_mode => p_delayed_actions_mode);
    exception when others then
      if sqlcode in (-6508,-4061) then raise; end if;
    end;
  end loop;
  v_ix.delete;
  v_cl.delete;
end;
   -- Enter further code below as specified in the Package spec.
END INDEX_MGR;
/
show err package body index_mgr
