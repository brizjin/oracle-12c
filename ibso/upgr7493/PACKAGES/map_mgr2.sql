prompt mapex_mgr body
create or replace
package body
/*
 *  $Author: timur $
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/map_mgr2.sql $
 *  $Revision: 33045 $
 *  $Date:: 2013-10-23 11:32:32 #$
 */
mapex_mgr is
--
LF constant varchar2(1) := chr(10);
TB constant varchar2(1) := chr(9);
MAP_PREFIX  constant varchar2(5) := 'MAP_';
--
mapped_col class_utils.COLUMN_INFO_TABLE;
--
function  map_trigger_name(p_table varchar2) return varchar2 is
begin
    return MAP_PREFIX||p_table;
end;
--
function needs_mapping(class_id_ varchar2) return boolean is                           -- @METAGS needs_map_columns
	cnt pls_integer;
begin
	select count(1) into cnt from class_tab_columns
     where map_style is not null and mapped_from=class_id_ and deleted='0' and rownum<2;
    return cnt > 0;
end;
--
function needs_map_columns(class_id_ varchar2) return boolean is                           -- @METAGS needs_map_columns
	cnt pls_integer;
begin
	select count(1) into cnt from class_tab_columns
     where map_style is not null and class_id=class_id_ and mapped_from<>'OBJECT' and deleted='0' and rownum<2;
    return cnt > 0;
end;
--
function get_attr_map_service_code return varchar2 is
begin
    if nvl(sysinfo.getvalue('PLP_MAP_TRIGGERS_LIGHT_ENABLED'), '0') = '1' then
        return ' if not attribute_mapping_service.is_enabled then' || LF ||
               '     return;' || LF ||
               ' end if;';
    end if;
    return null;
end;

--Собственно модификация таблицы - создание\удаление колонок
procedure add_columns_map(p_class_id varchar2,             -- @METAGS add_columns_map
						  p_qual varchar2,
                          idx    pls_integer
						 ) is
    attr  class_tab_columns%rowtype;
	attr_class classes%rowtype;     -- Attribute class
begin
    --storage_utils.ws('Построение списка колонок дублирования для класса '|| p_owner_ID ||'['||p_qual||']');
    select * into attr from class_tab_columns
     where class_id = p_class_id and qual = p_qual;
    --Зачитать описание типа атрибута
    select * into attr_class from classes where id = attr.self_class_id;
-- Заполним информацию о колонке
    storage_mgr.class2table(attr.table_name,attr.flags,p_class_id,null);
    mapped_col(idx).owner:= p_class_id;
    mapped_col(idx).qual := p_qual;
    if mapped_col(idx).name is null then
      mapped_col(idx).name := attr.column_name;
    end if;
    if mapped_col(idx).distance is null then
      mapped_col(idx).distance := attr.qual_pos;
    end if;
    mapped_col(idx).self := attr.self_class_id;
    mapped_col(idx).flags:= attr.flags;
    mapped_col(idx).table_name:= attr.table_name;
    mapped_col(idx).not_null:= attr.not_null;
    mapped_col(idx).indexed := attr.indexed;
    mapped_col(idx).base := attr_class.base_class_id;
    mapped_col(idx).target := attr_class.target_class_id;
    mapped_col(idx).kernel := attr_class.kernel;
    mapped_col(idx).len := attr_class.data_size;
    mapped_col(idx).prec:= attr_class.data_precision;
    if attr_class.target_class_id is null then
      mapped_col(idx).targ_kernel := '0';
    else
      mapped_col(idx).targ_kernel := storage_mgr.is_kernel(attr_class.target_class_id);
    end if;
end;
--
function modify_column_ex(i pls_integer, conv in out nocopy varchar2,
                          class_id_ varchar2, table_name_ varchar2, owner_ varchar2,
                          p_modify  boolean) return boolean is  -- @METAGS modify_column_ex
    col_name    varchar2(30);
    col_type    varchar2(100);
    new_type    varchar2(100);
    col_len     pls_integer;
    col_prec    pls_integer;
    col_scale   pls_integer;
    col_not_null   varchar2(10);
	action varchar2(10);
	q varchar2(256);
	table_modified boolean := false;
    cnt  pls_integer;
    v_add  boolean;
