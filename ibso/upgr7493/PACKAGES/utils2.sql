var db_version number
declare
  s1 varchar2(100);
  s2 varchar2(100);
begin
  dbms_utility.db_version(s1,s2);
  :db_version := substr(s1,1,instr(s1,'.')-1);
end;
/
column xxx new_value cmt10 noprint
select decode(sign(:db_version-9),1,'--','') xxx from dual;

column xxx new_value cmt9 noprint
select decode(sign(:db_version-10),-1,'--','') xxx from dual;

prompt utils body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/utils2.sql $
 *  $Author: almakarov $
 *  $Revision: 55349 $
 *  $Date:: 2014-11-14 14:20:25 #$
 *
 *  DBMS packages entry points for PL/PLUS
 */
utils is
--
    rseed       number;
--
procedure Randomize(p_seed number default null) is
begin
  if p_seed is null then
    rseed := to_number(to_char(sysdate,'SSSSS'))+mod(dbms_utility.get_time,100)/100;
    rseed := trunc((rseed/86400)*4294967296);
  else
    rseed := abs(p_seed);
    if rseed>1 then
      rseed := mod(trunc(rseed),4294967296);
    else
      rseed := trunc(rseed*4294967296);
    end if;
  end if;
end;
--
function Random ( p_base number default 1 ) return number is
begin
    if rseed is null then
      rseed := to_number(to_char(sysdate,'SSSSS'))+mod(dbms_utility.get_time,100)/100;
      rseed := trunc((rseed/86400)*4294967296);
    end if;
    rseed := rseed*134775813+1;
    rseed := mod(rseed,4294967296);
    return rseed*p_base/4294967296;
end;
--
function Hash_Id(p_num number) return pls_integer is
  r number;
begin
  if p_num<2147483648 then
    return p_num;
  else
    return 2147483647-p_num;
  end if;
exception when numeric_overflow then
  r := mod(p_num,4294967295);
  if r<2147483648 then
    return r;
  else
    return 2147483647-r;
  end if;
end;
--
function Hash_Id(p_str varchar2) return pls_integer is
begin
  return dbms_utility.get_hash_value(p_str,0,2147483647);
end;
--
function Hash_Id2(p_str varchar2) return pls_integer is
begin
  return dbms_utility.get_hash_value(p_str,0,2147483647);
end;
--
procedure opencursor ( p_cursor in out nocopy ref_cursor,
                       p_select varchar2,
                       p_vars   pls_integer,
                       p_value1 varchar2,
                       p_value2 varchar2,
                       p_value3 varchar2,
                       p_value4 varchar2,
                       p_value5 varchar2
                     ) is
  v_vars  pls_integer;
begin
  v_vars := nvl(p_vars,0);
  if v_vars<=0 then
    open p_cursor for p_select;
  elsif v_vars=1 then
    open p_cursor for p_select using p_value1;
  elsif v_vars=2 then
    open p_cursor for p_select using p_value1,p_value2;
  elsif v_vars=3 then
    open p_cursor for p_select using p_value1,p_value2,p_value3;
  elsif v_vars=4 then
    open p_cursor for p_select using p_value1,p_value2,p_value3,p_value4;
  else
    open p_cursor for p_select using p_value1,p_value2,p_value3,p_value4,p_value5;
  end if;
end;
--
function  open_cursor( p_cursor in out nocopy ref_cursor,
                       p_select varchar2,
                       p_raise  boolean  default TRUE,
                       p_vars   pls_integer default NULL,
                       p_value1 varchar2 default NULL,
                       p_value2 varchar2 default NULL,
                       p_value3 varchar2 default NULL,
                       p_value4 varchar2 default NULL,
                       p_value5 varchar2 default NULL
                     ) return boolean is
