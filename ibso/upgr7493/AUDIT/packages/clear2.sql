prompt clear body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/clear2.sql $
 *  $Author: khaliljullova $
 *  $Revision: 76622 $
 *  $Date:: 2015-07-16 10:47:19 #$
 */
clear is
--
NO_LIMIT     constant varchar2(10):= 'UNLIMITED';
LF           constant varchar2(1) := chr(10);
-----------------------------------------------------
-- Работа с версией
BUILD_NO constant pls_integer := 9;
REVISION_NO constant pls_integer := 3;
--
use_tz  boolean := true;
--
function build return pls_integer is
begin
  return BUILD_NO;
end;
--
function revision return pls_integer is
begin
  return REVISION_NO;
end;
--
function full_version return varchar2 is
begin
  return VERSION||'.'||BUILD_NO||'.'||REVISION_NO;
end;
-----------------------------------------------------
function IsOwnerAccessible(p_owner varchar2) return boolean is
    v_owner varchar2(30);
begin
    if USER = utils.AudOwner then
        return true;
    end if;
    v_owner := upper(p_owner);
    if v_owner = sys_context(v_owner || '_SYSTEM', 'OWNER') then
      return true;
    end if;
    for c in (
      select '1' from owners
       where owner=v_owner and schema_owner = sys_context(schema_owner|| '_SYSTEM', 'OWNER')
    ) loop
      return true;
    end loop;
    return false;
end;
-----------------------------------------------------
function AudPartitions return boolean is
begin
  return utils.AudPartitions;
end;
-----------------------------------------------------
procedure open_ses(p_owner varchar2) is
begin
  if p_owner is null or IsOwnerAccessible(p_owner) then
    utils.open_ses(p_owner);
  end if;
end;
--
procedure close_ses(p_owner varchar2) is
begin
  if p_owner is null or IsOwnerAccessible(p_owner) then
    utils.close_ses(p_owner);
  end if;
end;
--
procedure write_log(p_owner varchar2, p_topic varchar2, p_code varchar2, p_text varchar2) is
  pragma autonomous_transaction;
begin
  if p_owner is null or IsOwnerAccessible(p_owner) then
    utils.write_log(p_owner,p_topic,p_code,p_text);
  end if;
  commit;
end;
--
function get_buf return varchar2 is
begin
  return utils.get_buf;
end;
--
function check_role(p_user varchar2, p_role varchar2) return boolean is
begin
  return utils.check_role(p_user,p_role);
end;
-----------------------------------------------------
-- Работа с правами
function procs_and_grants(p_owner varchar2 default null) return varchar2 is
begin
    if not IsOwnerAccessible(p_owner) then
        return null;
    end if;
    utils.create_procedures;
    utils.grants(p_owner);
    return utils.get_buf();
end;
--
procedure create_user(p_user varchar2, p_name varchar2) is
begin
  utils.create_user(p_user,p_name);
end;
--
procedure edit_user(p_user varchar2, p_name varchar2) is
begin
  utils.edit_user(p_user,p_name);
end;
--
procedure user_grants(p_user varchar2 default null) is
begin
  utils.user_grants(p_user);
end;
--
procedure delete_user(p_user varchar2) is
begin
  utils.user_grants(p_user);
end;
--
procedure del_owner(p_owner varchar2,p_only_grants boolean default true,p_data boolean default false) is
begin
  if not IsOwnerAccessible(p_owner) then
    utils.error('USER_NOT_ACCESSIBLE',p_owner);
  end if;
  utils.del_owner(p_owner,p_only_grants,p_data);
end;
-----------------------------------------------------
-- Работа с настройками
function get_value(p_owner varchar2, p_name varchar2) return varchar2 is
begin
    if not IsOwnerAccessible(p_owner) then
        return null;
    end if;
    return utils.get_value(p_owner,p_name);
end;
--
procedure set_value(p_owner varchar2, p_name varchar2, p_value varchar2,
    p_description varchar2 default null) is
begin
  if not IsOwnerAccessible(p_owner) then
      return;
  end if;
  utils.set_value(p_owner,p_name,p_value,p_description);
end;
--
function get_interval(p_owner varchar2, p_name varchar2) return number is
    s   varchar2(2000);
    n   number;
