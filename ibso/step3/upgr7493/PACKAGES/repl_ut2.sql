prompt repl_utils body

column xxx new_value v_plsql_flag noprint
select decode(count(1),1, 'true', 0,'false') xxx from settings where name='SCRIPTS_LOGGING' and upper(substr(value,1,1)) in ('1','Y');

alter session set plsql_ccflags = 'MT_INSTALLED:&&v_plsql_flag'
/
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/repl_ut2.sql $
 *  $Author: sasa $
 *  $Revision: 49478 $
 *  $Date:: 2014-07-30 15:47:03 #$
 */
repl_utils as
--
    LF constant varchar2(1) := chr(10);
--
    -- структура для вставки в  REPLICATION
    $IF $$MT_INSTALLED $THEN
      type r_repl_record is record (
        OBJ_ID    REPLICATION.obj_id%TYPE,
        CLASS_ID  REPLICATION.CLASS_ID%TYPE,
        EVENT     REPLICATION.EVENT%TYPE,
        BTYPE     REPLICATION.btype%TYPE,
        QUAL      REPLICATION.qual%TYPE,
        VALUE     REPLICATION.value%TYPE,
        SES       REPLICATION.ses%TYPE,
        OLD_VALUE REPLICATION.old_value%TYPE,
        id  REPLICATION.id%TYPE);
    $END
  -- структура для вставки в  REPL_STACK

    $IF $$MT_INSTALLED $THEN
      type r_repl_stack is record(
        id REPL_STACK.id%TYPE,
        stack REPL_STACK.s%TYPE,
        num REPL_STACK.num%TYPE);

    type t_repl_type is table of r_repl_record;
    type t_repl_stack is table of r_repl_stack;

    repl_table t_repl_type := t_repl_type();
    repl_stacks t_repl_stack := t_repl_stack();
    $END
--

procedure WS(msg_str varchar2) is
begin
    if verbose then
        stdio.put_line_pipe(msg_str, pipe_name);
    end if;
end;
--
function repl_setting(p_name varchar2) return varchar2 is
    s   varchar2(2000);
begin
    select /*+ INDEX */ value  into s from repl_settings where name=p_name;
    return s;
exception when others then
    return null;
end;
--
procedure lock_repl_setting(p_name varchar2) is
    s   varchar2(2000);
begin
    select /*+ INDEX */ value  into s from repl_settings where name=p_name for update nowait;
end;
--
procedure put_repl_setting(p_name varchar2, p_value   varchar2) is
begin
  if p_value is null then
    delete repl_settings where name=p_name;
  else
    update repl_settings set value=p_value where name=p_name;
    if sql%rowcount=0 then
        insert into repl_settings(name,value) values (p_name,p_value);
    end if;
  end if;
end;
--
-- Запись в таблицу repl_sequences
procedure put_repl_sequence(p_class_id varchar2, p_attr_id varchar2, p_value number) is
begin
    update repl_sequences set value=p_value where class_id=p_class_id and attr_id=p_attr_id;
    if sql%rowcount=0 then
        insert into repl_sequences(class_id, attr_id, value) values (p_class_id, p_attr_id, p_value);
    end if;
