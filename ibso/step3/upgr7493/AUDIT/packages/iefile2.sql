prompt ie_file body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iefile2.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */
ie_file is
DL constant varchar2(1) := '|';
LF constant varchar2(1) := chr(10);
CR constant varchar2(1) := chr(13);

file_path varchar2(100);
file_name varchar2(50);
owner varchar2(50);
table_name varchar(50);
action_date date;
total_lines_count pls_integer;
lines_count pls_integer;

file_handle utl_file.file_type;

str varchar2(32767);
field varchar2(8000);
prev_field_pos pls_integer;
cur_field_pos pls_integer;

db_encoding varchar2(40);
file_encoding varchar2(40);
encoding_set boolean;
need_convert boolean;

do_get boolean := true;

/*
function quote(str varchar2) return varchar2 is
begin
  return replace(replace(replace(str, chr(13), '\r'), chr(10), '\n'), DL, '\/');
end;
*/

function quote_date(field varchar2) return varchar2 is
begin
  return 'to_char(' || field || ', ''' || clear.DATE_FORMAT || ''')';
end;

function quote_timestamp(field varchar2) return varchar2 is
begin
  return 'to_char(' || field || ', ''' || clear.TIMESTAMP_FORMAT || ''')';
end;

function quote_text(field varchar2) return varchar2 is
begin
  return 'replace(replace(replace(replace(' || field || ',''\'',''\\''), chr(13), ''\r''), chr(10), ''\n''), ''' || DL || ''', ''\/'')';
end;

/*
function dequote(str varchar2) return varchar2 is
begin
  if str is null then
    return str;
  end if;
  if need_convert then
    return convert(replace(replace(replace(str,'\/','|'),'\n',LF), '\r', CR), db_encoding, file_encoding);
  else
    return replace(replace(replace(str,'\/','|'),'\n',LF), '\r', CR);
  end if;
end;
*/

function dequote_date(place_holder varchar2) return varchar2 is
begin
  return 'to_date(' || place_holder || ', ''' || clear.DATE_FORMAT || ''')';
end;

function dequote_timestamp(place_holder varchar2) return varchar2 is
begin
  return '&&D_TO_TIMESTAMP(' || place_holder || ', ''' || clear.TIMESTAMP_FORMAT || ''')';
end;

function dequote_text(place_holder varchar2) return varchar2 is
begin
  if need_convert then
    return 'convert(replace(replace(replace(replace(replace(' || place_holder || ',''\\'', chr(0)||chr(0)),''\/'',''|''),''\n'', chr(10)), ''\r'', chr(13)),chr(0)||chr(0),''\''), ''' || ie_file.db_encoding ||''', ''' ||ie_file.file_encoding||''')';
  else
    return 'replace(replace(replace(replace(replace(' || place_holder || ',''\\'', chr(0)||chr(0)),''\/'',''|''),''\n'', chr(10)), ''\r'', chr(13)),chr(0)||chr(0),''\'')';
  end if;
end;

function convert_text(place_holder varchar2) return varchar2 is
begin
  if need_convert then
    return 'convert(' || place_holder || ', ''' || ie_file.db_encoding ||''', ''' ||ie_file.file_encoding||''')';
  else
    return place_holder;
  end if;
end;


procedure start_exp(p_file_path varchar2, p_file_name varchar2, p_append boolean default false) is
begin
  file_path := p_file_path;
  file_name := p_file_name;
  if p_append then
    file_handle := utl_file.fopen(file_path, file_name, 'a', 32767);
  else
    file_handle := utl_file.fopen(file_path, file_name, 'w', 32767);
  end if;
  encoding_set := false;
  total_lines_count := 0;
  lines_count := 0;
exception
  when utl_file.INVALID_PATH then
    utils.error('INVALID_PATH', file_path, file_name);
  when utl_file.INVALID_MODE then
    utils.error('CANT_OPEN_TO_WRITE', file_path, file_name);
  when utl_file.INVALID_OPERATION then
    utils.error('INVALID_OPERATION', file_path, file_name);
end;

procedure start_table_exp(p_owner in varchar2, p_table_name in varchar2, p_date in date) is
begin
  owner := p_owner;
  table_name := p_table_name;
  action_date := p_date;
  lines_count := 0;
end;

procedure put_line(str in varchar) is
begin
  if lines_count = 0 then
    if not encoding_set then
      utl_file.put_line(file_handle, 'ENC ' || db_encoding);
      encoding_set := true;
      total_lines_count := total_lines_count + 1;
    end if;
    utl_file.put_line(file_handle, 'BOD ' || table_name || ': (' || to_char(action_date, clear.DATE_FORMAT) || ') ' || owner);
    total_lines_count := total_lines_count + 1;
  end if;
  utl_file.put_line(file_handle, str);
  lines_count := lines_count + 1;
  total_lines_count := total_lines_count + 1;
exception
  when utl_file.INVALID_OPERATION then
    utils.error('INVALID_OPERATION', file_path, file_name);
  when utl_file.WRITE_ERROR then
    utils.error('WRITE_ERROR', file_path, file_name);
end;

procedure put(diary_rec in out nocopy diary_rec_t) is
begin
  put_line(
    diary_rec.id || DL ||
--    to_char(diary_rec.time, clear.DATE_FORMAT) || DL ||
    diary_rec.time || DL ||
--    quote(diary_rec.user_id) || DL ||
    diary_rec.user_id || DL ||
    diary_rec.topic || DL ||
--    quote(diary_rec.text)
    diary_rec.text
  );
end;

procedure put(dp_rec in out nocopy diary_param_rec_t) is
begin
  put_line(
    dp_rec.diary_id || DL ||
    dp_rec.qual || DL ||
--    quote(dp_rec.text)
    dp_rec.text
  );
end;

procedure put(osh_rec in out nocopy object_state_history_rec_t) is
begin
  put_line(
    osh_rec.id || DL ||
--    to_char(osh_rec.time, clear.DATE_FORMAT) || DL ||
    osh_rec.time || DL ||
--    quote(osh_rec.user_id) || DL ||
    osh_rec.user_id || DL ||
    osh_rec.obj_id || DL ||
    osh_rec.state_id
  );
end;

procedure put(valsh_rec in out nocopy values_history_rec_t) is
begin
  put_line(
    valsh_rec.id || DL ||
--    to_char(valsh_rec.time, clear.DATE_FORMAT) || DL ||
    valsh_rec.time || DL ||
--    quote(valsh_rec.user_id) || DL ||
    valsh_rec.user_id || DL ||
    valsh_rec.obj_id || DL ||
    valsh_rec.qual || DL ||
    valsh_rec.base_id || DL ||
--    quote(valsh_rec.value)
    valsh_rec.value
  );
end;

procedure put(diary_n_rec in out nocopy diary_n_rec_t) is
begin
  put_line(
    diary_n_rec.id || DL ||
--    to_char(diary_n_rec.time, clear.DATE_FORMAT) || DL ||
    diary_n_rec.time || DL ||
--    quote(diary_n_rec.user_id) || DL ||
    diary_n_rec.user_id || DL ||
    diary_n_rec.topic || DL ||
--    quote(diary_n_rec.text) || DL ||
    diary_n_rec.text || DL ||
    diary_n_rec.code || DL ||
    diary_n_rec.audsid
  );
end;

procedure put(dp_rec in out nocopy dp_rec_t) is
begin
  put_line(
    dp_rec.diary_id || DL ||
    dp_rec.qual || DL ||
--    quote(dp_rec.text) || DL ||
    dp_rec.text || DL ||
--    to_char(dp_rec.time, clear.DATE_FORMAT) || DL ||
    dp_rec.time || DL ||
    dp_rec.base_id
  );
end;

procedure put(och_rec in out nocopy och_rec_t) is
begin
  put_line(
    och_rec.id || DL ||
--    to_char(och_rec.time, clear.DATE_FORMAT) || DL ||
    och_rec.time || DL ||
--    quote(och_rec.user_id) || DL ||
    och_rec.user_id || DL ||
    och_rec.obj_id || DL ||
    och_rec.collection_id || DL ||
    och_rec.audsid || DL ||
    och_rec.class_id || DL ||
--    quote(och_rec.obj_parent)
    och_rec.obj_parent
  );
end;

procedure put(osh_rec in out nocopy osh_rec_t) is
begin
  put_line(
    osh_rec.id || DL ||
--    to_char(osh_rec.time, clear.DATE_FORMAT) || DL ||
    osh_rec.time || DL ||
--    quote(osh_rec.user_id) || DL ||
    osh_rec.user_id || DL ||
    osh_rec.obj_id || DL ||
    osh_rec.state_id || DL ||
    osh_rec.audsid || DL ||
    osh_rec.class_id
  );
end;

procedure put(valsh_rec in out nocopy valsh_rec_t) is
begin
  put_line(
    valsh_rec.id || DL ||
--    to_char(valsh_rec.time,clear.DATE_FORMAT) || DL ||
    valsh_rec.time || DL ||
--    quote(valsh_rec.user_id) || DL ||
    valsh_rec.user_id || DL ||
    valsh_rec.obj_id || DL ||
    valsh_rec.qual || DL ||
    valsh_rec.base_id || DL ||
--    quote(valsh_rec.value) || DL ||
    valsh_rec.value || DL ||
    valsh_rec.audsid || DL ||
    valsh_rec.class_id
  );
end;

procedure put(edh_rec in out nocopy edh_rec_t) is
begin
  put_line(
    edh_rec.id || DL ||
    edh_rec.time || DL ||
    edh_rec.audsid || DL ||
    edh_rec.user_id || DL ||
    edh_rec.class_id || DL ||
    edh_rec.obj_id || DL ||
    edh_rec.type_id || DL ||
    edh_rec.code || DL ||
    edh_rec.text
  );
end;

procedure finish_table_exp is
begin
  if lines_count > 0 then
    utl_file.put_line(file_handle, 'EOD ' || table_name || ': ' || lines_count);
    total_lines_count := total_lines_count + 1;
  end if;
exception
  when utl_file.INVALID_OPERATION then
    utils.error('INVALID_OPERATION', file_path, file_name);
  when utl_file.WRITE_ERROR then
    utils.error('WRITE_ERROR', file_path, file_name);
end;

procedure finish_exp is
begin
  if utl_file.is_open(file_handle) then
    utl_file.fclose(file_handle);
  end if;
exception
  when utl_file.WRITE_ERROR then
    utils.error('WRITE_ERROR', file_path, file_name);
end;

procedure start_imp(p_file_path varchar2, p_file_name varchar2) is
begin
  file_path := p_file_path;
  file_name := p_file_name;
  file_handle:= utl_file.fopen(file_path, file_name, 'r', 32767);
  file_encoding := db_encoding;
  need_convert := false;
  total_lines_count := 0;
  lines_count := 0;
exception
  when utl_file.INVALID_PATH then
    utils.error('INVALID_PATH', file_path, file_name);
  when utl_file.INVALID_MODE then
    utils.error('CANT_OPEN_TO_READ', file_path, file_name);
  when utl_file.INVALID_OPERATION then
    utils.error('INVALID_OPERATION', file_path, file_name);
end;

function get_record return boolean is
begin
  begin
    if do_get then
      utl_file.get_line(file_handle, str);
      total_lines_count := total_lines_count + 1;
    end if;
  exception when no_data_found then
    return false;
  end;

  if substr(str, 1, 4) = 'EOD ' then
    return false;
  end if;

  if substr(str, 1, 4) = 'BOD ' or substr(str, 1, 4) = 'ENC ' then
    do_get := false;
    return false;
  end if;

  lines_count := lines_count + 1;
  prev_field_pos :=  null;
  cur_field_pos := 1;
  str := rtrim(str, CR);
  return true;
end;

procedure get_field is
  i pls_integer;
begin
  i := instr(str, DL, cur_field_pos);
  if i>0 then
      field := substr(str, cur_field_pos, i - cur_field_pos);
      prev_field_pos := cur_field_pos;
      cur_field_pos := i + 1;
  else
      field := substr(str, cur_field_pos);
      prev_field_pos := cur_field_pos;
      cur_field_pos := 1;
      str := null;
  end if;
end;

function get_next_table(p_code out pls_integer, p_owner out varchar2, p_date out date) return boolean is
  t varchar2(100);
  i pls_integer;
begin
  loop
    begin
      if do_get then
        utl_file.get_line(file_handle, str);
        total_lines_count := total_lines_count + 1;
      else
        do_get := true;
      end if;
    exception when no_data_found then
      return false;
    end;

    str := rtrim(str, CR);
    if substr(str, 1, 4) = 'ENC ' then
      file_encoding := substr(str, 5);
      need_convert := file_encoding <> db_encoding;
    elsif substr(str, 1, 4) = 'BOD ' then
      p_owner := substr(str, instr(str, ' ', -1) + 1);

      i := instr(str,'(');
      if i>0 then
        field := substr(str, i + 1, instr(str, ')') - i - 1);
        p_date := to_date(field, clear.DATE_FORMAT);
      end if;

      t := substr(str, 5, instr(str,':') - 5);
      i := instr(t, ' ');
      if i > 0 then
        t := substr(t, 1, i - 1);
      end if;

      if t = 'DIARY' then
        table_name := t;
        lines_count := 0;
        p_code := 0;
        return true;
      elsif t = 'DIARY_PARAM' then
        table_name := t;
        lines_count := 0;
        p_code := 10;
        return true;
      elsif t = 'VALUES_HISTORY' then
        table_name := t;
        lines_count := 0;
        p_code := 11;
        return true;
      elsif t = 'OBJECT_STATE_HISTORY' then
        table_name := t;
        lines_count := 0;
        p_code := 12;
        return true;
      elsif t = p_owner || '_DP' then
        table_name := t;
        lines_count := 0;
        p_code := utils.DP;
        return true;
      elsif t = p_owner || '_VALSH' then
        table_name := t;
        lines_count := 0;
        p_code := utils.VALSH;
        return true;
      elsif t = p_owner || '_OSH' then
        table_name := t;
        lines_count := 0;
        p_code := utils.OSH;
        return true;
      elsif t = p_owner || '_OCH' then
        table_name := t;
        lines_count := 0;
        p_code := utils.OCH;
        return true;
      elsif t = p_owner || '_EDH' then
        table_name := t;
        lines_count := 0;
        p_code := utils.EDH;
        return true;
      elsif t like p_owner || '\_DIARY_' escape '\' then
        table_name := t;
        lines_count := 0;
        p_code := substr(t, length(t), 1);
        return true;
      end if;
    end if;
  end loop;
end;

function get(diary_rec in out nocopy diary_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  diary_rec.id := to_number(field);
  get_field;
--  diary_rec.time := to_date(field, clear.DATE_FORMAT);
  diary_rec.time := field;
  get_field;
--  diary_rec.user_id := dequote(field);
  diary_rec.user_id := field;
  get_field;
  diary_rec.topic := field;
  get_field;
--  diary_rec.text := dequote(field);
  diary_rec.text := field;

  return true;
end;

function get(dp_rec in out nocopy diary_param_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  dp_rec.diary_id := to_number(field);
  get_field;
  dp_rec.qual:=field;
  get_field;
--  dp_rec.text:= dequote(field);
  dp_rec.text:= field;

  return true;
end;

function get(osh_rec in out nocopy object_state_history_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  osh_rec.id := to_number(field);
  get_field;
--  osh_rec.time := to_date(field, clear.DATE_FORMAT);
  osh_rec.time := field;
  get_field;
--  osh_rec.user_id := dequote(field);
  osh_rec.user_id := field;
  get_field;
  osh_rec.obj_id := field;
  get_field;
  osh_rec.state_id := field;

  return true;
end;

function get(valsh_rec in out nocopy values_history_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  valsh_rec.id := to_number(field);
  get_field;
--  valsh_rec.time := to_date(field, clear.DATE_FORMAT);
  valsh_rec.time := field;
  get_field;
--  valsh_rec.user_id := dequote(field);
  valsh_rec.user_id := field;
  get_field;
  valsh_rec.obj_id := field;
  get_field;
  valsh_rec.qual := field;
  get_field;
  valsh_rec.base_id := field;
  get_field;
--  valsh_rec.value := dequote(field);
  valsh_rec.value := field;

  return true;
end;

function get(diary_n_rec in out nocopy diary_n_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  diary_n_rec.id := to_number(field);
  get_field;
--  diary_n_rec.time := &&D_TO_TIMESTAMP(field, clear.TIMESTAMP_FORMAT);
  diary_n_rec.time := field;
  get_field;
--  diary_n_rec.user_id := dequote(field);
  diary_n_rec.user_id := field;
  get_field;
  diary_n_rec.topic := field;
  get_field;
--  diary_n_rec.text := dequote(field);
  diary_n_rec.text := field;
  get_field;
  diary_n_rec.code := field;
  get_field;
  diary_n_rec.audsid := field;

  return true;
end;

function get(dp_rec in out nocopy dp_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  dp_rec.diary_id := to_number(field);
  get_field;
  dp_rec.qual := field;
  get_field;
--  dp_rec.text := dequote(field);
  dp_rec.text := field;
  get_field;
--  dp_rec.time := &&D_TO_TIMESTAMP(field, clear.TIMESTAMP_FORMAT);
  dp_rec.time := field;
  get_field;
  dp_rec.base_id := field;

  return true;
end;

function get(och_rec in out nocopy och_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  och_rec.id := to_number(field);
  get_field;
--  och_rec.time := &&D_TO_TIMESTAMP(field, clear.TIMESTAMP_FORMAT);
  och_rec.time := field;
  get_field;
--  och_rec.user_id := dequote(field);
  och_rec.user_id := field;
  get_field;
  och_rec.obj_id := field;
  get_field;
  och_rec.collection_id := to_number(field);
  get_field;
  och_rec.audsid := to_number(field);
  get_field;
  och_rec.class_id := field;
  get_field;
--  och_rec.obj_parent := dequote(field);
  och_rec.obj_parent := field;

  return true;
end;

function get(osh_rec in out nocopy osh_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  osh_rec.id := to_number(field);
  get_field;
--  osh_rec.time := &&D_TO_TIMESTAMP(field, clear.TIMESTAMP_FORMAT);
  osh_rec.time := field;
  get_field;
--  osh_rec.user_id := dequote(field);
  osh_rec.user_id := field;
  get_field;
  osh_rec.obj_id := field;
  get_field;
  osh_rec.state_id := field;
  get_field;
  osh_rec.audsid := to_number(field);
  get_field;
  osh_rec.class_id := field;

  return true;
end;

function get(valsh_rec in out nocopy valsh_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  valsh_rec.id := to_number(field);
  get_field;
--  valsh_rec.time := &&D_TO_TIMESTAMP(field, clear.TIMESTAMP_FORMAT);
  valsh_rec.time := field;
  get_field;
--  valsh_rec.user_id := dequote(field);
  valsh_rec.user_id := field;
  get_field;
  valsh_rec.obj_id := field;
  get_field;
  valsh_rec.qual := field;
  get_field;
  valsh_rec.base_id := field;
  get_field;
--  valsh_rec.value := dequote(field);
  valsh_rec.value := field;
  get_field;
  valsh_rec.audsid := to_number(field);
  get_field;
  valsh_rec.class_id := field;

  return true;
end;

function get(edh_rec in out nocopy edh_rec_t) return boolean is
begin
  if not get_record then
    return false;
  end if;

  get_field;
  edh_rec.id := to_number(field);
  get_field;
  edh_rec.time := field;
  get_field;
  edh_rec.audsid := to_number(field);
  get_field;
  edh_rec.user_id := field;
  get_field;
  edh_rec.class_id := field;
  get_field;
  edh_rec.obj_id := field;
  get_field;
  edh_rec.type_id := field;
  get_field;
  edh_rec.code := field;
  get_field;
  edh_rec.text := field;

  return true;
end;

procedure finish_imp is
begin
  if utl_file.is_open(file_handle) then
    utl_file.fclose(file_handle);
  end if;
exception
  when utl_file.WRITE_ERROR then
    utils.error('WRITE_ERROR', file_path, file_name);
end;

function get_table_name return varchar2 is
begin
  return table_name;
end;

function get_lines_count return pls_integer is
begin
  return lines_count;
end;

function get_total_lines_count return pls_integer is
begin
  return total_lines_count;
end;

function get_field_pos return pls_integer is
begin
  return prev_field_pos;
end;

procedure cleanup_table_inf is
begin
    owner := null;
    table_name := null;
    action_date := null;
    lines_count := 0;
end;

begin
  need_convert := false;
  select value into db_encoding from nls_database_parameters where parameter = 'NLS_CHARACTERSET';
end;
/
show err package body ie_file

