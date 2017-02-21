prompt ie_db54
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iedb54_2.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */
ie_db54 is
--
function date_to(p_owner varchar2, p_code pls_integer, p_date date default null) return date is
  d date := p_date;
  ndays number := clear.min_interval;
  diary varchar2(25);
begin
  if p_code = utils.OCH then
    diary := 'OBJECT_COLLECTION_HISTORY';
  elsif p_code = utils.OSH then
    diary := 'OBJECT_STATE_HISTORY';
  elsif p_code = utils.VALSH then
    diary := 'VALUES_HISTORY';
  elsif p_code = utils.DIARY3 then
    diary := 'DIARY_UADMIN';
  elsif p_code = utils.DIARY4 then
    diary := 'DIARY_ADMIN';
  elsif p_code = utils.DIARY5 then
    diary := 'DIARY_SES';
  elsif p_code = utils.DIARY6 then
    diary := 'DIARY_EVENTS';
  else
    diary := 'DIARY';
  end if;
  ndays := nvl(clear.get_interval(p_owner, diary), clear.min_interval);
  if ndays < clear.min_interval then  -- последние min_interval дней очищаться НЕ должны
      ndays := clear.min_interval;
  end if;
  clear.set_interval(p_owner, diary, ndays); commit;
  if d is null or (d > sysdate - ndays) then
      d := trunc(sysdate) - ndays;
  end if;
  return d;