begin
  if p_raise then
    opencursor(p_cursor,p_select,p_vars,p_value1,p_value2,p_value3,p_value4,p_value5);
  else
    begin
      opencursor(p_cursor,p_select,p_vars,p_value1,p_value2,p_value3,p_value4,p_value5);
    exception when others then
      return false;
    end;
  end if;
  return true;
end;
--
  procedure sleep(seconds in number) is
  begin
    if seconds > 0 then
      dbms_lock.sleep(seconds);
    end if;
  end;
--
  function get_time return number is
  begin
    return dbms_utility.get_time;
  end;
--
  function error_stack(p_stack boolean default true) return varchar2 is
    s varchar2(2000);
  begin
    s := dbms_utility.format_error_stack;
    if s is null then
      return sqlerrm(0);
    end if;
    &&cmt9.if p_stack then
    &&cmt9.  return s||dbms_utility.format_error_backtrace;
    &&cmt9.end if;
    return rtrim(s,chr(10));
  end;
--
  function call_stack return varchar2 is
  begin
    return dbms_utility.format_call_stack;
  end;
--
  function session_id return varchar2 is
  begin
    return dbms_session.unique_session_id;
  end;
--
  procedure free_memory is
  begin
    dbms_session.free_unused_user_memory;
  end;
--
  procedure reset_package(p_free_all boolean default false) is
  begin
    if p_free_all then
      dbms_session.modify_package_state(dbms_session.FREE_ALL_RESOURCES);
    else
      dbms_session.modify_package_state(dbms_session.REINITIALIZE);
    end if;
  end;
--
  procedure set_sql_trace(sql_trace boolean, p_waits boolean default true, p_binds boolean default false) is
  begin
    &&cmt10.dbms_session.set_sql_trace(sql_trace);
    &&cmt9.if sql_trace then
    &&cmt9.  dbms_session.session_trace_enable(p_waits,p_binds);
    &&cmt9.else
    &&cmt9.  dbms_session.session_trace_disable;
    &&cmt9.end if;
  end;
--
  procedure set_sql_trace_in_session(sid pls_integer, serial pls_integer, sql_trace boolean,
                                     p_waits boolean default true, p_binds boolean default false) is
    v_level pls_integer;
  begin
    v_level := 0;
  	if sql_trace then
      if p_waits then
        v_level := 8;
        if p_binds then
          v_level := 12;
        end if;
      elsif p_binds then
        v_level := 4;
      else
        v_level := 1;
      end if;
  	end if;
    dbms_system.set_ev(sid, serial, 10046, v_level, '');
  end;
--
  procedure set_param_in_session(sid pls_integer, serial pls_integer, par_name varchar2,
                                 bool_val boolean, int_val pls_integer) is
  begin
    if bool_val is not null then
      dbms_system.set_bool_param_in_session(sid,serial,par_name,bool_val);
    elsif int_val is not null then
      dbms_system.set_int_param_in_session(sid,serial,par_name,int_val);
    end if;
  end;
--
  procedure set_role(role_cmd varchar2) is
  begin
    dbms_session.set_role(role_cmd);
  end;
--
  function is_role_enabled(rolename varchar2) return boolean is
  begin
    return dbms_session.is_role_enabled(rolename);
  end;
--
  procedure set_nls(param varchar2, value varchar2) is
  begin
    dbms_session.set_nls(param,value);
  end;
--
  function hash_value( name varchar2,
                       base      number default 0,
                       hash_size number default 1073741824
                     ) return pls_integer is
  begin
    return dbms_utility.get_hash_value(name,base,hash_size);
  end;
--
  function hash_value2( name varchar2,
                        base      number default 0,
                        hash_size number default 1073741824
                      ) return pls_integer is
  begin
    return dbms_utility.get_hash_value(name,base,hash_size);
  end;
--
-- @METAGS Int_Hex
function Int_Hex(p_idx pls_integer) return varchar2 is
    i   pls_integer;
    idx pls_integer := p_idx;
    sig pls_integer := 0;
    hex varchar2(3);