begin
    if not IsOwnerAccessible(p_owner) then
        return null;
    end if;
    s := utils.get_value(p_owner,p_name);
    if s=no_limit or s='0' then return max_interval; end if;
    n := to_number(s);
    if n<0 then n:=null; end if;
    return n;
exception when others then
    return null;
end;
--
procedure set_interval(p_owner varchar2, p_name varchar2, p_interval number) is
begin
  if not IsOwnerAccessible(p_owner) then
      return;
  end if;
  if p_interval<=0 or p_interval>=max_interval then
    utils.set_value(p_owner,p_name,no_limit);
  elsif p_interval>min_interval then
    utils.set_value(p_owner,p_name,to_char(p_interval));
  else
    utils.set_value(p_owner,p_name,to_char(min_interval));
  end if;
end;
-----------------------------------------------------
-- Работа с email
procedure set_notification(p_owner   varchar2, p_event   varchar2,
                           p_subject varchar2, p_message varchar2,
                           p_sender  varchar2, p_sender_name varchar2,
                           p_description varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
    return;
  end if;
  mail_mgr.set_notification(p_owner,p_event,p_subject,p_message,p_sender,p_sender_name,p_description);
end;
--
procedure set_notification_status(p_owner varchar2, p_event varchar2, p_status varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
    return;
  end if;
  mail_mgr.set_notification_status(p_owner,p_event,p_status);
end;
--
procedure set_recipient(p_owner varchar2, p_event varchar2,
                        p_email varchar2, p_name  varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
    return;
  end if;
  mail_mgr.set_recipient(p_owner,p_event,p_email,p_name);
end;
--
procedure set_recipient_status(p_owner varchar2, p_event  varchar2,
                               p_email varchar2, p_status varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
    return;
  end if;
  mail_mgr.set_recipient_status(p_owner,p_event,p_email,p_status);
end;
--
procedure set_message (p_topic varchar2, p_code  varchar2, p_text varchar2) is
  s varchar2(10);
begin
  if p_topic in ('SUBJ','BODY') and p_text is not null then
    if utils.set_message(p_topic,p_code,p_text) then
      s := 'CREATE';
    else
      s := 'SET';
    end if;
    utils.write_log(null,'G',s,'AUDIT_MESSAGES-'||p_topic||'-'||p_code||','||p_text);
  end if;
end;
-----------------------------------------------------
-- Работа с разделами (партификация)
function get_diary_step(p_owner varchar2, p_code pls_integer) return varchar2 is
begin
  if not IsOwnerAccessible(p_owner) then
      return null;
  end if;
  return utils.get_diary_step(p_owner, p_code);
end;
--
procedure get_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace out nocopy varchar2, p_idx_tablespace out nocopy varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
      return;
  end if;
  utils.get_tablespaces(p_owner, p_code, p_step, p_tablespace, p_idx_tablespace);
end;
--
procedure set_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace in varchar2, p_idx_tablespace in varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
      return;
  end if;
  utils.set_tablespaces(p_owner, p_code, p_step, p_tablespace, p_idx_tablespace);
end;
--
function get_end_date(owner varchar2, p_code pls_integer) return date is
begin
  if not IsOwnerAccessible(owner) then
      return null;
  end if;
  return utils.get_end_date(owner, p_code);
end;
--
procedure get_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent out nocopy varchar2, p_next_extent out nocopy varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
      return;
  end if;
  utils.get_extents(p_owner, p_code, p_idx, p_initial_extent, p_next_extent);
end;
--
procedure set_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent varchar2, p_next_extent varchar2) is
begin
  if not IsOwnerAccessible(p_owner) then
      return;
  end if;
  utils.set_extents(p_owner, p_code, p_idx, p_initial_extent, p_next_extent);
end;
--
procedure add_partitions(owner varchar2, p_code pls_integer, end_date date) is
  v_table varchar2(100);
  v_ok    varchar2(4000);
begin
  if not (IsOwnerAccessible(owner) and utils.AudPartitions) then
      return;
  end if;
  utils.add_partitions(owner, p_code, end_date, v_table, v_ok);
  if not v_ok is null then
    v_ok := utils.get_msg('CREATED_PARTS',v_ok,v_table,to_char(end_date,'(DD/MM/YYYY)'));
    write_log(owner,'U','AUDIT',v_ok);
    utils.put_line(v_ok);
  end if;
   exception 
    when others then
      v_ok := utils.get_msg('INVALID_ADD_PARTS',v_table,to_char(end_date,'(DD/MM/YYYY)'),substr(utils.get_error_stack,1,3800));
      write_log(owner,'U','AUDIT',v_ok);
      utils.put_line(v_ok); 
      raise;
end;
--
procedure drop_partitions(owner varchar2, p_code pls_integer, p_date date) is
  v_table varchar2(100);
  v_ok    varchar2(4000);
  v_faild varchar2(4000);
  d date;
begin
  if not (IsOwnerAccessible(owner) and utils.AudPartitions) then
      return;
  end if;
  d := ie_db61.date_to(owner,p_code,p_date);
  utils.drop_partitions(owner, p_code, d, v_table, v_ok, v_faild);
  if not v_ok is null then
    v_ok := utils.get_msg('DROPPED_PARTS',v_ok,v_table,to_char(d,'(DD/MM/YYYY)'));
    write_log(owner,'U','AUDIT',v_ok);
    utils.put_line(v_ok);
  end if;
  if not v_faild is null then
    v_faild := utils.get_msg('DROPPING_ERRORS',v_faild,v_table);
    write_log(owner,'U','AUDIT',v_faild);
    utils.put_line(v_faild);
  end if;
end;
-----------------------------------------------------
-- Максимальная дата для экспорта/очистки
function date_to(p_owner varchar2, p_code pls_integer, p_date date default null) return date is
begin
  if not IsOwnerAccessible(p_owner) then
      return null;
  end if;
  return ie_db61.date_to(p_owner,p_code,p_date,nvl(utils.get_interval(p_owner,'VERSION'),3.4)>=6.1);
end date_to;
-----------------------------------------------------
-- Проверка существования файла
function check_file ( location  in varchar2, filename  in varchar2 ) return integer is
  fd  utl_file.file_type;
begin
  fd := utl_file.fopen( location, filename, 'r' );
  utl_file.fclose( fd );
  return 0;
exception
  when utl_file.INVALID_PATH then
    return 1;
  when utl_file.INVALID_MODE then
    return 2;
  when utl_file.INVALID_OPERATION then
    return 3;
end;
-----------------------------------------------------
-- Очистка журнала(ов)
function diary(p_owner varchar2, p_code pls_integer default null, p_date date default null) return varchar2 is
  n number;
  d date;
  v54 boolean;
  v61  boolean;
  v63  boolean;
  nrows number;
  s varchar2(4000);
  v_table varchar2(100);
  v_count pls_integer;
  v_error varchar2(4000);
  v_code pls_integer := nvl(p_code, utils.DP);
begin
  if not IsOwnerAccessible(p_owner) then
      return null;
  end if;
  n := nvl(utils.get_interval(p_owner,'VERSION'),3.4);
  v54 := n>=5.4;
  v61 := n>=6.1;
  v63 := n>=6.3;
  nrows := nvl(utils.get_interval(p_owner,'ROWS'),100000);
  d := ie_db61.date_to(p_owner,v_code,p_date,v61);
  utils.set_interval(p_owner,'ROWS',nrows); commit;
  if v_code = utils.EDH then
    if v63 then
      ie_db61.clr(p_owner, v_code, d, v_error);
    end if;
  elsif v_code = utils.OCH then
    if v61 then
      ie_db61.clr(p_owner, v_code, d, v_error);
    elsif v54 then
      ie_db54.clr(p_owner, v_code, d, nrows, v_table, v_count, v_error);
    end if;
  else
    if v61 then
      ie_db61.clr(p_owner, v_code, d, v_error);
    elsif v54 then
      ie_db54.clr(p_owner, v_code, d, nrows, v_table, v_count, v_error);
    else
      ie_db34.clr(p_owner, v_code, d, nrows, v_table, v_count, v_error);
    end if;
  end if;
  if not v_table is null and v_count>0 then
    s := utils.get_msg('RECORDS_WERE_REMOVED',v_count,v_table,to_char(d,'(DD/MM/YYYY)'));
  end if;
  if not v_error is null then
    s := s || v_error || LF;
  end if;
  if not s is null then
    utils.write_log(p_owner,'U','AUDIT',s);
    commit;
  end if;
  return s;
end;
--
function diarys(p_owner varchar2, p_diary boolean default TRUE, p_osh boolean default TRUE,
                p_vals  boolean default TRUE, p_date date default null, p_och boolean default TRUE) return varchar2 is
    s varchar2(4000);
begin
    if not IsOwnerAccessible(p_owner) then
        return null;
    end if;
    if p_diary then
        s := diary(p_owner,0,p_date);
    end if;
    if p_vals then
        s := s||diary(p_owner,-1,p_date);
    end if;
    if p_osh then
        s := s||diary(p_owner,-2,p_date);
    end if;
    if p_och then
        s := s||diary(p_owner,-3,p_date);
    end if;
    return s;
end;
-----------------------------------------------------
-- Экспорт журнала(ов)
function exp(p_owner varchar2, p_FilePath varchar2 default null,
             p_FileName varchar2 default null, p_append boolean default FALSE,
             p_code pls_integer default null, p_date date default null,
             p_make_date_safe boolean default true,
             p_debug boolean default false) return varchar2 is
  n number;
  d date;
  v54 boolean;
  v60 boolean;
  v61 boolean;
  s varchar2(4000);
  v_name varchar2(100) := nvl(p_FileName,'diary.txt');
  v_path varchar2(1000):= p_FilePath;
  v_code pls_integer := nvl(p_code, utils.DP);
begin
  if not IsOwnerAccessible(p_owner) then
      return null;
  end if;
  d := p_date;
  n := nvl(utils.get_interval(p_owner,'VERSION'), 3.4);
  v54 := n>=5.4;
  v60 := n>=6.0;
  v61 := n>=6.1;
  if not ie_db61.chk_exp_date(p_owner,v_code,d,p_make_date_safe,v61) then
    return null;
  end if;
  if v_path is null then
    v_path := nvl(get_value(p_owner,'FILE_PATH'),'/oradb1/utlfile');
  end if;
  if use_tz then
    use_tz := false;
    execute immediate 'alter session set time_zone=dbtimezone';
  end if;
  ie_file.start_exp(v_path, v_name, p_append);
  begin
    if v61 then
      ie_db61.exp(p_owner, v_code, d, false);
    elsif v54 then
      ie_db54.exp(p_owner, v60, v_code, d, false);
    else
      ie_db34.exp(p_owner, v_code, d, false);
    end if;
  exception
    when others then
      if sqlcode in(-6508,-4061) then
        raise;
      end if;
      s := utils.get_msg('ERROR', sqlerrm);
      if p_debug then
        s := s || utils.get_msg('EXP_ERROR_REPORT',
          n, v_code, ie_file.get_total_lines_count, ie_file.get_lines_count);
      end if;
  end;
  if not ie_file.get_table_name is null then
    s := utils.get_msg('RECORDS_EXPORTED',ie_file.get_lines_count,ie_file.get_table_name,
                       '('||v_path||'/'||v_name||to_char(d,' - DD/MM/YYYY)'))||s;
    utils.write_log(p_owner,'U','AUDIT',s);
    commit;
    ie_file.start_table_exp(null, null, null);
  end if;
  ie_file.finish_exp;
  return s;
exception
  when others then
    if sqlcode in(-6508,-4061) then
      raise;
    end if;
    ie_file.finish_exp;
    return s || utils.get_msg('ERROR', sqlerrm);
end;
--
function export(p_owner    varchar2, p_FilePath varchar2 default null,
                p_FileName varchar2 default null, p_append boolean default FALSE,
                p_diary boolean default TRUE, p_osh  boolean default TRUE,
                p_vals  boolean default TRUE, p_date date default null,
                p_och   boolean default TRUE,
                p_make_date_safe boolean default true) return varchar2 is
    s varchar2(30000);
    v_append boolean := p_append;
    n number;
begin
    if not IsOwnerAccessible(p_owner) then
        return null;
    end if;
    n := nvl(utils.get_interval(p_owner,'VERSION'),3.4);
    if p_diary then
        if n>=6.0 then
          for i in utils.DIARY1..utils.DIARY6 loop
            s := s||exp(p_owner,p_FilePath,p_FileName,v_append,i,p_date,p_make_date_safe);
            v_append := true;
          end loop;
          if n>=6.1 then
            s := s||exp(p_owner,p_FilePath,p_FileName,v_append,utils.DIARY7,p_date,p_make_date_safe);
            v_append := true;
          end if;
        else
          s := exp(p_owner,p_FilePath,p_FileName,v_append,utils.DIARY,p_date,p_make_date_safe);
          v_append := true;
        end if;
        s := s||exp(p_owner,p_FilePath,p_FileName,v_append,utils.DP,p_date,p_make_date_safe);
    end if;
    if p_vals then
        s := s||exp(p_owner,p_FilePath,p_FileName,v_append,utils.VALSH,p_date,p_make_date_safe);
        v_append := true;
    end if;
    if p_osh then
        s := s||exp(p_owner,p_FilePath,p_FileName,v_append,utils.OSH,p_date,p_make_date_safe);
        v_append := true;
    end if;
    if p_och and n>=6.0 then
        s := s||exp(p_owner,p_FilePath,p_FileName,v_append,utils.OCH,p_date,p_make_date_safe);
    end if;
    return s;
end;
-----------------------------------------------------
-- Импорт журнала(ов)
function imp(p_owner    varchar2, p_FilePath  varchar2 default null,
             p_FileName varchar2 default null, p_codes varchar2 default null,
             p_date     date default null, p_destowner varchar2 default null,
             p_debug boolean default false) return varchar2 is
  n number;
  v54 boolean;
  v60  boolean;
  v61  boolean;
  v63  boolean;
  s varchar2(30000);
  nrows   number;
  v_date  date := nvl(p_date,sysdate);
  m_date  date;
  v_owner varchar2(30)  := nvl(p_destowner,p_owner);
  m_owner varchar2(30);
  v_codes varchar2(100) := nvl(p_codes,'-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7');
  v_code  pls_integer;
  v_path  varchar2(1000):= p_FilePath;
  v_name  varchar2(100) := nvl(p_FileName,'diary.txt');
  v_table varchar2(100);
  v_count pls_integer;
  v_error varchar2(4000);
  v_need_dp boolean := false;
  v_need_diary_param boolean := false;
begin
  if not IsOwnerAccessible(p_owner) then
      return null;
  end if;
  n := nvl(utils.get_interval(v_owner,'VERSION'), 3.4);
  v54 := n>=5.4;
  v60 := n>=6.0;
  v61 := n>=6.1;
  v63 := n>=6.3;
  if v_path is null then
      v_path := nvl(get_value(v_owner,'FILE_PATH'),'/oradb1/utlfile');
  end if;
  nrows := nvl(utils.get_interval(v_owner,'ROWS'),100000);
  utils.set_interval(v_owner,'ROWS',nrows); commit;
  v_codes := upper(replace(v_codes, ' '));
  if substr(v_codes,1,1)<>',' then
      v_codes := ','||v_codes;
  end if;
  if substr(v_codes, length(v_codes), 1)<>',' then
      v_codes := v_codes||',';
  end if;
  v_codes := replace(v_codes, 'NULL', utils.DP);
  if use_tz then
    use_tz := false;
    execute immediate 'alter session set time_zone=dbtimezone';
  end if;
  ie_file.start_imp(v_path, v_name);
  while ie_file.get_next_table(v_code, m_owner, m_date) loop
    if m_owner = p_owner and m_date <= v_date then
      begin
        if v_code = utils.DIARY then
          if instr(v_codes,',' || utils.DIARY || ',') > 0 or
              instr(v_codes,',' || utils.DIARY1 || ',') > 0 then
            if v61 then
              ie_db61.imp_diary(v_owner, nrows, v_table, v_count);
            else
              ie_db34.imp_diary(v_owner, nrows, v_table, v_count);
            end if;
            v_need_diary_param := true;
          end if;
        elsif v_code = utils.DIARY_PARAM then
          if instr(v_codes, ',' || utils.DP || ',') > 0 or v_need_diary_param then
            if v61 then
              ie_db61.imp_diary_param(v_owner, nrows, v_table, v_count);
            else
              ie_db34.imp_diary_param(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code = utils.VALUES_HISTORY then
          if instr(v_codes, ',' || utils.VALSH || ',') > 0 then
            if v61 then
              ie_db61.imp_values_history(v_owner, nrows, v_table, v_count);
            else
              ie_db34.imp_values_history(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code = utils.OBJECT_STATE_HISTORY then
          if instr(v_codes, ',' || utils.OSH || ',') > 0 then
            if v61 then
              ie_db61.imp_object_state_history(v_owner, nrows, v_table, v_count);
            else
              ie_db34.imp_object_state_history(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code  = utils.DP then
          if instr(v_codes, ',' || utils.DP || ',') > 0 or v_need_dp then
            if v61 then
              ie_db61.imp_dp(v_owner, nrows, v_table, v_count);
            elsif v54 then
              ie_db54.imp_dp(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code = utils.VALSH then
          if instr(v_codes, ',' || utils.VALSH || ',') > 0 then
            if v61 then
              ie_db61.imp_valsh(v_owner, nrows, v_table, v_count);
            elsif v54 then
              ie_db54.imp_valsh(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code = utils.OSH then
          if instr(v_codes, ',' || utils.OSH || ',') > 0 then
            if v61 then
              ie_db61.imp_osh(v_owner, nrows, v_table, v_count);
            elsif v54 then
              ie_db54.imp_osh(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code = utils.OCH then
          if instr(v_codes, ',' || utils.OCH || ',') > 0 then
            if v61 then
              ie_db61.imp_och(v_owner, nrows, v_table, v_count);
            elsif v60 then
              ie_db54.imp_och(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        elsif v_code = utils.EDH then
          if instr(v_codes, ',' || utils.EDH || ',') > 0 then
            if v63 then
              ie_db61.imp_edh(v_owner, nrows, v_table, v_count);
            end if;
          end if;
        else
          if instr(v_codes,',' || v_code || ',') > 0 then
            if v61 and 1 <= v_code and v_code <= 7 then
              ie_db61.imp_diary_n(v_owner, v_code, nrows, v_table, v_count);
            elsif v54 and 1 <= v_code and v_code <= 6 then
              ie_db54.imp_diary_n(v_owner, v_code, nrows, v_table, v_count);
            end if;
            if v_code = utils.DIARY2 then
                v_need_dp := true;
            end if;
          end if;
        end if;
      exception
        when others then
          if sqlcode in(-6508,-4061) then
            raise;
          end if;
          v_error := utils.get_msg('ERROR', sqlerrm);
          if p_debug then
            v_error := v_error || utils.get_msg('IMP_ERROR_REPORT',
               n, v_codes, v_code, ie_file.get_table_name, ie_file.get_total_lines_count,
               ie_file.get_lines_count, ie_file.get_field_pos);
          end if;
      end;
      if not v_table is null then
        v_error := utils.get_msg('TO_DIARY',v_table,'('||v_path||'/'||v_name||to_char(v_date,' - DD/MM/YYYY)'))||v_error;
        if v_table <> ie_file.get_table_name then
          v_error := utils.get_msg('FROM_DIARY', ie_file.get_table_name)||' '||v_error;
        end if;
        v_error := utils.get_msg('RECORDS_IMPORTED',v_count)||' '||v_error;
        utils.write_log(p_owner,'U','AUDIT',v_error);
        commit;
        v_table := null;
      end if;
      s := s || v_error;
      v_error := null;
    end if;
  end loop;
  ie_file.finish_imp;
  return nvl(s, utils.get_msg('NO_DATA'));
exception
  when others then
    if sqlcode in(-6508,-4061) then
      raise;
    end if;
    ie_file.finish_imp;
    return s || utils.get_msg('ERROR', sqlerrm);
end;
--
function import(p_owner    varchar2, p_FilePath varchar2 default null,
                p_FileName varchar2 default null, p_diary boolean default TRUE,
                p_osh  boolean default TRUE, p_vals  boolean default TRUE,
                p_och  boolean default TRUE) return varchar2 is
    s   varchar2(100);
    n   number;
begin
  if not IsOwnerAccessible(p_owner) then
      return null;
  end if;
  n := nvl(utils.get_interval(p_owner,'VERSION'),3.4);
  if p_diary then
    s := '0,NULL,';
    if n>=6.0 then
        s := s || '1,2,3,4,5,6,';
        if n>=6.1 then
            s := s || '7,';
        end if;
    end if;
  end if;
  if p_vals then
      s := s||'-1,';
  end if;
  if p_osh then
      s := s||'-2,';
  end if;
  if p_och and n>=6.0 then
      s := s||'-3,';
  end if;
  if s is null then
    return null;
  end if;
  return imp(p_owner,p_FilePath,p_FileName,','||s);
end;
--
end;
/
show err package body clear

