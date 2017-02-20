prompt ie_db61
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iedb61_2.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */
ie_db61 is
--
type number_tbl_t is table of number index by binary_integer;
type str100_tbl_t is table of varchar2(128) index by binary_integer;
type str4000_tbl_t is table of varchar2(4000) index by binary_integer;
--
type diary_n_recs_t is record (
  id number_tbl_t,
  time str100_tbl_t,
  audsid number_tbl_t,
  user_id str100_tbl_t,
  topic str100_tbl_t,
  code str100_tbl_t,
  text str4000_tbl_t
);
type dp_recs_t is record (
  diary_id number_tbl_t,
  time str100_tbl_t,
  qual str4000_tbl_t,
  base_id str100_tbl_t,
  text str4000_tbl_t
);
type och_recs_t is record (
  id number_tbl_t,
  time str100_tbl_t,
  obj_id   str100_tbl_t,
  class_id str100_tbl_t,
  collection_id number_tbl_t,
  obj_parent str4000_tbl_t,
  audsid number_tbl_t,
  user_id str100_tbl_t
);
type osh_recs_t is record (
  id number_tbl_t,
  time str100_tbl_t,
  obj_id   str100_tbl_t,
  class_id str100_tbl_t,
  state_id str100_tbl_t,
  audsid number_tbl_t,
  user_id str100_tbl_t
);
type valsh_recs_t is record (
  id number_tbl_t,
  time str100_tbl_t,
  obj_id   str100_tbl_t,
  class_id str100_tbl_t,
  audsid number_tbl_t,
  user_id str100_tbl_t,
  qual str4000_tbl_t,
  base_id str100_tbl_t,
  value str4000_tbl_t
);
type edh_recs_t is record (
  id number_tbl_t,
  time str100_tbl_t,
  obj_id   str100_tbl_t,
  class_id str100_tbl_t,
  audsid number_tbl_t,
  user_id str100_tbl_t,
  type_id str100_tbl_t,
  code str100_tbl_t,
  text str4000_tbl_t
);
--
function flush_diary_n(diary in out nocopy diary_n_recs_t, table_name varchar2) return pls_integer is
  lines_count pls_integer;
begin
  if diary.id.count = 0 then
    return 0;
  end if;
  forall i in diary.id.first..diary.id.last
    execute immediate 'insert into ' || table_name ||
      ' (id, time, audsid, user_id, topic, code, text) values ' ||
      '(:id, ' || ie_file.dequote_timestamp(':time') || ',:audsid,' || ie_file.convert_text(':user_id') || ',:topic,:code,' || ie_file.dequote_text(':text') || ')'
    using diary.id(i), diary.time(i), diary.audsid(i), diary.user_id(i), diary.topic(i), diary.code(i), diary.text(i);
  commit;
  lines_count := diary.id.count;
  diary.id.delete;
  diary.time.delete;
  diary.audsid.delete;
  diary.user_id.delete;
  diary.topic.delete;
  diary.code.delete;
  diary.text.delete;
  return lines_count;
end;
--
function flush_dp(diary in out nocopy dp_recs_t, table_name varchar2, d2_table_name varchar2 default null) return pls_integer is
  lines_count pls_integer;
begin
  if diary.diary_id.count = 0 then
    return 0;
  end if;
  if d2_table_name is null then
    forall i in diary.diary_id.first..diary.diary_id.last
      execute immediate 'insert into ' || table_name ||
        ' (diary_id, time, qual, base_id, text) values ' ||
        '(:diary_id,' || ie_file.dequote_timestamp(':time') || ',:qual,:base_id,' || ie_file.dequote_text(':text') || ')'
      using diary.diary_id(i), diary.time(i), diary.qual(i), diary.base_id(i), diary.text(i);
  else
    forall i in diary.diary_id.first..diary.diary_id.last
      execute immediate 'insert into ' || table_name ||
        ' (diary_id, qual, base_id, text, time) values ' ||
        '(:diary_id,:qual,:base_id,' || ie_file.dequote_text(':text') || ',' ||
        ' (select time from ' || d2_table_name || ' where id=:diary_id and rownum<2))'
      using diary.diary_id(i), diary.qual(i), diary.base_id(i), diary.text(i), diary.diary_id(i);
  end if;
  commit;
  lines_count := diary.diary_id.count;
  diary.diary_id.delete;
  diary.time.delete;
  diary.qual.delete;
  diary.base_id.delete;
  diary.text.delete;
  return lines_count;
end;
--
function flush_och(diary in out nocopy och_recs_t, table_name varchar2) return pls_integer is
  lines_count pls_integer;
begin
  if diary.id.count = 0 then
    return 0;
  end if;
  forall i in diary.id.first..diary.id.last
    execute immediate 'insert into ' || table_name ||
      ' (id, time, obj_id, class_id, collection_id, obj_parent, audsid, user_id) values ' ||
      '(:id,' || ie_file.dequote_timestamp(':time') || ',:obj_id,:class_id,:collection_id,' || ie_file.dequote_text(':obj_parent') || ',:audsid,' || ie_file.convert_text(':user_id') || ')'
    using diary.id(i), diary.time(i), diary.obj_id(i), diary.class_id(i), diary.collection_id(i), diary.obj_parent(i), diary.audsid(i), diary.user_id(i);
  commit;
  lines_count := diary.id.count;
  diary.id.delete;
  diary.time.delete;
  diary.obj_id.delete;
  diary.class_id.delete;
  diary.collection_id.delete;
  diary.obj_parent.delete;
  diary.audsid.delete;
  diary.user_id.delete;
  return lines_count;
end;
--
function flush_osh(diary in out nocopy osh_recs_t, table_name varchar2) return pls_integer is
  lines_count pls_integer;
begin
  if diary.id.count = 0 then
    return 0;
  end if;
  forall i in diary.id.first..diary.id.last
    execute immediate 'insert into ' || table_name ||
      ' (id, time, obj_id, class_id, state_id, audsid, user_id) values ' ||
      '(:id,' || ie_file.dequote_timestamp(':time') || ',:obj_id,:class_id,:state_id,:audsid,' || ie_file.convert_text(':user_id') || ')'
    using diary.id(i), diary.time(i), diary.obj_id(i), diary.class_id(i), diary.state_id(i), diary.audsid(i), diary.user_id(i);
  commit;
  lines_count := diary.id.count;
  diary.id.delete;
  diary.time.delete;
  diary.obj_id.delete;
  diary.class_id.delete;
  diary.state_id.delete;
  diary.audsid.delete;
  diary.user_id.delete;
  return lines_count;