begin
    if idx<0 then
        idx := -idx;
        sig := 128;
    end if;
    for j in 1..3 loop
      if idx<256 then
        hex := chr(idx)||hex;
        idx := 0;
      else
        i := idx mod 256;
        idx := trunc(idx/256);
        hex := chr(i)||hex;
      end if;
    end loop;
    return chr(sig+idx)||hex;
end;
--
-- @METAGS Hex_Int
function Hex_Int(p_hex varchar2) return pls_integer is
    i   pls_integer;
    idx pls_integer;
    sig boolean := false;
begin
    idx := ascii(p_hex);
    if idx>127 then
        idx := idx-128;
        sig := true;
    end if;
    for j in 2..4 loop
        i := ascii(substr(p_hex,j,1));
        if idx>0 then
            idx := idx*256+i;
        else
            idx := i;
        end if;
    end loop;
    if sig then
        idx := -idx;
    end if;
    return idx;
end;
--
-- @METAGS Char_Hex
function Char_Hex(p_char varchar2) return varchar2 is
begin
    return str_hex(p_char);
end;
--
-- @METAGS Hex_Char
function Hex_Char(p_hex varchar2) return varchar2 is
begin
    return hex_str(p_hex);
end;
--
-- @METAGS Str_Hex
function Str_Hex(p_str varchar2) return varchar2 is
begin
    if p_str is null then
        return null;
    end if;
    return rawtohex(utl_raw.cast_to_raw(p_str));
end;
--
-- @METAGS Str_Hex2
function Str_Hex2(p_str varchar2, out_text pls_integer) return varchar2 is
begin
    if p_str is null then
        return null;
    end if;
    return rawtohex(utl_raw.cast_to_raw(stdio.transform(p_str,null,out_text)));
end;
--
-- @METAGS Hex_Str
function Hex_Str(p_str varchar2) return varchar2 is
begin
    if p_str is null then
        return null;
    end if;
    return utl_raw.cast_to_varchar2(hextoraw(p_str));
end;
--
-- @METAGS Hex_Str2
function Hex_Str2(p_str varchar2, in_text pls_integer) return varchar2 is
begin
    if p_str is null then
        return null;
    end if;
    return stdio.transform(utl_raw.cast_to_varchar2(hextoraw(p_str)),in_text,null);
end;
--
-- @METAGS Str_Raw
function Str_Raw(p_str varchar2) return raw is
begin
    return utl_raw.cast_to_raw(p_str);
end;
--
-- @METAGS Str_Raw2
function Str_Raw2(p_str varchar2, out_text pls_integer) return raw is
begin
    return utl_raw.cast_to_raw(stdio.transform(p_str,null,out_text));
end;
--
-- @METAGS Raw_Str
function Raw_Str(p_raw raw) return varchar2 is
begin
    return utl_raw.cast_to_varchar2(p_raw);
end;
--
-- @METAGS Raw_Str2
function Raw_Str2(p_raw raw, in_text pls_integer) return varchar2 is
begin
    return stdio.transform(utl_raw.cast_to_varchar2(p_raw),in_text,null);
end;
--
--
function concatenate_list(p_cursor in sys_refcursor, p_divider in varchar2) return varchar2
is
  l_return  VARCHAR2(32767); 
  l_temp    VARCHAR2(32767);
BEGIN
  LOOP
    FETCH p_cursor
    INTO  l_temp;
    EXIT WHEN p_cursor%NOTFOUND;
    l_return := l_return || p_divider || l_temp;
  END LOOP;
  RETURN LTRIM(l_return, p_divider);
end;
--
function local_transaction_id( create_transaction boolean DEFAULT false) return varchar2 is
begin
  return dbms_transaction.local_transaction_id(create_transaction);
end;
--
-- @METAGS regexp_*
function regexp_replace(source_string Varchar2,
                        pattern Varchar2,
                        replace_string Varchar2 DEFAULT null,
                        position Number DEFAULT 1,
                        occurrence Number DEFAULT 0,
                        match_parameter Varchar2 DEFAULT null) return varchar2 is