begin
    col_name := mapped_col(i).name;
	-- Определим, а была ли колонка и есть ли она на самом деле
    if storage_utils.get_column_props(table_name_,col_name,col_type,col_len,col_prec,col_scale,col_not_null,owner_) then
      v_add := false; action := 'MODIFY';
    else
      v_add := true;  action := 'ADD';
    end if;
    --storage_utils.ws('Модификация колоноки дублирования '|| mapped_col(i).qual ||' ['|| col_name ||'] для класса '|| Class_ID_);
    if p_modify or v_add then
        update class_tab_columns
        set column_name= col_name,
            table_name = table_name_,
            self_class_id = mapped_col(i).self,
            base_class_id = mapped_col(i).base,
            target_class_id = mapped_col(i).target,
            indexed  = mapped_col(i).indexed,
            not_null = mapped_col(i).not_null,
            qual_pos = mapped_col(i).distance,
            map_style= 'D'
        where class_id = class_id_ and qual = mapped_col(i).qual;
    end if;
    if (p_modify or v_add) and
      (class_utils.check_type(mapped_col(i),new_type,col_type,col_len,col_prec,col_scale,null,null,false)
        or mapped_col(i).checked='A')
    then
		q := col_name || TB || new_type;
		if not mapped_col(i).len is null then
			q := q || '(' || to_char(mapped_col(i).len);
			if not mapped_col(i).prec is null then
				q := q || ',' || to_char(mapped_col(i).prec);
			end if;
	 		q := q || ')';
		end if;
	end if;
    conv := null;
	if not q is null then
        if v_add then
            conv := 'NULL';
        elsif new_type<>col_type then
            conv := 'NULL';
            if col_not_null = '1' then
              storage_utils.execute_sql('ALTER TABLE '||owner_||'.'||table_name_||' MODIFY '||col_name||' NULL');
            end if;
            storage_utils.clear_column(class_id_,col_name);
		end if;
        if conv is null and mapped_col(i).not_null <> col_not_null then
          if mapped_col(i).not_null = '0' then
            q := q || ' NULL';
          elsif mapped_col(i).not_null = '1' then
            q := q || ' NOT NULL';
          end if;
        end if;
        storage_utils.ws(table_name_|| ' ' || action || TB || q);
		begin
            storage_utils.execute_sql('ALTER TABLE '||owner_||'.'||table_name_||LF||action||TB||q);
			table_modified := true;
		exception when others then null;
		end;
    elsif p_modify then
        if mapped_col(i).not_null <> col_not_null then
            q := table_name_ || ' MODIFY ' || col_name;
            if mapped_col(i).not_null = '0' then
                q := q || ' NULL';
            elsif mapped_col(i).not_null = '1' then
                q := q || ' NOT NULL';
            end if;
            storage_utils.execute_sql('ALTER TABLE '||owner_||'.'||q, q);
		elsif mapped_col(i).base in ('REFERENCE','COLLECTION') and mapped_col(i).prev_target <> mapped_col(i).target then
            table_modified := true;
		end if;
	end if;
	return table_modified;
end;
--
procedure map_columns_ex(p_class_id varchar2, p_modify boolean default true) is             -- @METAGS map_columns_ex
    q varchar2(200);
    vb Boolean;
    cmt boolean;
    n pls_integer;
    i pls_integer;
    v_table varchar2(30);
    v_owner varchar2(30);
