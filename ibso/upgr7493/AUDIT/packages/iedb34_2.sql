prompt ie_db34
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iedb34_2.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */
ie_db34 is
procedure exp_diary(p_owner varchar2, p_code pls_integer, p_date date) is
  n pls_integer;
  q varchar2(1000);
  table_name varchar2(100) := 'DIARY';
  w varchar2(200);
  c integer;
  v_rec ie_file.diary_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;

  q := 'id,' || ie_file.quote_date('time') || ',replace(user_id, chr(10)),topic,' || ie_file.quote_text('text') || '';
  if p_code = utils.DIARY1 or p_code = utils.DIARY2 then
    w := ' and owner=''' || p_owner || ''' and topic not in (''S'',''U'',''E'',''H'',''N'')';
  elsif p_code = utils.DIARY3 then
    w := ' and owner=''' || p_owner || ''' and topic in (''U'',''E'')';
  elsif p_code = utils.DIARY4 then
    w := ' and owner=''' || p_owner || ''' and topic=''S'' and text not like ''LOCK_INFO%''';
  elsif p_code = utils.DIARY5 then
    w := ' and owner=''' || p_owner || ''' and topic=''S'' and text like ''LOCK_INFO%''';
  elsif p_code = utils.DIARY6 then
    w := ' and owner=''' || p_owner || ''' and topic in (''H'',''N'')';
  else
    w := ' and owner=''' || p_owner || '''';
  end if;

  ie_file.start_table_exp(p_owner, table_name, p_date);

  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id' || w || ' order by id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);

      dbms_sql.define_column(c, 1, v_rec.id);
      dbms_sql.define_column(c, 2, v_rec.time, 30);
      dbms_sql.define_column(c, 3, v_rec.user_id, 70);
      dbms_sql.define_column(c, 4, v_rec.topic, 10);
      dbms_sql.define_column(c, 5, v_rec.text, 2000);

      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n < 1;
        dbms_sql.column_value(c, 1, v_rec.id);
        dbms_sql.column_value(c, 2, v_rec.time);
        dbms_sql.column_value(c, 3, v_rec.user_id);
        dbms_sql.column_value(c, 4, v_rec.topic);
        dbms_sql.column_value(c, 5, v_rec.text);
        ie_file.put(v_rec);
        snapshot_id := v_rec.id;
      end loop;
      exit;
    exception when utils.SNAPSHOT_TOO_OLD then
        null;
    end;
  end loop;
  dbms_sql.close_cursor(c);

  ie_file.finish_table_exp();

exception
  when others then
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    ie_file.finish_table_exp();
    raise;
end;

procedure exp_diary_param(p_owner varchar2, p_date date) is
  n pls_integer;
  q varchar2(1000);
  table_name varchar2(100) := 'DIARY_PARAM p, DIARY d';
  w varchar2(200);
  c integer;
  v_rec ie_file.diary_param_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;

  w := ' and d.owner=''' || p_owner || ''' and d.topic=''P'' and d.id=p.diary_id';
  q := 'p.diary_id, p.qual, ' || ie_file.quote_text('p.text') || '';

  ie_file.start_table_exp(p_owner, 'DIARY_PARAM', p_date);

  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where d.time < :d and p.diary_id >= :id' || w || ' order by p.diary_id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);

      dbms_sql.define_column(c, 1, v_rec.diary_id);
      dbms_sql.define_column(c, 2, v_rec.qual, 700);
      dbms_sql.define_column(c, 3, v_rec.text, 2000);
      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n<1;
        dbms_sql.column_value(c, 1, v_rec.diary_id);
        dbms_sql.column_value(c, 2, v_rec.qual);
        dbms_sql.column_value(c, 3, v_rec.text);
        ie_file.put(v_rec);
        snapshot_id := v_rec.diary_id;
      end loop;
      exit;
    exception when utils.SNAPSHOT_TOO_OLD then
      null;
    end;
  end loop;
  dbms_sql.close_cursor(c);

  ie_file.finish_table_exp();

exception
  when others then
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    ie_file.finish_table_exp();
    raise;
end;

procedure exp_object_state_history(p_owner varchar2, p_date date) is
  n pls_integer;
  q varchar2(1000);
  table_name varchar2(100) := 'OBJECT_STATE_HISTORY';
  w varchar2(200);
  c integer;
  osh_rec ie_file.object_state_history_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;

  w := ' and owner=''' || p_owner || '''';
  q := 'id, ' || ie_file.quote_date('time') || ', user_id, obj_id, state_id';

  ie_file.start_table_exp(p_owner, table_name, p_date);

  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id' || w || ' order by id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);

      dbms_sql.define_column(c, 1, osh_rec.id);
      dbms_sql.define_column(c, 2, osh_rec.time, 30);
      dbms_sql.define_column(c, 3, osh_rec.user_id, 70);
      dbms_sql.define_column(c, 4, osh_rec.obj_id, 16);
      dbms_sql.define_column(c, 5, osh_rec.state_id, 700);

      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n<1;

        dbms_sql.column_value(c, 1, osh_rec.id);
        dbms_sql.column_value(c, 2, osh_rec.time);
        dbms_sql.column_value(c, 3, osh_rec.user_id);
        dbms_sql.column_value(c, 4, osh_rec.obj_id);
        dbms_sql.column_value(c, 5, osh_rec.state_id);
        ie_file.put(osh_rec);
        snapshot_id := osh_rec.id;
      end loop;
      exit;
    exception when utils.SNAPSHOT_TOO_OLD then
      null;
    end;
  end loop;
  dbms_sql.close_cursor(c);

  ie_file.finish_table_exp();

exception
  when others then
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    ie_file.finish_table_exp();
    raise;
end;

procedure exp_values_history(p_owner varchar2, p_date date) is
  n pls_integer;
  q varchar2(1000);
  table_name varchar2(100) := 'VALUES_HISTORY';
  w varchar2(200);
  c integer;
  valsh_rec ie_file.values_history_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;

  w := ' and owner='''||p_owner||'''';
  q := 'id, ' || ie_file.quote_date('time') || ', user_id, obj_id, qual, base_id, ' || ie_file.quote_text('value') || '';

  ie_file.start_table_exp(p_owner, table_name, p_date);

  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id' || w || ' order by id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);

      dbms_sql.define_column(c, 1, valsh_rec.id);
      dbms_sql.define_column(c, 2, valsh_rec.time, 30);
      dbms_sql.define_column(c, 3, valsh_rec.user_id, 70);
      dbms_sql.define_column(c, 4, valsh_rec.obj_id, 16);
      dbms_sql.define_column(c, 5, valsh_rec.qual, 700);
      dbms_sql.define_column(c, 6, valsh_rec.base_id, 100);
      dbms_sql.define_column(c, 7, valsh_rec.value, 2000);

      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n<1;

        dbms_sql.column_value(c, 1, valsh_rec.id);
        dbms_sql.column_value(c, 2, valsh_rec.time);
        dbms_sql.column_value(c, 3, valsh_rec.user_id);
        dbms_sql.column_value(c, 4, valsh_rec.obj_id);
        dbms_sql.column_value(c, 5, valsh_rec.qual);
        dbms_sql.column_value(c, 6, valsh_rec.base_id);
        dbms_sql.column_value(c, 7, valsh_rec.value);
        ie_file.put(valsh_rec);
        snapshot_id := valsh_rec.id;
      end loop;
      exit;
    exception when utils.SNAPSHOT_TOO_OLD then
      null;
    end;
  end loop;
  dbms_sql.close_cursor(c);

  ie_file.finish_table_exp();

exception
  when others then
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    ie_file.finish_table_exp();
    raise;
end;



procedure imp_diary(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  diary_rec ie_file.diary_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := 'DIARY';
  p_count := 0;

  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, owner, user_id, topic, text) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',''' || p_owner || ''',' || ie_file.convert_text(':user_id') || ',:topic,' || ie_file.dequote_text(':text') || ')';
  dbms_sql.parse(c, q, dbms_sql.native);

  while ie_file.get(diary_rec) loop
    dbms_sql.bind_variable(c, ':id', diary_rec.id);
    dbms_sql.bind_variable(c, ':time', diary_rec.time, 30);
    dbms_sql.bind_variable(c, ':user_id', diary_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':topic', diary_rec.topic, 10);
    dbms_sql.bind_variable(c, ':text', diary_rec.text, 2000);

    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count:=0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count:=0;

  dbms_sql.close_cursor(c);

exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;

procedure imp_diary_param(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  dp_rec ie_file.diary_param_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := 'DIARY_PARAM';
  p_count := 0;

  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (diary_id, qual, text) values ' ||
    '(:diary_id,:qual,' || ie_file.dequote_text(':text') || ')';
  dbms_sql.parse(c, q, dbms_sql.native);

  while ie_file.get(dp_rec) loop
    dbms_sql.bind_variable(c, ':diary_id', dp_rec.diary_id);
    dbms_sql.bind_variable(c, ':qual', dp_rec.qual, 700);
    dbms_sql.bind_variable(c, ':text', dp_rec.text, 2000);

    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count:=0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count:=0;

  dbms_sql.close_cursor(c);

exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;

procedure imp_object_state_history(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  osh_rec ie_file.object_state_history_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := 'OBJECT_STATE_HISTORY';
  p_count := 0;

  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, owner, user_id, obj_id, state_id) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',''' || p_owner || ''',' || ie_file.convert_text(':user_id') || ',:obj_id,:state_id)';
  dbms_sql.parse(c, q, dbms_sql.native);

  while ie_file.get(osh_rec) loop
    dbms_sql.bind_variable(c, ':id', osh_rec.id);
    dbms_sql.bind_variable(c, ':time', osh_rec.time, 30);
    dbms_sql.bind_variable(c, ':user_id', osh_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':obj_id', osh_rec.obj_id, 100);
    dbms_sql.bind_variable(c, ':state_id', osh_rec.state_id, 700);

    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count:=0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count:=0;

  dbms_sql.close_cursor(c);

exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;

procedure imp_values_history(p_owner in varchar2, p_nrows in pls_integer, p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  valsh_rec ie_file.values_history_rec_t;
  total_lines_count pls_integer := 0;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := 'VALUES_HISTORY';
  p_count := 0;

  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, owner, user_id, obj_id, qual, base_id, value) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',''' || p_owner || ''',' || ie_file.convert_text(':user_id') || ',:obj_id,:qual,:base_id,' || ie_file.dequote_text(':value') || ')';
  dbms_sql.parse(c, q, dbms_sql.native);

  while ie_file.get(valsh_rec) loop
    dbms_sql.bind_variable(c, ':id', valsh_rec.id);
    dbms_sql.bind_variable(c, ':time', valsh_rec.time, 30);
    dbms_sql.bind_variable(c, ':user_id', valsh_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':obj_id', valsh_rec.obj_id, 100);
    dbms_sql.bind_variable(c, ':qual', valsh_rec.qual, 700);
    dbms_sql.bind_variable(c, ':base_id', valsh_rec.base_id, 100);
    dbms_sql.bind_variable(c, ':value', valsh_rec.value, 2000);

    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count:=0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count:=0;

  dbms_sql.close_cursor(c);

exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;

procedure exp(p_owner varchar2, p_code pls_integer, p_date date, p_make_date_safe boolean) is
  v_date date := p_date;
begin
  if v_date is null or p_make_date_safe then
    v_date := ie_db54.date_to(p_owner, p_code, p_date);
    if v_date <= trunc(sysdate) - clear.max_interval then
      return;
    end if;
  end if;
  if p_code = utils.OSH then
    exp_object_state_history(p_owner, v_date);
  elsif p_code = utils.VALSH then
    exp_values_history(p_owner, v_date);
  elsif p_code = utils.DP then
    exp_diary_param(p_owner, v_date);
  else
    if p_code = utils.OCH then -- hack for compatibility
      return;
    end if;
    exp_diary(p_owner, p_code, v_date);
  end if;
end;

procedure clr(p_owner varchar2, p_code pls_integer, p_date date, p_nrows pls_integer,
    p_table in out varchar2, p_count out pls_integer, p_error out varchar2) is
  n pls_integer;
  m number;
  b boolean;
  w varchar2(200);
  r varchar2(30);
  d date;
begin
  p_table := null;
  p_count := 0;
  p_error := null;

  if p_code = utils.OSH then
    p_table := 'OBJECT_STATE_HISTORY';
    w := ' and owner=''' || p_owner || '''';
  elsif p_code = utils.VALSH then
    p_table := 'VALUES_HISTORY';
    w := ' and owner=''' || p_owner || '''';
  elsif p_code = utils.DIARY3 then
    p_table := 'DIARY';
    w := ' and owner=''' || p_owner || ''' and topic in (''U'',''E'')';
  elsif p_code= utils.DIARY4 then
    p_table := 'DIARY';
    w := ' and owner=''' || p_owner || ''' and topic=''S'' and text not like ''LOCK_INFO%''';
  elsif p_code= utils.DIARY5 then
    p_table := 'DIARY';
    w := ' and owner=''' || p_owner || ''' and topic=''S'' and text like ''LOCK_INFO%''';
  elsif p_code= utils.DIARY6 then
    p_table := 'DIARY';
    w := ' and owner=''' || p_owner || ''' and topic in (''H'',''N'')';
  else
    p_table := 'DIARY';
    if p_code in ( utils.DIARY1,  utils.DIARY2) then
      w := ' and owner=''' || p_owner || ''' and topic not in (''S'',''U'',''E'',''H'',''N'')';
    else
      w := ' and owner=''' || p_owner || '''';
    end if;
  end if;
  d := ie_db54.date_to(p_owner, p_code, p_date);

  m := 0;
  if d > trunc(sysdate) - clear.max_interval then
    declare
      s varchar2(2000);
      c integer;
    begin
      c := dbms_sql.open_cursor;
      s := 'delete ' || p_table || ' where time<:d and rownum<=:n' || w;
      dbms_sql.parse(c, s, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', d);
      dbms_sql.bind_variable(c, ':n', p_nrows);
      loop
        n := dbms_sql.execute(c);
        m := m + n;
        commit;
        exit when n < p_nrows;
      end loop;
      dbms_sql.close_cursor(c);
    exception when others then
      p_error := sqlerrm;
      rollback;
      if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
      end if;
    end;
  end if;
  p_count := m;
end;

end;
/
show err package body ie_db34