end;
--
function flush_valsh(diary in out nocopy valsh_recs_t, table_name varchar2) return pls_integer is
  lines_count pls_integer;
begin
  if diary.id.count = 0 then
    return 0;
  end if;
  forall i in diary.id.first..diary.id.last
    execute immediate 'insert into ' || table_name ||
      ' (id, time, obj_id, class_id, audsid, user_id, qual, base_id, value) values ' ||
      '(:id,' || ie_file.dequote_timestamp(':time') || ',:obj_id,:class_id,:audsid,' || ie_file.convert_text(':user_id') || ',:qual,:base_id,' || ie_file.dequote_text(':value') || ')'
    using diary.id(i), diary.time(i), diary.obj_id(i), diary.class_id(i), diary.audsid(i), diary.user_id(i), diary.qual(i), diary.base_id(i), diary.value(i);
  commit;
  lines_count := diary.id.count;
  diary.id.delete;
  diary.time.delete;
  diary.obj_id.delete;
  diary.class_id.delete;
  diary.audsid.delete;
  diary.user_id.delete;
  diary.qual.delete;
  diary.base_id.delete;
  diary.value.delete;
  return lines_count;
end;
--
function flush_edh(diary in out nocopy edh_recs_t, table_name varchar2) return pls_integer is
  lines_count pls_integer;
begin
  if diary.id.count = 0 then
    return 0;
  end if;
  forall i in diary.id.first..diary.id.last
    execute immediate 'insert into ' || table_name ||
      ' (id, time, obj_id, class_id, audsid, user_id, type_id, code, text) values ' ||
      '(:id,' || ie_file.dequote_timestamp(':time') || ',:obj_id,:class_id,:audsid,' || ie_file.convert_text(':user_id') || ',:type_id,:code,' || ie_file.dequote_text(':text') || ')'
    using diary.id(i), diary.time(i), diary.obj_id(i), diary.class_id(i), diary.audsid(i), diary.user_id(i), diary.type_id(i), diary.code(i), diary.text(i);
  commit;
  lines_count := diary.id.count;
  diary.id.delete;
  diary.time.delete;
  diary.obj_id.delete;
  diary.class_id.delete;
  diary.audsid.delete;
  diary.user_id.delete;
  diary.type_id.delete;
  diary.code.delete;
  diary.text.delete;
  return lines_count;
end;
--
function date_to(p_owner varchar2, p_code pls_integer,
                 p_date date default null, p_parts boolean default true) return date is
  d date;
begin
  d := ie_db54.date_to(p_owner, p_code, p_date);
  if p_parts and utils.AudPartitions then
    utils.nearest_trunc_date(p_owner, p_code, d);
  end if;
  return d;
end date_to;
--
function chk_exp_date(p_owner varchar2, p_code pls_integer, p_date  in out nocopy date,
                      p_make_date_safe boolean default true,p_parts boolean default true) return boolean is
begin
  if p_date is null or p_make_date_safe then
    p_date := date_to(p_owner, p_code, p_date, p_parts);
    if p_date <= trunc(sysdate) - clear.max_interval then
      return false;
    end if;
  end if;
  return true;
end;
--
procedure exp_diary_n(p_owner varchar2, p_code pls_integer, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100);
  c integer;
  v_rec ie_file.diary_n_rec_t;