end date_to;
--
procedure exp_diary_n(p_owner varchar2, p_code pls_integer, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100);
  c integer;
  v_rec ie_file.diary_n_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;
  if 1 > p_code or p_code > 6 then
    return;
  end if;
  table_name := p_owner || '_DIARY' || p_code;
  q := 'id,' || ie_file.quote_date('time') || ',replace(user_id, chr(10)),topic,' || ie_file.quote_text('text') || ',code,audsid';
  ie_file.start_table_exp(p_owner, table_name, p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id order by id';
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
      dbms_sql.define_column(c, 6, v_rec.code, 100);
      dbms_sql.define_column(c, 7, v_rec.audsid);
      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n < 1;
        dbms_sql.column_value(c, 1, v_rec.id);
        dbms_sql.column_value(c, 2, v_rec.time);
        dbms_sql.column_value(c, 3, v_rec.user_id);
        dbms_sql.column_value(c, 4, v_rec.topic);
        dbms_sql.column_value(c, 5, v_rec.text);
        dbms_sql.column_value(c, 6, v_rec.code);
        dbms_sql.column_value(c, 7, v_rec.audsid);
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
--
procedure exp_dp(p_owner varchar2, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100) := p_owner || '_DP p, ' || p_owner || '_DIARY2 d';
  w varchar2(200);
  c integer;
  v_rec ie_file.dp_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;
  w := ' and d.id=p.diary_id';
  q := 'p.diary_id,p.qual,' || ie_file.quote_text('p.text') || '';
  ie_file.start_table_exp(p_owner, p_owner || '_DP', p_date);
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
--
procedure exp_och(p_owner varchar2, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100) := p_owner||'_OCH';
  c integer;
  v_rec ie_file.och_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;
  q := 'id,' || ie_file.quote_date('time') || ',user_id,obj_id,collection_id,audsid';
  ie_file.start_table_exp(p_owner, table_name, p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id order by id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);
      dbms_sql.define_column(c, 1, v_rec.id);
      dbms_sql.define_column(c, 2, v_rec.time, 30);
      dbms_sql.define_column(c, 3, v_rec.user_id, 70);
      dbms_sql.define_column(c, 4, v_rec.obj_id, 128);
      dbms_sql.define_column(c, 5, v_rec.collection_id);
      dbms_sql.define_column(c, 6, v_rec.audsid);
      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n<1;
        dbms_sql.column_value(c, 1, v_rec.id);
        dbms_sql.column_value(c, 2, v_rec.time);
        dbms_sql.column_value(c, 3, v_rec.user_id);
        dbms_sql.column_value(c, 4, v_rec.obj_id);
        dbms_sql.column_value(c, 5, v_rec.collection_id);
        dbms_sql.column_value(c, 6, v_rec.audsid);
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
--
procedure exp_osh(p_owner varchar2, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100) := p_owner||'_OSH';
  c integer;
  osh_rec ie_file.osh_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;
  q := 'id,' || ie_file.quote_date('time') || ',user_id,obj_id,state_id,audsid';
  ie_file.start_table_exp(p_owner, table_name, p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id order by id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);
      dbms_sql.define_column(c, 1, osh_rec.id);
      dbms_sql.define_column(c, 2, osh_rec.time, 30);
      dbms_sql.define_column(c, 3, osh_rec.user_id, 70);
      dbms_sql.define_column(c, 4, osh_rec.obj_id, 128);
      dbms_sql.define_column(c, 5, osh_rec.state_id, 700);
      dbms_sql.define_column(c, 6, osh_rec.audsid);
      n := dbms_sql.execute(c);
      loop
        n := dbms_sql.fetch_rows(c);
        exit when n<1;
        dbms_sql.column_value(c, 1, osh_rec.id);
        dbms_sql.column_value(c, 2, osh_rec.time);
        dbms_sql.column_value(c, 3, osh_rec.user_id);
        dbms_sql.column_value(c, 4, osh_rec.obj_id);
        dbms_sql.column_value(c, 5, osh_rec.state_id);
        dbms_sql.column_value(c, 6, osh_rec.audsid);
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
--
procedure exp_valsh(p_owner varchar2, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100) := p_owner||'_VALSH';
  c integer;
  valsh_rec ie_file.valsh_rec_t;
  snapshot_id number;
begin
  ie_file.cleanup_table_inf;
  q := 'id,' || ie_file.quote_date('time') || ',user_id,obj_id,qual,base_id,' || ie_file.quote_text('value') || ',audsid';
  ie_file.start_table_exp(p_owner, table_name, p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d and id > :id order by id';
  snapshot_id := 0;
  loop
    begin
      dbms_sql.parse(c, q, dbms_sql.native);
      dbms_sql.bind_variable(c, ':d', p_date);
      dbms_sql.bind_variable(c, ':id', snapshot_id);
      dbms_sql.define_column(c, 1, valsh_rec.id);
      dbms_sql.define_column(c, 2, valsh_rec.time, 30);
      dbms_sql.define_column(c, 3, valsh_rec.user_id, 70);
      dbms_sql.define_column(c, 4, valsh_rec.obj_id, 128);
      dbms_sql.define_column(c, 5, valsh_rec.qual, 700);
      dbms_sql.define_column(c, 6, valsh_rec.base_id, 100);
      dbms_sql.define_column(c, 7, valsh_rec.value, 2000);
      dbms_sql.define_column(c, 8, valsh_rec.audsid);
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
        dbms_sql.column_value(c, 8, valsh_rec.audsid);
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
--
procedure imp_diary_n(p_owner in varchar2, p_code in pls_integer, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  diary_rec ie_file.diary_n_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := p_owner || '_DIARY' || p_code;
  p_count := 0;
  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, audsid, user_id, topic, code, text) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',:audsid,' || ie_file.convert_text(':user_id') || ',:topic,:code,' || ie_file.dequote_text(':text') || ')';
  dbms_sql.parse(c, q, dbms_sql.native);
  while ie_file.get(diary_rec) loop
    dbms_sql.bind_variable(c, ':id', diary_rec.id);
    dbms_sql.bind_variable(c, ':time', diary_rec.time, 30);
    dbms_sql.bind_variable(c, ':audsid', diary_rec.audsid);
    dbms_sql.bind_variable(c, ':user_id', diary_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':topic', diary_rec.topic, 10);
    dbms_sql.bind_variable(c, ':code', diary_rec.code, 100);
    dbms_sql.bind_variable(c, ':text', diary_rec.text, 2000);
    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count := 0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count := 0;
  dbms_sql.close_cursor(c);
exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;
--
procedure imp_dp(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  dp_rec ie_file.dp_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := p_owner || '_DP';
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
      block_lines_count := 0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count := 0;
  dbms_sql.close_cursor(c);
exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;
--
procedure imp_och(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  och_rec ie_file.och_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := p_owner || '_OCH';
  p_count := 0;
  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, audsid, user_id, obj_id, collection_id) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',:audsid,' || ie_file.convert_text(':user_id') || ',:obj_id,:collection_id)';
  dbms_sql.parse(c, q, dbms_sql.native);
  while ie_file.get(och_rec) loop
    dbms_sql.bind_variable(c, ':id', och_rec.id);
    dbms_sql.bind_variable(c, ':time', och_rec.time, 30);
    dbms_sql.bind_variable(c, ':audsid', och_rec.audsid);
    dbms_sql.bind_variable(c, ':user_id', och_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':obj_id', och_rec.obj_id, 128);
    dbms_sql.bind_variable(c, ':collection_id', och_rec.collection_id);
    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count := 0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count := 0;
  dbms_sql.close_cursor(c);
exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;
--
procedure imp_osh(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  osh_rec ie_file.osh_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := p_owner || '_OSH';
  p_count := 0;
  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, audsid, user_id, obj_id, state_id) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',:audsid,' || ie_file.convert_text(':user_id') || ',:obj_id,:state_id)';
  dbms_sql.parse(c, q, dbms_sql.native);
  while ie_file.get(osh_rec) loop
    dbms_sql.bind_variable(c, ':id', osh_rec.id);
    dbms_sql.bind_variable(c, ':time', osh_rec.time, 30);
    dbms_sql.bind_variable(c, ':audsid', osh_rec.audsid);
    dbms_sql.bind_variable(c, ':user_id', osh_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':obj_id', osh_rec.obj_id, 128);
    dbms_sql.bind_variable(c, ':state_id', osh_rec.state_id, 700);
    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count := 0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count := 0;
  dbms_sql.close_cursor(c);
exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;
--
procedure imp_valsh(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  valsh_rec ie_file.valsh_rec_t;
  block_lines_count pls_integer := 0;
  lines_count pls_integer;
  q varchar2(1000);
  c integer;
begin
  p_table := p_owner || '_VALSH';
  p_count := 0;
  c := dbms_sql.open_cursor;
  q := 'insert into ' || p_table ||
    ' (id, time, audsid, user_id, obj_id, qual, base_id, value) values ' ||
    '(:id,' || ie_file.dequote_date(':time') || ',:audsid,' || ie_file.convert_text(':user_id') || ',:obj_id,:qual,:base_id,' || ie_file.dequote_text(':value') || ')';
  dbms_sql.parse(c, q, dbms_sql.native);
  while ie_file.get(valsh_rec) loop
    dbms_sql.bind_variable(c, ':id', valsh_rec.id);
    dbms_sql.bind_variable(c, ':time', valsh_rec.time, 30);
    dbms_sql.bind_variable(c, ':audsid', valsh_rec.audsid);
    dbms_sql.bind_variable(c, ':user_id', valsh_rec.user_id, 70);
    dbms_sql.bind_variable(c, ':obj_id', valsh_rec.obj_id, 128);
    dbms_sql.bind_variable(c, ':qual', valsh_rec.qual, 700);
    dbms_sql.bind_variable(c, ':base_id', valsh_rec.base_id, 100);
    dbms_sql.bind_variable(c, ':value', valsh_rec.value, 2000);
    lines_count := dbms_sql.execute(c);
    block_lines_count := block_lines_count + lines_count;
    if block_lines_count >= p_nrows then
      commit;
      p_count := p_count + block_lines_count;
      block_lines_count := 0;
    end if;
  end loop;
  commit;
  p_count := p_count + block_lines_count;
  block_lines_count := 0;
  dbms_sql.close_cursor(c);
exception
  when others then
    rollback;
    if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
    end if;
    raise;
end;
--
procedure exp(p_owner varchar2, v6 boolean, p_code pls_integer, p_date date, p_make_date_safe boolean) is
  v_date date := p_date;
  v_code pls_integer;
begin
  if not ie_db61.chk_exp_date(p_owner,p_code,v_date,p_make_date_safe,false) then
    return;
  end if;
  if p_code = utils.OCH then
    if v6 then
      exp_och(p_owner, v_date);
    end if;
  elsif p_code = utils.OSH then
    exp_osh(p_owner, v_date);
  elsif p_code = utils.VALSH then
    exp_valsh(p_owner, v_date);
  elsif p_code = utils.DP then
    exp_dp(p_owner, v_date);
  elsif p_code>0 then
    if p_code > 6 then
      v_code := 1;
    else
      v_code := p_code;
    end if;
    exp_diary_n(p_owner, v_code, v_date);
  end if;
end;
--
procedure clr(p_owner varchar2, p_code pls_integer, p_date date, p_nrows pls_integer,
              p_table in out varchar2, p_count out pls_integer, p_error out varchar2) is
  b boolean;
  c pls_integer;
  d date;
begin
  if p_code > 6 then
    c := 1;
  else
    c := p_code;
  end if;
  d := date_to(p_owner, c, p_date);
  p_table := utils.table_name(p_owner,c,false);
  if d > trunc(sysdate) - clear.max_interval then
    utils.delete_data(p_table,d,p_nrows,p_count,p_error);
  end if;
end;
--
end;
/
show err package body ie_db54