end;
--
-- Сохранение сиквенсов автонумеруемых реквизитов и SEQ_ID в таблице repl_sequencies
procedure save_sequences is
v_seqval number;
begin
  WS('*** Sequence for autonumerated requisits... ');
  for c in (select class_id,attr_id,sequenced
            from  class_attributes
            where sequenced is not null
            order by class_id, attr_id
            )
  loop
      WS( '   ' || c.class_id || '.' || c.attr_id);
      v_seqval:= 0;
      begin
        execute immediate
        'select last_number from user_sequences where sequence_name=''' || c.sequenced || '''' into v_seqval;
        put_repl_sequence(c.class_id,c.attr_id,v_seqval);
      exception when others then
        WS('    - сбой при получении значения последовательности');
      end;
  end loop;
  WS('*** Sequence SEQ_ID');
  v_seqval:= 0;
  select last_number into v_seqval from user_sequences where sequence_name='SEQ_ID';
  put_repl_sequence('SEQ_ID','SEQ_ID',v_seqval);
end;
--
-- Пересоздание сиквенса с новым значением (использовано решение в SYS_DIARYS.DLIB)
procedure alter_sequence(p_seq varchar2, p_value number) is
    v_num number;
    v_start_value number;
    v_cache number;
    v_minval number;
    v_maxval number;
    v_inc number;
    v_cycle varchar2(128);
    s varchar2(2000);
    i   pls_integer;
    ii  pls_integer;
begin
    select  last_number, cache_size, min_value, max_value, increment_by, cycle_flag
    into v_num, v_cache, v_minval, v_maxval, v_inc, v_cycle
    from user_sequences
    where sequence_name = p_seq;
--
    if p_seq='SEQ_ID' and p_value<v_num then
      WS('Sequence "SEQ_ID" is not altered, new value less then seq_id.currval');
      return;
    end if;
    i:= v_cache;
    s:=  'alter sequence "'||p_seq||'"';
    if p_value is not null then
        v_start_value := trunc(p_value);
        v_num := v_start_value-v_num+2*v_cache;
        if abs(v_num)>2*v_cache and v_start_value>=v_minval and v_start_value<=v_maxval then
          if v_cycle='Y' then
              ii := 0;
              v_start_value := v_start_value-1;
              if v_start_value<v_minval then
                  v_start_value := v_maxval;
              end if;
          else
            ii := 1;
          end if;
          v_cache := rtl.next_value(p_seq);
          v_num := v_start_value-v_cache-2;
          if v_num<0 then
              v_cache := v_start_value-1000;
          else
              v_cache := v_minval;
          end if;
          execute_sql(s || ' minvalue ' || v_cache ||' increment by ' || v_num|| ' nocache',
                        'Altering ' || p_seq || ' : ' || p_value);
          v_cache := rtl.next_value(p_seq);
          execute_sql(s || ' increment by 1 nocache');
          loop
                v_cache := rtl.next_value(p_seq)+ii;
                exit when v_cache>=v_start_value;
          end loop;
          if v_minval+ii>=v_start_value then
              v_minval := v_start_value-ii;
          end if;
          s := s||' minvalue '||v_minval||' increment by '||v_inc;
          if i>0 then
              s := s||' cache '||i;
          else
              s := s||' nocache';
          end if;
          execute_sql(s, 'Altering sequence ' || p_seq || ' finished' );
        else
          if v_start_value<v_minval or v_start_value>v_maxval then
            WS('Sequence "' || p_seq ||'" is not altered, new value is not correct');
          else
            WS('Altering of sequence "' || p_seq ||'" is not required');
          end if;
        end if;
    else
      WS('Sequence "' || p_seq ||'" is not altered, new value is not defined');
    end if;
exception when no_data_found then
    WS('Sequence "' ||  p_seq || '" is not exists');
    return;
end;
--
-- Импорт сиквенсов автонумеруемых реквизитов и SEQ_ID из таблицы repl_sequencies
procedure import_sequences is
v_sequence_name varchar2(128);
begin
  for c in (select class_id,attr_id,value
            from  repl_sequences
            )
  loop
      v_sequence_name:= null;
      if  not (c.class_id='SEQ_ID' and c.attr_id='SEQ_ID') then
        WS(c.class_id || '.' || c.attr_id);
        begin
            select sequenced into v_sequence_name
              from  class_attributes
              where class_id=c.class_id and attr_id=c.attr_id;
            alter_sequence(v_sequence_name, c.value);
        exception when NO_DATA_FOUND then
            WS('  ...sequence is not defined !!!');
        end;
      else
        WS('SEQ_ID');
        alter_sequence('SEQ_ID', c.value);
      end if;
  end loop;
end;
--
-- Выполнение заданного pl/sql выражения
function  execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false, p_name varchar2 default null ) return integer is
    v_status     integer;
    v_cursor     integer;
    v_count      integer := 0;
    v_var        boolean := p_name is not null;
begin
    if comment is not null then
      WS(comment);
    end if;
    v_cursor := dbms_sql.open_cursor;
    v_status := dbms_sql.last_sql_function_code;
    if not dbms_sql.is_open(v_cursor) then
        raise_application_error(-20999, 'DBMS_SQL.OPEN_CURSOR: Can not open cursor, status = ' || to_char(v_status));
    end if;
    dbms_sql.parse(v_cursor, p_sql_block, dbms_sql.native);
    if v_var then
        dbms_sql.bind_variable( v_cursor, p_name, v_count);
    end if;
    v_count := dbms_sql.execute(v_cursor);
    if v_var then
        dbms_sql.variable_value( v_cursor, p_name, v_count);
    end if;
    v_status := dbms_sql.last_sql_function_code;
    dbms_sql.close_cursor(v_cursor);
    return v_count;
  exception when others then
    if dbms_sql.is_open( v_cursor ) then
        dbms_sql.close_cursor( v_cursor );
    end if;
    if not silent then
        WS(p_sql_block); WS(SQLERRM);
        raise;
    end if;
    return -1;
end execute_sql;
--
procedure execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false ) is
    v_status     integer;
begin
v_status := execute_sql(p_sql_block, comment, silent);
end execute_sql;
--
procedure create_kernel_triggers(p_pipe varchar2 default null) is
    s   varchar2(200);
    ss  varchar2(100);
begin
    if p_pipe is not null then
        verbose := true;
        pipe_name := p_pipe;
    end if;
    s := 'CREATE OR REPLACE TRIGGER REP$###'||LF
      || 'AFTER INSERT OR UPDATE OR DELETE ON ### FOR EACH ROW'||LF
      || 'begin message.sys_error(''CLS'',''METADATA''); end;';
    ss:= 'Creating trigger REP$###';
    execute_sql(replace(s,'###','CLASSES'),replace(ss,'###','CLASSES'));
    execute_sql(replace(s,'###','CLASS_TABLES'),replace(ss,'###','CLASS_TABLES'));
    execute_sql(replace(s,'###','CLASS_ATTRIBUTES'),replace(ss,'###','CLASS_ATTRIBUTES'));
    execute_sql(replace(s,'###','CLASS_TAB_COLUMNS'),replace(ss,'###','CLASS_TAB_COLUMNS'));
    execute_sql(replace(s,'###','CLASS_PARTITIONS'),replace(ss,'###','CLASS_PARTITIONS'));
    execute_sql(replace(s,'###','CLASS_PART_COLUMNS'),replace(ss,'###','CLASS_PART_COLUMNS'));
end;
--
procedure drop_kernel_triggers(p_pipe varchar2 default null) is
    s   varchar2(100);
    ss  varchar2(100);
begin
    if p_pipe is not null then
        verbose := true;
        pipe_name := p_pipe;
    end if;
    s := 'DROP TRIGGER REP$###';
    ss:= 'Dropping trigger REP$###';
    for c in (select ut.trigger_name, ut.table_name from user_triggers ut
              where ut.table_name in ('CLASSES', 'CLASS_TABLES','CLASS_ATTRIBUTES','CLASS_TAB_COLUMNS',
                                      'CLASS_PARTITIONS', 'CLASS_PART_COLUMNS')
                    and ut.trigger_name like 'REP$%'
              order by ut.table_name)
    loop
      execute_sql(replace(s,'###',c.table_name),replace(ss,'###',c.table_name));
    end loop;
end;
--
function  show_errors ( p_name  IN varchar2,
                        p_title IN boolean default TRUE
                      ) return varchar2 is
    v_text  varchar2(20000);
    v_type  varchar2(40) := chr(1);
    v_name  varchar2(40) := chr(1);
    v_pack  varchar2(40) := upper(rtrim(ltrim(p_name)));
begin
    for c in (
        select name, line, position, text, type
          from user_errors
         where name like v_pack
         order by name,type,sequence
             )
    loop
      begin
        if p_title and (v_type<>c.type or v_name<>c.name) then
            v_type := c.type;
            v_name := c.name;
            v_text := v_text||'Errors for '||v_type||' '||v_name||': '||LF;
        end if;
        v_text := v_text||'P('||to_char(c.line)||','||to_char(c.position)||'): '||c.text||LF;
      exception when value_error then exit;
      end;
    end loop;
    return v_text;
end;
--
procedure set_trigger_status(p_name varchar2, p_status varchar2) is
sOldStatus varchar2(128);
sSql varchar2(128);
begin
    select status into sOldStatus from user_triggers where trigger_name=p_name;
    if sOldStatus<>upper(p_status) then
        if p_status='ENABLED' then
          sSql:= 'ENABLE';
        elsif p_status='DISABLED' then
          sSql:= 'DISABLE';
        end if;
        if sSql is not null then
          repl_utils.execute_sql('ALTER TRIGGER ' || p_name || ' ' || sSql,
                                 'Setting status of trigger ' || p_name || ' to ' || upper(p_status));
        end if;
    end if;
exception when NO_DATA_FOUND then null;
end;
--
--
procedure reset is
sIdx integer;
begin
  -- лучше иcпользовать repl_stacks вместо repl_table,
  -- так как в repl_table может не быть записей, a в repl_stacks - уже записи могли занестись
  $IF $$MT_INSTALLED $THEN
    sIdx:= repl_stacks.count();
      if sIdx = 0 then
        return;
      end if;
      repl_table.delete;
      repl_stacks.delete;
  $ELSE
    null;
  $END
end;

procedure save(p_table varchar2) is
begin
   $IF $$MT_INSTALLED $THEN
    forall i in 1..repl_table.count
    insert into REPLICATION (id, obj_id, class_id, event, btype, qual, value, old_value, ses)
    values(repl_table(i).id,
           repl_table(i).obj_id,
           repl_table(i).class_id,
           repl_table(i).event,
           repl_table(i).btype,
           repl_table(i).qual,
           repl_table(i).value,
           repl_table(i).old_value,
           repl_table(i).ses);

    forall i in 1..repl_stacks.count
    insert into REPL_STACK(id, s, num)
    values(repl_stacks(i).id, repl_stacks(i).stack, repl_stacks(i).num);

    repl_table.delete();
    repl_stacks.delete();
  $ELSE
    raise value_error;
  $END
end;

-- инициализация repl_stack
procedure init(p_table varchar2) is
n pls_integer;
 begin
    $IF $$MT_INSTALLED $THEN
      n := repl_stacks.count + 1;

      -- Елси записей больше 50000, то сбрасываем резултаты в таблицы REPLICATION и REPL_STACK
      if(n >= 50000) then
        save(p_table);
        n := 1;
      end if;

      repl_stacks.extend;
      repl_stacks(n).stack := dbms_utility.format_call_stack;
      repl_stacks(n).id := rep_id.nextval;
      repl_stacks(n).num := sys_context(INST_INFO.Owner|| '_USER', '$SCMGR_NUM$');
    $ELSE
      raise value_error;
    $END
end init;

procedure add(p_table varchar2, p_id varchar2, p_event varchar2, p_type varchar2, p_qual varchar2,
              p_value varchar2, p_old_value varchar2) is
n pls_integer;
begin
  $IF $$MT_INSTALLED $THEN
    n:=repl_table.count+1;
    repl_table.extend;
    repl_table(n).id := repl_stacks(repl_stacks.count).id;
    repl_table(n).obj_id := p_id;
    if not(p_event='I' and p_qual is null) then
      repl_table(n).class_id:= p_table;
      repl_table(n).value:= p_value;
    else
      repl_table(n).class_id:= p_value;
      repl_table(n).value:= p_table;
    end if;
    repl_table(n).event:= p_event;
    repl_table(n).btype:= p_type;
    repl_table(n).qual:= p_qual;
    repl_table(n).old_value:= p_old_value;
    repl_table(n).ses:=sys_context(INST_INFO.Owner|| '_SYSTEM','ID');
  $ELSE
    null;
  $END
end;
--
end;
/
show err package body repl_utils