begin
    storage_mgr.class2table(v_table,v_owner,p_class_id,null);
    if v_table is null then return; end if;
    storage_utils.ws(message.gettext('KRNL', 'MAPPING_START', p_Class_ID));
	--Синхронизация сдублированных колонок с источником колонок
	update class_tab_columns ctc set deleted='1'
	 where class_id=p_class_id and mapped_from<>'OBJECT' and deleted='0'
       and not exists(select 1 from class_tab_columns
                       where class_id=ctc.mapped_from
                         and qual=ctc.qual and deleted='0' and flags is null);
	n := 0;
    mapped_col.delete;
	for mcols in (
        select qual,column_name,base_class_id,target_class_id,deleted,map_style,mapped_from,qual_pos
          from class_tab_columns ctc
         where class_id=p_class_id and mapped_from<>'OBJECT'
           and (deleted='0' or deleted='1' and not_null='1')
    ) loop
        if mcols.deleted = '1' then
            update class_tab_columns set not_null='0'
             where class_id=p_class_id and qual=mcols.qual;
            q := v_table || ' MODIFY ' || mcols.column_name || ' NULL';
            storage_utils.execute_sql('ALTER TABLE '||v_owner||'.'||q, q, true);
        else
            n:=n+1;
            mapped_col(n).name := mcols.column_name;
            mapped_col(n).prev_base := mcols.base_class_id;
            mapped_col(n).prev_target := mcols.target_class_id;
            mapped_col(n).checked := mcols.map_style;
            mapped_col(n).distance:= mcols.qual_pos;
            add_columns_map(mcols.mapped_from,mcols.qual,n);
        end if;
	end loop;
    cmt := upper(storage_mgr.get_storage_parameter('GLOBAL','COMMENTS'))='ON';
	i:= mapped_col.first;
	while not i is null loop
		if modify_column_ex(i,q,p_class_id,v_table,v_owner,p_modify) then
			part_mgr.map_column_data(mapped_col(i).flags||'.'||mapped_col(i).table_name,v_owner||'.'||v_table,mapped_col(i).name);
            if not q is null and mapped_col(i).not_null = '1' then
              q := v_table || ' MODIFY ' || mapped_col(i).name || ' NOT NULL';
              storage_utils.execute_sql('ALTER TABLE '||v_owner||'.'||q, q);
            end if;
		end if;
        if cmt then
          declare
            qual_name   varchar2(8000) := null;
          begin
            types.qual_prop(mapped_col(i).owner,mapped_col(i).qual,q,q,qual_name);
            storage_utils.execute_sql('COMMENT ON COLUMN '||v_owner||'.'||v_table
                ||'.'||mapped_col(i).name||' IS '''||qual_name||'''');
          exception when others then
            if sqlcode=-6508 then raise; end if;
          end;
        end if;
		i:=mapped_col.Next(i);
	end loop;
    mapped_col.delete;
    storage_utils.ws(message.gettext('KRNL', 'MAPPING_FINISH', p_Class_ID));
end;
--
procedure drop_map_trigger( pclass_id varchar2, p_table varchar2 default null ) is -- @METAGS drop_map_trigger
    cnt pls_integer;
    class_table varchar2(30);
    v_name  varchar2(30);
BEGIN
    if p_table is null then
      class_table := storage_mgr.class2table(pclass_id);
      if class_table is null then
        return;
      end if;
    else
      class_table := p_table;
    end if;
    v_name := map_trigger_name(class_table);
    select count(1) into cnt from user_objects
     where object_type = 'TRIGGER' and object_name = v_name;
	if cnt > 0 then
        storage_utils.execute_sql('DROP TRIGGER ' || v_name,
            message.gettext('KRNL', 'DELETING_MAPPING_TRIGGER', pclass_id));
	end if;
exception when others then
    if sqlcode in (-6508,-4061) then raise; end if;
end;
--
procedure create_map_trigger( pclass_id varchar2, p_table varchar2 default null ) is        -- @METAGS create_map_trigger
    t varchar2(32000);
    l varchar2(2000);
    s varchar2(120);
    w varchar2(200);
    b boolean;
    class_table varchar2(100);
    class_owner varchar2(30);
    i pls_integer;
    attr_map_service_injected boolean := false;
begin
    if p_table is null then
      storage_mgr.class2table(class_table,class_owner,pclass_id,null);
    else
      class_table := p_table;
      i := instr(p_table,'.');
      if i>1 then
        class_owner := substr(p_table,1,i-1);
        class_table := substr(p_table,i+1);
      else
        storage_mgr.class2table(class_table,class_owner,pclass_id,null);
      end if;
    end if;
    if class_table is null then
      return;
    end if;
    for mcols in (
      SELECT distinct column_name name,qual,self_class_id,base_class_id
        FROM CLASS_TAB_COLUMNS ctl1
       where mapped_from=pclass_id and deleted='0'
         AND exists(
             select 1 from class_tab_columns ctl2
              where ctl2.class_id = pclass_id
                and ctl2.qual = ctl1.qual
                and ctl2.deleted='0'
                and ctl2.flags is null
             )
    )loop
      b := true;
      if mcols.base_class_id='TABLE' then
        b := false;
      elsif mcols.base_class_id='OLE' and storage_mgr.is_kernel(mcols.self_class_id)='1' then
        b := mcols.self_class_id='RAW';
      end if;
      if b then
        if l is null then
            l := 'OF '||mcols.name;
        else
            l := l||', '||mcols.name;
        end if;

        if not attr_map_service_injected then
            t := t || get_attr_map_service_code || LF;
            attr_map_service_injected := true;
        end if;
        t := t ||
            ' if not ((:NEW.' || mcols.name || ' is null and :OLD.' || mcols.name || ' is null) ' ||
            '   or NVL((:NEW.' || mcols.name || ' = :OLD.' || mcols.name || '),false)) then' || LF ;
        for tcols in (select ct.class_id, ct.cached, ct.table_name, nvl(ct.part_profile_id, ct.param_group) param_group, ct.owner
                        from class_tables ct, class_tab_columns ctc
                       where ctc.mapped_from = pclass_id
                         and ctc.qual = mcols.qual
                         and ctc.deleted = '0'
                         and ct.class_id = ctc.class_id
        ) loop
            s := nvl(tcols.owner,inst_info.gowner)||'.'||tcols.table_name;
            if tcols.param_group='PARTITION' then
                s := s||' partition('||tcols.table_name||'#0)';
                w := ' and KEY=1000;';
            else
                w := ';';
            end if;
            if tcols.cached < 0 or tcols.cached > 1 then
              if class_mgr.count_children(tcols.class_id,'1') > 1 then
                w := w||class_mgr.interface_package(tcols.class_id)||'.cache$del(:NEW.ID,:NEW.ID,c);';
              else
                w := w||class_mgr.interface_package(tcols.class_id)||'.cache_del(:NEW.ID,false);';
              end if;
            end if;
            t:=t||
            '    if lib.is_parent('''||tcols.class_id||''',c) then'||LF||
            '      update '||s||' set ' || mcols.name ||'= :NEW.'||mcols.name||' where ID=:NEW.ID'||w||LF||
            '    end if;'||LF
            ;
        end Loop;
        t := t ||' end if;' || LF;
      else
        storage_utils.ws(message.gettext('EXEC','UNABLE_TO_CONVERT_COLUMN',class_table||'.'||mcols.name||'('||mcols.self_class_id||')'));
      end if;
    end loop;
    if t is null then
        drop_map_trigger(pClass_Id,class_table);
    else
        t :='CREATE OR REPLACE TRIGGER ' ||  map_trigger_name(class_table) || LF ||
            'AFTER UPDATE '||l||' ON '||class_owner||'.'||class_table||LF||
            'FOR EACH ROW' || LF ||
            'DECLARE c varchar2(16):=:NEW.CLASS_ID;'|| LF ||
			'BEGIN' || LF ||
            	t ||
			'END;';
        storage_utils.execute_sql(t, message.gettext('KRNL', 'CREATING_MAPPING_TRIGGER', pClass_ID));
    end if;
exception when others then
    if sqlcode=-6508 then raise; end if;
    storage_utils.ws(sqlerrm);
end;
--
procedure create_mapping_triggers(p_class_id varchar2) is
begin
  for c in(select distinct(mapped_from) id from class_tab_columns
            where class_id=p_class_id and mapped_from<>'OBJECT' and deleted='0'
  ) loop
    create_map_trigger(c.id);
  end loop;
end;
--
procedure update_mapping(p_class_id  varchar2,
                         p_verbose   boolean  default false,
                         p_pipe_name varchar2 default 'DEBUG',
                         p_modify    boolean  default true,
                         p_self      boolean  default null) is
    b boolean;
begin
    storage_utils.verbose := p_verbose;
    storage_utils.pipe_name := p_pipe_name;
    for mClassId in (
     select distinct(class_id) CLID from class_tab_columns
      where mapped_from = p_class_id and map_style is not null and (deleted='0' or deleted='1' and not_null = '1')
    ) loop
      b := true;
      exit when p_self;
      map_columns_ex( mClassId.CLID,p_modify);
    end loop;
    if b then
      create_map_trigger(p_class_id);
    else
      drop_map_trigger(p_class_id);
    end if;
	--Если есть колонки , которые сдублированы из других классов
    if p_self or needs_map_columns(p_class_id) then
        map_columns_ex(p_class_id);
        if p_self then
          return;
        end if;
        create_mapping_triggers(p_class_id);
    end if;
end update_mapping;
end;
/
show err package body mapex_mgr