begin
  return standard.regexp_replace(source_string, pattern, replace_string, position, occurrence, match_parameter);
end;
--
function regexp_count(source_string Varchar2,
                      pattern Varchar2,
                      position Number DEFAULT 1,
                      match_parameter Varchar2 DEFAULT null) return number is
begin
  return standard.regexp_count(source_string, pattern, position, match_parameter);
end;
--
function regexp_instr(source_string Varchar2,
                      pattern Varchar2,
                      position Number DEFAULT 1,
                      occurrence Number DEFAULT 1,
                      return_option Number DEFAULT 0,
                      match_parameter Varchar2 DEFAULT null,
                      subexpr Number DEFAULT 0) return number is
begin
  return standard.regexp_instr(source_string, pattern, position, occurrence, return_option, match_parameter, subexpr);
end;
--
function regexp_substr(source_string Varchar2,
                      pattern Varchar2,
                      position Number DEFAULT 1,
                      occurrence Number DEFAULT 1,
                      match_parameter Varchar2 DEFAULT null,
                      subexpr Number DEFAULT 0) return varchar2 is
begin
  return standard.regexp_substr(source_string, pattern, position, occurrence, match_parameter, subexpr);
end;
--
function regexp_like(source_string Varchar2,
                     pattern Varchar2,
                     match_parameter Varchar2 DEFAULT null) return Boolean is
begin
  return standard.regexp_like(source_string, pattern, match_parameter);
end;
--
function split_string_to_array(
  p_input_string varchar2,
  p_separators   varchar2
) return type_string_table is
  v_result_array type_string_table;
  v_pattern      varchar2(32767) := utils.str_format('[^{1}]+', p_separators);
  cursor v_get_array(p_string varchar2, p_pattern varchar2) is
    select regexp_substr(p_string, p_pattern, 1, level)
      from dual
    connect by regexp_substr(p_string, p_pattern, 1, level) is not null;
begin
  open v_get_array(p_input_string, v_pattern);
  fetch v_get_array bulk collect into v_result_array;
  close v_get_array;
  return v_result_array;
exception
  when others then
    if v_get_array%isopen then
      close v_get_array;
    end if;
    return v_result_array;
end;
--
function iif(
  condition         boolean,
  output_when_true  varchar2,
  output_when_false varchar2
) return varchar2 is
begin
  if condition then
    return output_when_true;
  end if;
  return output_when_false;
end;
  
function iif(
  condition         boolean,
  output_when_true  pls_integer,
  output_when_false pls_integer
) return pls_integer is
begin
  if condition then
    return output_when_true;
  end if;
  return output_when_false;
end;
  
/* Заменяет placeholder'ы вида {1}, {2} и т.д. в text на значения p1, p2 и т.д.
   Также заменяет \n и \t в text на chr(10) и chr(9), соответственно*/
function str_format(
  text varchar2, 
  p1   varchar2 default NULL,
  p2   varchar2 default NULL,
  p3   varchar2 default NULL,
  p4   varchar2 default NULL,
  p5   varchar2 default NULL,
  p6   varchar2 default NULL,
  p7   varchar2 default NULL,
  p8   varchar2 default NULL
) return varchar2
is
  LF  constant varchar2(1) := chr(10);
  TB  constant varchar2(1) := chr(9);
  s            varchar2(32767);
begin
  s := replace(text,'\n',LF);
  s := replace(s,'\t',TB);
  s := replace(s,'{1}',p1);
  s := replace(s,'{2}',p2);
  s := replace(s,'{3}',p3);
  s := replace(s,'{4}',p4);
  s := replace(s,'{5}',p5);
  s := replace(s,'{6}',p6);
  s := replace(s,'{7}',p7);
  s := replace(s,'{8}',p8);
  return s;
end;
  
end utils;
/
show errors package body utils