begin
  ie_file.cleanup_table_inf;
  if 1 > p_code and p_code > 7 then
    return;
  end if;
  table_name := utils.table_name(p_owner, p_code);
  q := 'id, ' || ie_file.quote_timestamp('time') || ', audsid, replace(user_id, chr(10)), topic, code, ' || ie_file.quote_text('text');
  ie_file.start_table_exp(p_owner, p_owner || '_DIARY' || p_code, p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d order by id';
  dbms_sql.parse(c, q, dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.define_column(c, 1, v_rec.id);
  dbms_sql.define_column(c, 2, v_rec.time, 30);
  dbms_sql.define_column(c, 3, v_rec.audsid);
  dbms_sql.define_column(c, 4, v_rec.user_id, 70);
  dbms_sql.define_column(c, 5, v_rec.topic, 10);
  dbms_sql.define_column(c, 6, v_rec.code, 100);
  dbms_sql.define_column(c, 7, v_rec.text, 4000);
  n := dbms_sql.execute(c);
  loop
    n := dbms_sql.fetch_rows(c);
    exit when n < 1;
    dbms_sql.column_value(c, 1, v_rec.id);
    dbms_sql.column_value(c, 2, v_rec.time);
    dbms_sql.column_value(c, 3, v_rec.audsid);
    dbms_sql.column_value(c, 4, v_rec.user_id);
    dbms_sql.column_value(c, 5, v_rec.topic);
    dbms_sql.column_value(c, 6, v_rec.code);
    dbms_sql.column_value(c, 7, v_rec.text);
    ie_file.put(v_rec);
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
  table_name varchar2(100);
  c integer;
  v_rec ie_file.dp_rec_t;
begin
  ie_file.cleanup_table_inf;
  table_name := utils.table_name(p_owner, utils.DP);
  q := 'diary_id, ' || ie_file.quote_timestamp('time') || ', qual, base_id, ' || ie_file.quote_text('text');
  ie_file.start_table_exp(p_owner, p_owner || '_DP', p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d order by diary_id';
  dbms_sql.parse(c, q, dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.define_column(c, 1, v_rec.diary_id);
  dbms_sql.define_column(c, 2, v_rec.time, 30);
  dbms_sql.define_column(c, 3, v_rec.qual, 700);
  dbms_sql.define_column(c, 4, v_rec.base_id, 16);
  dbms_sql.define_column(c, 5, v_rec.text, 4000);
  n := dbms_sql.execute(c);
  loop
    n := dbms_sql.fetch_rows(c);
    exit when n<1;
    dbms_sql.column_value(c, 1, v_rec.diary_id);
    dbms_sql.column_value(c, 2, v_rec.time);
    dbms_sql.column_value(c, 3, v_rec.qual);
    dbms_sql.column_value(c, 4, v_rec.base_id);
    dbms_sql.column_value(c, 5, v_rec.text);
    ie_file.put(v_rec);
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
  table_name varchar2(100);
  c integer;
  v_rec ie_file.och_rec_t;
begin
  ie_file.cleanup_table_inf;
  table_name := utils.table_name(p_owner, utils.OCH);
  q := 'id, ' || ie_file.quote_timestamp('time') || ', obj_id, class_id, collection_id, ' || ie_file.quote_text('obj_parent') || ', audsid, user_id';
  ie_file.start_table_exp(p_owner, p_owner || '_OCH', p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d order by id';
  dbms_sql.parse(c, q, dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.define_column(c, 1, v_rec.id);
  dbms_sql.define_column(c, 2, v_rec.time, 30);
  dbms_sql.define_column(c, 3, v_rec.obj_id, 128);
  dbms_sql.define_column(c, 4, v_rec.class_id, 16);
  dbms_sql.define_column(c, 5, v_rec.collection_id);
  dbms_sql.define_column(c, 6, v_rec.obj_parent, 2000);
  dbms_sql.define_column(c, 7, v_rec.audsid);
  dbms_sql.define_column(c, 8, v_rec.user_id, 70);
  n := dbms_sql.execute(c);
  loop
    n := dbms_sql.fetch_rows(c);
    exit when n<1;
    dbms_sql.column_value(c, 1, v_rec.id);
    dbms_sql.column_value(c, 2, v_rec.time);
    dbms_sql.column_value(c, 3, v_rec.obj_id);
    dbms_sql.column_value(c, 4, v_rec.class_id);
    dbms_sql.column_value(c, 5, v_rec.collection_id);
    dbms_sql.column_value(c, 6, v_rec.obj_parent);
    dbms_sql.column_value(c, 7, v_rec.audsid);
    dbms_sql.column_value(c, 8, v_rec.user_id);
    ie_file.put(v_rec);
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
  table_name varchar2(100);
  c integer;
  osh_rec ie_file.osh_rec_t;
begin
  ie_file.cleanup_table_inf;
  table_name := utils.table_name(p_owner, utils.OSH);
  q := 'id, ' || ie_file.quote_timestamp('time') || ', obj_id, class_id, state_id, audsid, user_id';
  ie_file.start_table_exp(p_owner, p_owner || '_OSH', p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d order by id';
  dbms_sql.parse(c, q, dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.define_column(c, 1, osh_rec.id);
  dbms_sql.define_column(c, 2, osh_rec.time, 30);
  dbms_sql.define_column(c, 3, osh_rec.obj_id, 128);
  dbms_sql.define_column(c, 4, osh_rec.class_id, 16);
  dbms_sql.define_column(c, 5, osh_rec.state_id, 700);
  dbms_sql.define_column(c, 6, osh_rec.audsid);
  dbms_sql.define_column(c, 7, osh_rec.user_id, 70);
  n := dbms_sql.execute(c);
  loop
    n := dbms_sql.fetch_rows(c);
    exit when n<1;
    dbms_sql.column_value(c, 1, osh_rec.id);
    dbms_sql.column_value(c, 2, osh_rec.time);
    dbms_sql.column_value(c, 3, osh_rec.obj_id);
    dbms_sql.column_value(c, 4, osh_rec.class_id);
    dbms_sql.column_value(c, 5, osh_rec.state_id);
    dbms_sql.column_value(c, 6, osh_rec.audsid);
    dbms_sql.column_value(c, 7, osh_rec.user_id);
    ie_file.put(osh_rec);
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
  table_name varchar2(100);
  c integer;
  valsh_rec ie_file.valsh_rec_t;
begin
  ie_file.cleanup_table_inf;
  table_name := utils.table_name(p_owner, utils.VALSH);
  q := 'id, ' || ie_file.quote_timestamp('time') || ', obj_id, class_id, audsid, user_id, qual, base_id, ' || ie_file.quote_text('value');
  ie_file.start_table_exp(p_owner, p_owner || '_VALSH', p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d order by id';
  dbms_sql.parse(c, q, dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.define_column(c, 1, valsh_rec.id);
  dbms_sql.define_column(c, 2, valsh_rec.time, 30);
  dbms_sql.define_column(c, 3, valsh_rec.obj_id, 128);
  dbms_sql.define_column(c, 4, valsh_rec.class_id, 16);
  dbms_sql.define_column(c, 5, valsh_rec.audsid);
  dbms_sql.define_column(c, 6, valsh_rec.user_id, 70);
  dbms_sql.define_column(c, 7, valsh_rec.qual, 700);
  dbms_sql.define_column(c, 8, valsh_rec.base_id, 100);
  dbms_sql.define_column(c, 9, valsh_rec.value, 4000);
  n := dbms_sql.execute(c);
  loop
    n := dbms_sql.fetch_rows(c);
    exit when n<1;
    dbms_sql.column_value(c, 1, valsh_rec.id);
    dbms_sql.column_value(c, 2, valsh_rec.time);
    dbms_sql.column_value(c, 3, valsh_rec.obj_id);
    dbms_sql.column_value(c, 4, valsh_rec.class_id);
    dbms_sql.column_value(c, 5, valsh_rec.audsid);
    dbms_sql.column_value(c, 6, valsh_rec.user_id);
    dbms_sql.column_value(c, 7, valsh_rec.qual);
    dbms_sql.column_value(c, 8, valsh_rec.base_id);
    dbms_sql.column_value(c, 9, valsh_rec.value);
    ie_file.put(valsh_rec);
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
procedure exp_edh(p_owner varchar2, p_date date) is
  n number;
  q varchar2(1000);
  table_name varchar2(100);
  c integer;
  edh_rec ie_file.edh_rec_t;
begin
  ie_file.cleanup_table_inf;
  table_name := utils.table_name(p_owner, utils.EDH);
  q := 'id, ' || ie_file.quote_timestamp('time') || ', obj_id, class_id, audsid, user_id, type_id, code, ' || ie_file.quote_text('text');
  ie_file.start_table_exp(p_owner, p_owner || '_EDH', p_date);
  c := dbms_sql.open_cursor;
  q := 'select ' || q || ' from ' || table_name || ' where time < :d order by id';
  dbms_sql.parse(c, q, dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.define_column(c, 1, edh_rec.id);
  dbms_sql.define_column(c, 2, edh_rec.time, 30);
  dbms_sql.define_column(c, 3, edh_rec.obj_id, 128);
  dbms_sql.define_column(c, 4, edh_rec.class_id, 16);
  dbms_sql.define_column(c, 5, edh_rec.audsid);
  dbms_sql.define_column(c, 6, edh_rec.user_id, 70);
  dbms_sql.define_column(c, 7, edh_rec.type_id, 16);
  dbms_sql.define_column(c, 8, edh_rec.code, 70);
  dbms_sql.define_column(c, 9, edh_rec.text, 4000);
  n := dbms_sql.execute(c);
  loop
    n := dbms_sql.fetch_rows(c);
    exit when n<1;
    dbms_sql.column_value(c, 1, edh_rec.id);
    dbms_sql.column_value(c, 2, edh_rec.time);
    dbms_sql.column_value(c, 3, edh_rec.obj_id);
    dbms_sql.column_value(c, 4, edh_rec.class_id);
    dbms_sql.column_value(c, 5, edh_rec.audsid);
    dbms_sql.column_value(c, 6, edh_rec.user_id);
    dbms_sql.column_value(c, 7, edh_rec.type_id);
    dbms_sql.column_value(c, 8, edh_rec.code);
    dbms_sql.column_value(c, 9, edh_rec.text);
    ie_file.put(edh_rec);
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
procedure imp_diary(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  diary_rec ie_file.diary_rec_t;
  d1 diary_n_recs_t;
  d2 diary_n_recs_t;
  d3 diary_n_recs_t;
  d4 diary_n_recs_t;
  d5 diary_n_recs_t;
  d7 diary_n_recs_t;
  d_index pls_integer;
  pos pls_integer;
  pos1 pls_integer;
  pos2 pls_integer;
  tmp varchar2(4000);
  q varchar2(1000);
--
  procedure append_table(table_name in varchar2) is
  begin
    if p_table is null then
      p_table := table_name;
    elsif instr(p_table, table_name) = 0 then
      p_table := p_table || ', ' || table_name;
    end if;
  end;
begin
  p_table := null;
  p_count := 0;
  while ie_file.get(diary_rec) loop
    if diary_rec.topic = 'L' then
      d_index := nvl(d1.id.last, 0) + 1;
      d1.id(d_index) := diary_rec.id;
      d1.time(d_index) := diary_rec.time;
      pos := instr(diary_rec.text,'.',1,4);
      if pos = 0 then
        d1.audsid(d_index) := to_number(null);
      else
        d1.audsid(d_index) := substr(diary_rec.text, pos + 1);
      end if;
      d1.user_id(d_index) := diary_rec.user_id;
      d1.topic(d_index) := diary_rec.topic;
      pos1 := instr(diary_rec.text, '.');
      d1.code(d_index) := substr(diary_rec.text, 1, pos1 - 1);
      d1.text(d_index) := nvl(substr(diary_rec.text, pos1 + 1, pos - pos1 - 1), substr(diary_rec.text, pos1 + 1));
      if d1.id.count >= p_nrows then
        tmp := utils.table_name(p_owner, utils.DIARY1);
        p_count := p_count + flush_diary_n(d1, tmp);
        append_table(tmp);
      end if;
    elsif diary_rec.topic = 'P' then
      d_index := nvl(d2.id.last, 0) + 1;
      d2.id(d_index) := diary_rec.id;
      d2.time(d_index) := diary_rec.time;
      d2.user_id(d_index) := diary_rec.user_id;
      pos := instr(diary_rec.text, '.');
      if pos > 0 then
        d2.audsid(d_index) := to_number(substr(diary_rec.text, 1, pos - 1));
        d2.code(d_index) := substr(diary_rec.text, pos + 1);
      else
        d2.audsid(d_index) := to_number(null);
        d2.code(d_index) := substr(diary_rec.text, 1, 30);
      end if;
      d2.topic(d_index) := diary_rec.topic;
      d2.text(d_index) := null;
      if d2.id.count >= p_nrows then
        tmp := utils.table_name(p_owner, utils.DIARY2);
        p_count := p_count + flush_diary_n(d2, tmp);
        append_table(tmp);
      end if;
    elsif diary_rec.topic = 'E' or diary_rec.topic = 'U' then
      d_index := nvl(d3.id.last, 0) + 1;
      if diary_rec.topic = 'E' then
        d3.id(d_index) := diary_rec.id;
        d3.time(d_index) := diary_rec.time;
        d3.audsid(d_index) := null;
        d3.user_id(d_index) := diary_rec.user_id;
        d3.topic(d_index) := diary_rec.topic;
        pos := instr(diary_rec.text, ':');
        d3.code(d_index) := substr(diary_rec.text, 1, pos - 1);
        d3.text(d_index) := ltrim(substr(diary_rec.text, pos + 1));
      else
        d3.id(d_index) := diary_rec.id;
        d3.time(d_index) := diary_rec.time;
        d3.audsid(d_index) := null;
        d3.user_id(d_index) := diary_rec.user_id;
        d3.topic(d_index) := diary_rec.topic;
        d3.code(d_index) := null;
        d3.text(d_index) := diary_rec.text;
      end if;
      if d3.id.count >= p_nrows then
        tmp := utils.table_name(p_owner, utils.DIARY3);
        p_count := p_count + flush_diary_n(d3, tmp);
        append_table(tmp);
      end if;
    elsif diary_rec.topic = 'S' then
      if diary_rec.text like 'LOCK_INFO%' then
        d_index := nvl(d5.id.last, 0) + 1;
        d5.id(d_index) := diary_rec.id;
        d5.time(d_index) := diary_rec.time;
        --decode(instr(text,'ORA-'),0,decode(sign(ascii(substr(text,instr(text,' ',-1)+1))-58),-1,substr(text,instr(text,' ',-1)+1),'0'),'0'),
        if instr(diary_rec.text,'ORA-') = 0 then
          begin
            d5.audsid(d_index) := substr(diary_rec.text, instr(diary_rec.text, ' ', -1) + 1);
          exception when VALUE_ERROR then
            d5.audsid(d_index) := 0;
          end;
        else
          d5.audsid(d_index) := 0;
        end if;
        if substr(diary_rec.text,10,1) = ':' then
          pos := instr(diary_rec.text, ' - ', 1, 2);
          pos1 := instr(diary_rec.text,') ');
          diary_rec.user_id := nvl(substr(diary_rec.text, pos + 3, pos1 - pos - 3), diary_rec.user_id);
        end if;
        d5.user_id(d_index) := diary_rec.user_id;
        if substr(diary_rec.text,10,1) = ':' then
          diary_rec.topic := 'I';
        else
          diary_rec.topic := 'J';
        end if;
        d5.topic(d_index) := diary_rec.topic;
        if instr(diary_rec.text,'ORA-') = 0 then
          pos := instr(diary_rec.text, ') ');
          pos1 := instr(diary_rec.text,' ', pos + 2, 2);
          d5.code(d_index) := substr(upper(rtrim(rtrim(substr(diary_rec.text, pos + 2, pos1 - pos - 2),' :'),' -')), 1, 30);
        else
          d5.code(d_index) := 'ERROR';
        end if;
        if substr(diary_rec.text,10,1) = ':' then
          tmp := substr(diary_rec.text, 12, instr(diary_rec.text, ' : ', -1) - 12);
        else
          tmp := substr(diary_rec.text, 11, instr(diary_rec.text, ' - ', -1) - 11);
        end if;
        d5.text(d_index) := nvl(tmp, substr(diary_rec.text, 11));
        if d5.id.count >= p_nrows then
          tmp := utils.table_name(p_owner, utils.DIARY5);
          p_count := p_count + flush_diary_n(d5, tmp);
          append_table(tmp);
        end if;
      else
        d_index := nvl(d4.id.last, 0) + 1;
        if diary_rec.text like 'STORAGE: %' then
          --storage
          d4.id(d_index) := diary_rec.id;
          d4.time(d_index) := diary_rec.time;
          pos := instr(diary_rec.text,'(',-1);
          pos1 := instr(diary_rec.text,')',-1);
          d4.audsid(d_index) := substr(diary_rec.text, pos + 1 , pos1 - pos - 1);
          pos := instr(diary_rec.text,' - ',-1);
          pos1 := instr(diary_rec.text,'(',-1);
          d4.user_id(d_index) := diary_rec.user_id || '.' || substr(diary_rec.text, pos + 3, pos1 - pos - 3);
          d4.topic(d_index) := 'B';
          pos := instr(diary_rec.text, ':');
          pos1 := instr(diary_rec.text, ':', 1, 2);
          d4.code(d_index) := substr(diary_rec.text, pos + 2, pos1 - pos - 2);
          if instr(diary_rec.text,': RECONCILE_CLASS_TABLE - ') > 0 then
            diary_rec.text := 'REBUILDED:';
          elsif instr(diary_rec.text,': DELETE_CLASS - ') > 0 then
            diary_rec.text := 'REMOVED:';
          elsif instr(diary_rec.text, ': DELETE_CLASS_ENTIRELY - ') > 0 then
            diary_rec.text := 'DROPPED:';
          elsif instr(diary_rec.text,': Renamed [') > 0 then
            pos := instr(diary_rec.text,'[');
            diary_rec.text := 'RENAMED ' || substr(diary_rec.text, pos, instr(diary_rec.text,']') - pos + 1) || ':';
          else
            pos := instr(diary_rec.text,':',1,2);
            diary_rec.text := 'UPDATED' || substr(diary_rec.text, pos, instr(diary_rec.text, ' - ', -1) - pos);
          end if;
          d4.text(d_index) := diary_rec.text;
        elsif (diary_rec.text like 'GENERATE%' or diary_rec.text like 'DROP%' or diary_rec.text like 'CRITERIA%') then
          --methods
          d4.id(d_index) := diary_rec.id;
          d4.time(d_index) := diary_rec.time;
          pos := instr(diary_rec.text,'(');
          pos1 := instr(diary_rec.text,')');
          d4.audsid(d_index) := substr(diary_rec.text, pos + 1, pos1 - pos - 1);
          pos1 := instr(diary_rec.text,' - ');
          d4.user_id(d_index) := diary_rec.user_id || '.' || substr(diary_rec.text, pos1 + 3, pos - pos1 - 3);
          if substr(diary_rec.text,1,4) = 'CRIT' then
            diary_rec.topic := 'C';
          else
            diary_rec.topic := 'M';
          end if;
          d4.topic(d_index) := diary_rec.topic;
          pos := instr(diary_rec.text, ':');
          pos1 := instr(diary_rec.text, ':', 1, 2);
          d4.code(d_index) := substr(diary_rec.text, pos + 2, pos1 - pos - 2);
          if instr(diary_rec.text,'DROP:') = 0 then
            if instr(diary_rec.text,'ERROR:') = 0 then
              tmp := 'COMPILE';
            else
              tmp := 'ERROR';
            end if;
          else
            tmp := 'DROP';
          end if;
          pos := instr(diary_rec.text,')');
          pos1 := instr(diary_rec.text,' - ');
          pos2 := instr(diary_rec.text,':', 1, 2);
          d4.text(d_index) := tmp || substr(diary_rec.text, pos2, pos1 - pos2) || substr(diary_rec.text, pos + 1);
        elsif (diary_rec.text like 'PARAMETER %' or diary_rec.text like 'VARIABLE %' or diary_rec.text like 'STATE %' or diary_rec.text like 'TRANSITION %' or diary_rec.text like 'ATTRIBUTE %') then
          --attrs
          d4.id(d_index) := diary_rec.id;
          d4.time(d_index) := diary_rec.time;
          d4.audsid(d_index) := substr(diary_rec.text, instr(diary_rec.text, '.', -1) + 1);
          pos := instr(diary_rec.text, '.', -1, 2);
          pos1 := instr(diary_rec.text, '.', -1);
          d4.user_id(d_index) := diary_rec.user_id || '.' || substr(diary_rec.text, pos + 1, pos1 - pos - 1);
          tmp := substr(diary_rec.text, 1, 3);
          if tmp = 'PAR' then
            diary_rec.topic := 'R';
          elsif tmp = 'VAR' then
            diary_rec.topic := 'V';
          elsif tmp = 'STA' then
            diary_rec.topic := 'S';
          elsif tmp = 'TRA' then
            diary_rec.topic := 'T';
          else
            diary_rec.topic := 'A';
          end if;
          d4.topic(d_index) := diary_rec.topic;
          if substr(diary_rec.text,2,1) = 'A' then
            pos := instr(diary_rec.text,':');
            pos1 := instr(diary_rec.text, ':', 1, 2);
            d4.code(d_index) := substr(diary_rec.text, pos + 2, pos1 - pos - 2);
          else
            pos := instr(diary_rec.text,':');
            pos1 := instr(diary_rec.text, '.');
            d4.code(d_index) := substr(diary_rec.text, pos + 2, pos1 - pos - 2);
          end if;
          pos := instr(diary_rec.text, ' ');
          pos1 := instr(diary_rec.text, ':');
          tmp := substr(diary_rec.text, pos + 1, pos1 - pos + 1);
          if substr(diary_rec.text, 2, 1) = 'A' then
            pos := instr(diary_rec.text, ':', 1, 2);
            pos1 := instr(diary_rec.text, ' : ', -1);
            diary_rec.text := tmp || substr(diary_rec.text, pos + 2, pos1 - pos - 2);
          else
            pos := instr(diary_rec.text, '.');
            pos1 := instr(diary_rec.text, ' : ', -1);
            diary_rec.text := tmp || substr(diary_rec.text, pos + 1, pos1 - pos - 1);
          end if;
          d4.text(d_index) := diary_rec.text;
        elsif diary_rec.text like 'SYSINFO: %' then
          --info
          d4.id(d_index) := diary_rec.id;
          d4.time(d_index) := diary_rec.time;
          pos := instr(diary_rec.text, '(');
          pos1 := instr(diary_rec.text, ')');
          d4.audsid(d_index) := substr(diary_rec.text, pos + 1, pos1 - pos - 1);
          pos := instr(diary_rec.text,': ');
          pos1 := instr(diary_rec.text,'(');
          d4.user_id(d_index) := diary_rec.user_id || '.' || substr(diary_rec.text, pos + 2 , pos1 - pos - 3);
          d4.topic(d_index) := 'G';
          pos := instr(diary_rec.text, ')');
          pos1 := instr(diary_rec.text, ':', 1, 2);
          d4.code(d_index) := upper(substr(diary_rec.text, pos + 2, pos1 - pos - 2));
          pos := instr(diary_rec.text, '(', -1);
          pos1 := instr(diary_rec.text, ')', -1);
          d4.text(d_index) := substr(diary_rec.text, pos + 1, pos1 - pos - 1);
        else
          --others
          d4.id(d_index) := diary_rec.id;
          d4.time(d_index) := diary_rec.time;
          d4.audsid(d_index) := null;
          d4.user_id(d_index) := diary_rec.user_id;
          d4.topic(d_index) := 'O';
          d4.code(d_index) := ltrim(rtrim(upper(substr(diary_rec.text, 1, instr(diary_rec.text,':') - 1))));
          d4.text(d_index) := ltrim(substr(diary_rec.text, instr(diary_rec.text, ':') + 1));
        end if;
        if d4.id.count >= p_nrows then
          tmp := utils.table_name(p_owner, utils.DIARY4);
          p_count := p_count + flush_diary_n(d4, tmp);
          append_table(tmp);
        end if;
      end if;
    elsif diary_rec.topic = 'D' then
      d_index := nvl(d7.id.last, 0) + 1;
      d7.id(d_index) := diary_rec.id;
      d7.time(d_index) := diary_rec.time;
      d7.audsid(d_index) := replace(translate(substr(diary_rec.text, 1, instr(diary_rec.text, ':') - 1), 'ABCDEF', '******'), '*');
      d7.user_id(d_index) := diary_rec.user_id;
      d7.topic(d_index) := diary_rec.topic;
      d7.code(d_index) := null;
      d7.text(d_index) := substr(diary_rec.text, instr(diary_rec.text, ':') + 1);
      if d7.id.count >= p_nrows then
        tmp := utils.table_name(p_owner, utils.DIARY7);
        p_count := p_count + flush_diary_n(d7, tmp);
        append_table(tmp);
      end if;
    end if;
  end loop;
  tmp := utils.table_name(p_owner, utils.DIARY1);
  p_count := p_count + flush_diary_n(d1, tmp);
  append_table(tmp);
  tmp := utils.table_name(p_owner, utils.DIARY2);
  p_count := p_count + flush_diary_n(d2, tmp);
  append_table(tmp);
  tmp := utils.table_name(p_owner, utils.DIARY3);
  p_count := p_count + flush_diary_n(d3, tmp);
  append_table(tmp);
  tmp := utils.table_name(p_owner, utils.DIARY4);
  p_count := p_count + flush_diary_n(d4, tmp);
  append_table(tmp);
  tmp := utils.table_name(p_owner, utils.DIARY5);
  p_count := p_count + flush_diary_n(d5, tmp);
  append_table(tmp);
  tmp := utils.table_name(p_owner, utils.DIARY7);
  p_count := p_count + flush_diary_n(d7, tmp);
  append_table(tmp);
end;
--
procedure imp_diary_param(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  dp_rec ie_file.diary_param_rec_t;
  dp dp_recs_t;
  dp_index pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.DP);
  p_count := 0;
  while ie_file.get(dp_rec) loop
    dp_index := nvl(dp.diary_id.last, 0) + 1;
    dp.diary_id(dp_index) := dp_rec.diary_id;
    dp.qual(dp_index) := dp_rec.qual;
    dp.base_id(dp_index) := null;
    dp.text(dp_index) := dp_rec.text;
    if dp.diary_id.count >= p_nrows then
      p_count := p_count +
        flush_dp(dp, p_table, utils.table_name(p_owner, utils.DIARY2));
    end if;
  end loop;
  p_count := p_count +
    flush_dp(dp, p_table, utils.table_name(p_owner, utils.DIARY2));
end;
--
procedure imp_object_state_history(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  osh_rec ie_file.object_state_history_rec_t;
  osh osh_recs_t;
  osh_index pls_integer;
  pos pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.OSH);
  p_count := 0;
  while ie_file.get(osh_rec) loop
    osh_index := nvl(osh.id.last, 0) + 1;
    osh.id(osh_index) := osh_rec.id;
    osh.time(osh_index) := osh_rec.time;
    osh.obj_id(osh_index) := osh_rec.obj_id;
    osh.class_id(osh_index) := null;
    osh.state_id(osh_index) := osh_rec.state_id;
    pos := instr(osh_rec.user_id,'.',1,2);
    if pos = 0 then
      osh.user_id(osh_index) := osh_rec.user_id;
      osh.audsid(osh_index) := to_number(null);
    else
      osh.user_id(osh_index) := substr(osh_rec.user_id, 1, pos - 1);
      osh.audsid(osh_index) := to_number(substr(osh_rec.user_id, pos + 1));
    end if;
    if osh.id.count >= p_nrows then
      p_count := p_count +
        flush_osh(osh, p_table);
    end if;
  end loop;
  p_count := p_count +
    flush_osh(osh, p_table);
end;
--
procedure imp_values_history(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  valsh_rec ie_file.values_history_rec_t;
  valsh valsh_recs_t;
  valsh_index pls_integer;
  pos pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.VALSH);
  p_count := 0;
  while ie_file.get(valsh_rec) loop
    valsh_index := nvl(valsh.id.last, 0) + 1;
    valsh.id(valsh_index) := valsh_rec.id;
    valsh.time(valsh_index) := valsh_rec.time;
    valsh.obj_id(valsh_index) := valsh_rec.obj_id;
    valsh.class_id(valsh_index) := null;
    pos := instr(valsh_rec.user_id,'.',1,2);
    if pos = 0 then
      valsh.audsid(valsh_index) := to_number(null);
      valsh.user_id(valsh_index) := valsh_rec.user_id;
    else
      valsh.audsid(valsh_index) := to_number(substr(valsh_rec.user_id, pos + 1));
      valsh.user_id(valsh_index) := substr(valsh_rec.user_id, 1, pos - 1);
    end if;
    valsh.qual(valsh_index) := valsh_rec.qual;
    valsh.base_id(valsh_index) := valsh_rec.base_id;
    valsh.value(valsh_index) := valsh_rec.value;
    if valsh.id.count >= p_nrows then
      p_count := p_count +
        flush_valsh(valsh, p_table);
    end if;
  end loop;
  p_count := p_count +
    flush_valsh(valsh, p_table);
end;
--
procedure imp_diary_n(p_owner in varchar2, p_code in pls_integer, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  diary_rec ie_file.diary_n_rec_t;
  d1 diary_n_recs_t;
  d2 diary_n_recs_t;
  d_index pls_integer;
begin
  p_table := utils.table_name(p_owner, p_code);
  p_count := 0;
  while ie_file.get(diary_rec) loop
    if p_code = utils.DIARY1 and diary_rec.topic = 'D' then
      d_index := nvl(d2.id.last, 0) + 1;
      d2.id(d_index) := diary_rec.id;
      d2.time(d_index) := diary_rec.time;
      d2.audsid(d_index) := diary_rec.audsid;
      d2.user_id(d_index) := diary_rec.user_id;
      d2.topic(d_index) := diary_rec.topic;
      d2.code(d_index) := diary_rec.code;
      d2.text(d_index) := diary_rec.text;
      if d2.id.count >= p_nrows then
        p_count := p_count + flush_diary_n(d2, utils.table_name(p_owner, utils.DIARY7));
      end if;
    else
      d_index := nvl(d1.id.last, 0) + 1;
      d1.id(d_index) := diary_rec.id;
      d1.time(d_index) := diary_rec.time;
      d1.audsid(d_index) := diary_rec.audsid;
      d1.user_id(d_index) := diary_rec.user_id;
      d1.topic(d_index) := diary_rec.topic;
      d1.code(d_index) := diary_rec.code;
      d1.text(d_index) := diary_rec.text;
      if d1.id.count >= p_nrows then
        p_count := p_count + flush_diary_n(d1, p_table);
      end if;
    end if;
  end loop;
  p_count := p_count + flush_diary_n(d1, p_table);
  p_count := p_count + flush_diary_n(d2, utils.table_name(p_owner, utils.DIARY7));
end;
--
procedure imp_dp(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  dp_rec ie_file.dp_rec_t;
  dp1 dp_recs_t;
  dp2 dp_recs_t;
  dp_index pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.DP);
  p_count := 0;
  while ie_file.get(dp_rec) loop
    if dp_rec.time is null then
      dp_index := nvl(dp1.diary_id.last, 0) + 1;
      dp1.diary_id(dp_index) := dp_rec.diary_id;
      dp1.qual(dp_index) := dp_rec.qual;
      dp1.base_id(dp_index) := dp_rec.base_id;
      dp1.text(dp_index) := dp_rec.text;
      if dp1.diary_id.count >= p_nrows then
        p_count := p_count +
          flush_dp(dp1, p_table, utils.table_name(p_owner, utils.DIARY2));
      end if;
    else
      dp_index := nvl(dp2.diary_id.last, 0) + 1;
      dp2.diary_id(dp_index) := dp_rec.diary_id;
      dp2.time(dp_index) := dp_rec.time;
      dp2.qual(dp_index) := dp_rec.qual;
      dp2.base_id(dp_index) := dp_rec.base_id;
      dp2.text(dp_index) := dp_rec.text;
      if dp2.diary_id.count >= p_nrows then
        p_count := p_count +
          flush_dp(dp2, p_table);
      end if;
    end if;
  end loop;
  p_count := p_count +
    flush_dp(dp1, p_table, utils.table_name(p_owner, utils.DIARY2));
  p_count := p_count +
    flush_dp(dp2, p_table);
end;
--
procedure imp_och(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  och_rec ie_file.och_rec_t;
  och och_recs_t;
  och_index pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.OCH);
  p_count := 0;
  while ie_file.get(och_rec) loop
    och_index := nvl(och.id.last, 0) + 1;
    och.id(och_index) := och_rec.id;
    och.time(och_index) := och_rec.time;
    och.obj_id(och_index) := och_rec.obj_id;
    och.class_id(och_index) := och_rec.class_id;
    och.collection_id(och_index) := och_rec.collection_id;
    och.obj_parent(och_index) := och_rec.obj_parent;
    och.audsid(och_index) := och_rec.audsid;
    och.user_id(och_index) := och_rec.user_id;
    if och.id.count >= p_nrows then
      p_count := p_count + flush_och(och, p_table);
    end if;
  end loop;
  p_count := p_count + flush_och(och, p_table);
end;
--
procedure imp_osh(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  osh_rec ie_file.osh_rec_t;
  osh osh_recs_t;
  osh_index pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.OSH);
  p_count := 0;
  while ie_file.get(osh_rec) loop
    osh_index := nvl(osh.id.last, 0) + 1;
    osh.id(osh_index) := osh_rec.id;
    osh.time(osh_index) := osh_rec.time;
    osh.obj_id(osh_index) := osh_rec.obj_id;
    osh.class_id(osh_index) := osh_rec.class_id;
    osh.state_id(osh_index) := osh_rec.state_id;
    osh.audsid(osh_index) := osh_rec.audsid;
    osh.user_id(osh_index) := osh_rec.user_id;
    if osh.id.count >= p_nrows then
      p_count := p_count + flush_osh(osh, p_table);
    end if;
  end loop;
  p_count := p_count + flush_osh(osh, p_table);
end;
--
procedure imp_valsh(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  valsh_rec ie_file.valsh_rec_t;
  valsh valsh_recs_t;
  valsh_index pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.VALSH);
  p_count := 0;
  while ie_file.get(valsh_rec) loop
    valsh_index := nvl(valsh.id.last, 0) + 1;
    valsh.id(valsh_index) := valsh_rec.id;
    valsh.time(valsh_index) := valsh_rec.time;
    valsh.obj_id(valsh_index) := valsh_rec.obj_id;
    valsh.class_id(valsh_index) := valsh_rec.class_id;
    valsh.audsid(valsh_index) := valsh_rec.audsid;
    valsh.user_id(valsh_index) := valsh_rec.user_id;
    valsh.qual(valsh_index) := valsh_rec.qual;
    valsh.base_id(valsh_index) := valsh_rec.base_id;
    valsh.value(valsh_index) := valsh_rec.value;
    if valsh.id.count >= p_nrows then
      p_count := p_count + flush_valsh(valsh, p_table);
    end if;
  end loop;
  p_count := p_count + flush_valsh(valsh, p_table);
end;
--
procedure imp_edh(p_owner in varchar2, p_nrows in pls_integer,
    p_table in out nocopy varchar2, p_count in out nocopy pls_integer) is
  edh_rec ie_file.edh_rec_t;
  edh edh_recs_t;
  edh_index pls_integer;
begin
  p_table := utils.table_name(p_owner, utils.EDH);
  p_count := 0;
  while ie_file.get(edh_rec) loop
    edh_index := nvl(edh.id.last, 0) + 1;
    edh.id(edh_index) := edh_rec.id;
    edh.time(edh_index) := edh_rec.time;
    edh.obj_id(edh_index) := edh_rec.obj_id;
    edh.class_id(edh_index) := edh_rec.class_id;
    edh.audsid(edh_index) := edh_rec.audsid;
    edh.user_id(edh_index) := edh_rec.user_id;
    edh.type_id(edh_index) := edh_rec.type_id;
    edh.code(edh_index) := edh_rec.code;
    edh.text(edh_index) := edh_rec.text;
    if edh.id.count >= p_nrows then
      p_count := p_count + flush_edh(edh, p_table);
    end if;
  end loop;
  p_count := p_count + flush_edh(edh, p_table);
end;
--
procedure exp(p_owner varchar2, p_code pls_integer, p_date date, p_make_date_safe boolean) is
  v_date date := p_date;
begin
  if not chk_exp_date(p_owner,p_code,v_date,p_make_date_safe,true) then
    return;
  end if;
  if p_code = utils.OCH then
    exp_och(p_owner, v_date);
  elsif p_code = utils.OSH then
    exp_osh(p_owner, v_date);
  elsif p_code = utils.VALSH then
    exp_valsh(p_owner, v_date);
  elsif p_code = utils.EDH then
    exp_edh(p_owner, v_date);
  elsif p_code = utils.DP then
    exp_dp(p_owner, v_date);
  else
    if 1 <= p_code and p_code <= 7 then
      exp_diary_n(p_owner, p_code, v_date);
    end if;
  end if;
end;
--
procedure clr(p_owner varchar2, p_code pls_integer, p_date date, p_result out nocopy varchar2) is
  v_table varchar2(30);
  v_ok varchar2(3000);
  v_faild varchar2(3000);
  v_rows  number;
  n pls_integer;
  d date;
begin
  p_result := null;
  d := date_to(p_owner, p_code, p_date, true);
  if d > trunc(sysdate) - clear.max_interval then
    if utils.AudPartitions then
      begin
        utils.truncate_partitions(p_owner, p_code, d, v_table, v_ok, v_faild);
        if not v_ok is null then
          p_result := utils.get_msg('TRUNCATED_PARTS',v_ok,v_table,to_char(d,'(DD/MM/YYYY)'));
        end if;
        if not v_faild is null then
          p_result := p_result || utils.get_msg('TRUNCATING_ERRORS',v_faild,v_table);
        end if;
      exception when others then
        p_result := sqlerrm;
        rollback;
      end;
    else
      v_table := utils.table_name(p_owner,p_code,true);
      v_rows := nvl(utils.get_interval(p_owner,'ROWS'),100000);
      utils.delete_data(v_table,d,v_rows,n,v_faild);
      if n>0 then
        p_result := utils.get_msg('RECORDS_WERE_REMOVED',n,v_table,to_char(d,'(DD/MM/YYYY)'));
      end if;
      if not v_faild is null then
        p_result := p_result || v_faild ;
      end if;
    end if;
  end if;
end;
--
end;
/
show err package body ie_db61

