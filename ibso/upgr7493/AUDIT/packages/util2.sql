prompt utils body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/util2.sql $
 *  $Author: verkhovskiy $
 *  $Revision: 87850 $
 *  $Date:: 2015-12-08 13:21:57 #$
 */
utils is
--
    BUFFERSIZE    constant pls_integer := 100000;
    MAX_INTERVAL  constant pls_integer := 365000; -- must be synchronized with clear.MAX_INTERVAL
    LF      constant varchar2(1) := chr(10);
    CR      constant varchar2(1) := chr(13);
--
    Role_Name constant varchar2(30) := 'AUD_REVISOR';
--
    BUFFER_OVERFLOW exception;
    PRAGMA EXCEPTION_INIT(BUFFER_OVERFLOW, -20000);  -- ORA-20000: ORU-10027: buffer overflow, limit of 2000 bytes
--
    ROLE_EXISTS exception;
    PRAGMA EXCEPTION_INIT(ROLE_EXISTS, -01921);
--
    ROLE_DOES_NOT_EXISTS exception;
    PRAGMA EXCEPTION_INIT(ROLE_DOES_NOT_EXISTS, -01919);
--
    buf_enable  boolean := true;
    aud_init    boolean := true;
    aud_part    boolean;
    aud_uid     pls_integer;
    aud_owner   varchar2(30);
--
    use_paral   boolean := true;
    cur_owner   varchar2(30);
    cur_paral   pls_integer;
--
    aud_sid     pls_integer;
    aud_inst    pls_integer;
    aud_ses     pls_integer;
    aud_user    varchar2(30);
    aud_osuser  varchar2(30);
    aud_program varchar2(100);
    aud_module  varchar2(100);
    aud_machine varchar2(100);
    owners  dbms_sql.varchar2s;
-- Cache of messages
    type mes_tbl_t is table of varchar2(2000) index by varchar2(50);
    mes mes_tbl_t;
--
-----------------------------------------------------
procedure init is
begin
    select username, user_id into aud_owner, aud_uid
      from all_users where user_id=userenv('SCHEMAID');
    aud_init := false;
end;
-----------------------------------------------------
function force_parallel(p_owner varchar2) return pls_integer is
  v_paral varchar2(30);
  paral pls_integer;
begin
  v_paral := upper(nvl(get_value(p_owner,'FORCE_PARALLEL'),'0'));
  if substr(v_paral,1,1)='N' then
    paral := 0;
  elsif substr(v_paral,1,1)='Y' then
    paral := 1;
  else
    paral := v_paral;
    if paral<1 then
      paral := 0;
    end if;
  end if;
  return paral;
exception when value_error then
  return 0;
end;
-----------------------------------------------------
procedure inituser(p_audsid  out nocopy pls_integer,
                   p_orauser out nocopy varchar2,
                   p_osuser  out nocopy varchar2,
                   p_machine out nocopy varchar2,
                   p_module  out nocopy varchar2,
                   p_program out nocopy varchar2,
                   p_sid pls_integer default null) is
  str varchar2(100);
  s   number;
  n   number;
  j   number;
begin
  if p_sid is null then
    s := sys_context('USERENV','SID');
  else
    s := p_sid;
  end if;
  select audsid, sys_context('USERENV','BG_JOB_ID'), osuser, username, module, replace(machine,chr(0)), program
    into n, j, p_osuser, p_orauser, p_module, p_machine, str
    from v$session where sid=s and rownum=1;
  if j is null then
    if not str is null then
      p_program := substr(str,instr(str,'\',-1)+1);
    end if;
    if n > 2147483647 then
      n := dbms_utility.get_hash_value(dbms_session.unique_session_id,1073741824,1073741824);
    end if;
  elsif j > 2147483647 then
    n := dbms_utility.get_hash_value(dbms_session.unique_session_id,1073741824,1073741824);
  else
    p_osuser := 'JOB';
    p_program:= n;
    n := -j;
  end if;
  p_audsid := n;
end;
-----------------------------------------------------
procedure writelog(p_owner varchar2, p_ses  pls_integer, p_user varchar2,
                   p_topic varchar2, p_code varchar2,    p_text varchar2) is
begin
  execute immediate 'BEGIN DIARYS_INS(:OWNER,null,:SES,:USR,:TOP,:COD,:TXT); END;'
    using p_owner,p_ses,p_user,p_topic,p_code,p_text;
exception when others then null;
end;
--
procedure openses(p_owner varchar2,p_owner1 varchar2) is
  i pls_integer;
begin
  if aud_ses is null then
    aud_sid := sys_context('USERENV','SID');
    aud_inst:= to_number(sys_context('USERENV','INSTANCE'))-1;
    inituser(aud_ses,aud_user,aud_osuser,aud_machine,aud_module,aud_program,aud_sid);
  end if;
  i := dbms_utility.get_hash_value(p_owner,0,2147483647);
  if not owners.exists(i) then
    if p_owner=p_owner1 and nvl(sys_context(p_owner||'_SYSTEM','STATUS'),'0')<>'1'
       or p_owner<>p_owner1 and nvl(sys_context(p_owner1||'_SYSTEM','STATUS'),'0')<>'1'
    then
      writelog(p_owner,aud_ses,substr(nvl(aud_program,aud_module),1,70),'I','REGISTERED',
               aud_machine||' ('||aud_user||' - '||aud_osuser||' - '||aud_module||') '||aud_inst);
    end if;
    owners(i) := p_owner;
  end if;
end;
--
procedure open_ses(p_owner varchar2) is
begin
  if aud_init then init; end if;
  if p_owner is null or p_owner=aud_owner then
    for c in (select owner,schema_owner from owners
               where owner<>aud_owner and
                 ( user=aud_owner and owner=schema_owner
                   or user<>aud_owner
                      and schema_owner=sys_context(schema_owner||'_SYSTEM','OWNER') )
    ) loop
      openses(c.owner,c.schema_owner);
    end loop;
  else
    for c in (select owner,schema_owner from owners
               where owner=p_owner
                 and schema_owner=sys_context(schema_owner||'_SYSTEM','OWNER')
    ) loop
      openses(p_owner,c.schema_owner);
      return;
    end loop;
    openses(p_owner,p_owner);
  end if;
end;
--
procedure close_ses(p_owner varchar2) is
  i pls_integer;
begin
  if aud_ses is null then
    aud_sid := sys_context('USERENV','SID');
    aud_inst:= to_number(sys_context('USERENV','INSTANCE'))-1;
    inituser(aud_ses,aud_user,aud_osuser,aud_machine,aud_module,aud_program,aud_sid);
  end if;
  if p_owner is null or p_owner=aud_owner then
    i := owners.first;
    while not i is null loop
      writelog(owners(i),aud_ses,substr(nvl(aud_program,aud_module),1,70),'I','REMOVED',
               aud_machine||' ('||aud_user||' - '||aud_osuser||' - '||aud_module||') '||aud_inst);
      i := owners.next(i);
    end loop;
    owners.delete;
  else
    i := dbms_utility.get_hash_value(p_owner,0,2147483647);
    if owners.exists(i) then
      writelog(p_owner,aud_ses,substr(nvl(aud_program,aud_module),1,70),'I','REMOVED',
               aud_machine||' ('||aud_user||' - '||aud_osuser||' - '||aud_module||') '||aud_inst);
      owners.delete(i);
    end if;
  end if;
end;
--
procedure write_log(p_owner varchar2, p_topic varchar2, p_code varchar2, p_text varchar2) is
begin
  if aud_init then init; end if;
  if p_owner is null or p_owner=aud_owner then
    for c in (select owner,schema_owner from owners
               where owner<>aud_owner and
                   ( user=aud_owner and owner=schema_owner
                     or user<>aud_owner
                        and schema_owner=sys_context(schema_owner||'_SYSTEM','OWNER') )
    ) loop
      openses(c.owner,c.schema_owner);
      writelog(c.owner,aud_ses,aud_user||'.'||aud_osuser,p_topic,p_code,p_text);
    end loop;
  else
    open_ses(p_owner);
    writelog(p_owner,aud_ses,aud_user||'.'||aud_osuser,p_topic,p_code,p_text);
  end if;
end;
-----------------------------------------------------
procedure enable_buf ( p_size  IN pls_integer default null,
                       p_clear IN boolean default TRUE ) is
    v_size  pls_integer := nvl(p_size,0);
begin
    if p_clear then
        dbms_output.disable;
    end if;
    if v_size<=0 then
        v_size := BUFFERSIZE;
    end if;
    dbms_output.enable(v_size);
    buf_enable := false;
end;
--
procedure disable_buf is
begin
    dbms_output.disable;
end;
--
procedure put_line ( p_text IN varchar2,
                     p_nl   IN boolean default true
                   ) is
    len  pls_integer := nvl(length(p_text),0);
    len1 pls_integer;
    pos0 pls_integer := 1;
    pos1 pls_integer;
begin
    if buf_enable then
        enable_buf;
    end if;
    if len <= 255 then
        if p_nl then
            if len>0 then
                dbms_output.put_line( p_text );
            else
                dbms_output.new_line;
            end if;
        elsif len>0 then
            dbms_output.put( p_text );
        end if;
        return;
    end if;
    loop
        pos1 := instr( p_text, LF, pos0 );
        if pos1=len then
            pos1 := pos1+1;
        end if;
        if pos1 = 0 or pos1>pos0+255 then
            len1 := 255;
            pos1 := pos0+254;
        else
            len1 := pos1-pos0;
        end if;
        dbms_output.put_line( substr(p_text,pos0,len1) );
        pos0 := pos1 + 1;
        exit when pos0>len;
    end loop;
exception
when BUFFER_OVERFLOW or VALUE_ERROR then
    return;
end;
--
function get_line ( p_text out nocopy varchar2 ) return integer is
    v_status integer;
begin
    dbms_output.get_line( p_text, v_status );
    return v_status;
exception
when others then
    return 1;
end;
--
function get_buf return varchar2 is
    v_status integer;
    v_text  varchar2(1000);
    v_buf   varchar2(32767);
begin
    while
        get_line(v_text)=0
    loop
        v_buf := v_buf||v_text||LF;
    end loop;
    return v_buf;
end;
-----------------------------------------------------
function execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false, p_par varchar2 default null ) return integer is  -- @METAGS execute_sql
    v_count      integer := 0;
    v_param varchar2(2000) := p_par;
    v_par   boolean := not p_par is null;
begin
    if not comment is null then
        put_line(comment);
    end if;
    if v_par then
      execute immediate p_sql_block using in out v_param;
      v_count := v_param;
    else
      execute immediate p_sql_block;
      v_count := sql%rowcount;
    end if;
    return v_count;
exception when others then
    if not silent then
        put_line(p_sql_block); put_line(SQLERRM);
        raise;
    end if;
    return null;
end execute_sql;
--
procedure execute_sql ( p_sql_block varchar2, comment varchar2 default null, silent boolean default false ) is
    v_status     integer;
begin
    v_status := execute_sql(p_sql_block, comment, silent);
end execute_sql;
-----------------------------------------------------
function AudOwner return varchar2 is
begin
    if aud_init then init; end if;
    return aud_owner;
end;
-----------------------------------------------------
function AudPartitions return boolean is
begin
    if aud_init then init; end if;
    if aud_part is null then
      aud_part := upper(substr(nvl(get_value(aud_owner,'PARTITIONS'),'1'),1,1)) in ('1','Y');
    end if;
    return aud_part;
end;
-----------------------------------------------------
function get_value(p_owner varchar2, p_name varchar2) return varchar2 is
    s varchar2(2000);
begin
    select VALUE into s from settings
     where owner = p_owner and name = p_name ;
    return s;
exception when no_data_found then
    return null;
end;
--
procedure set_value(p_owner varchar2, p_name varchar2, p_value varchar2,
    p_description varchar2 default null) is
begin
  if p_name in ('UADMINS_MAX_COUNT','ADMIN_GRP_ENABLED','REVISOR_DISABLED') then
      return;
  end if;
  if p_value is null then
    delete from settings where owner = p_owner and name = p_name;
  else
    update settings
       set value = p_value, description = nvl(p_description,description)
     where owner = p_owner and name = p_name;
    if sql%notfound then
        insert into  settings(OWNER,NAME,VALUE,DESCRIPTION)
             values(p_owner,p_name,p_value,p_description);
    end if;
  end if;
end;
--
function get_interval(p_owner varchar2, p_name varchar2) return number is
    n   number;
begin
    n := to_number(get_value(p_owner,p_name),'9999999999.999');
    if n<0 then n:=null; end if;
    return n;
exception when value_error then
    return null;
end;
--
procedure set_interval(p_owner varchar2, p_name varchar2, p_interval number) is
begin
    set_value(p_owner,p_name,to_char(p_interval));
end;
-----------------------------------------------------
procedure exec_sql(p_sql varchar2,p_cmt varchar2) is
begin
    execute_sql(p_sql);
    put_line(p_cmt||' - OK.');
exception when others then null;
end;
-----------------------------------------------------
function check_role(p_user varchar2, p_role varchar2) return boolean is
begin
    for c in (select grantee from dba_role_privs
               where grantee=p_user and granted_role=p_role and rownum<2)
    loop
        return true;
    end loop;
    return false;
end;
--
procedure RevisorAccessible(p_user varchar2) is
  b boolean;
  u varchar2(30);
begin
  if aud_init then init; end if;
  if substr(get_value(Aud_Owner, 'REVISOR_DISABLED'), 1, 1) in ('Y', 'y' , '1') then
    error('REVISOR_DISABLED');
  end if;
  u := sys_context('USERENV','SESSION_USER');
  if u = Aud_Owner then
    return;
  end if;
  if not dbms_session.is_role_enabled(Role_Name) then
    error('USER_NOT_ACCESSIBLE',p_user);
  end if;
  b := true;
  for c in (select owner,schema_owner from owners
             where owner<>aud_owner
               and schema_owner=sys_context(schema_owner||'_SYSTEM','OWNER')
  ) loop
    if u = c.owner or u = c.schema_owner
      or dbms_session.is_role_enabled(c.owner||'_REVISOR')
      or dbms_session.is_role_enabled(c.schema_owner||'_REVISOR')
    then
      if p_user = u or check_role(p_user,c.owner||'_REVISOR') or check_role(p_user,c.schema_owner||'_REVISOR') then
        b := false; exit;
      end if;
    end if;
  end loop;
  if b then
    error('USER_NOT_ACCESSIBLE',p_user);
  end if;
end;
--
procedure create_user(p_user varchar2, p_name varchar2) is
begin
    RevisorAccessible(p_user);
    insert into users (username, name) values (p_user , p_name);
    commit;
    user_grants(p_user);
end;
--
procedure edit_user(p_user varchar2, p_name varchar2) is
begin
    RevisorAccessible(p_user);
    update users set name = p_name where username  = p_user;
    commit;
end;
--
procedure user_grants(p_user varchar2 default null) is
begin
  for c in (select username  from users u where username like nvl(p_user,'%') and
            exists (select 1 from all_users where username=u.username))
  loop
      RevisorAccessible(c.username);
      exec_sql('GRANT '||Role_Name||' TO '||c.username,
               'GRANT '||Role_Name||' TO '||c.username);
      write_log(null,'U','AUDIT',get_msg('REVISOR_GRANTS',c.username));
  end loop;
  commit;
end;
--
procedure delete_user(p_user varchar2) is
begin
    RevisorAccessible(p_user);
    for c in (select username  from users u where username = p_user and
              exists (select 1 from all_users where username=u.username))
    loop
        exec_sql('REVOKE '||Role_Name||' FROM '||p_user, 'REVOKE '||Role_Name||' FROM '||p_user);
    end loop;
    delete from users where username = p_user;
    commit;
end;
--
procedure roles(dropping boolean default true) is
begin
    create_views;

    if (dropping) then
        begin
            execute immediate 'DROP ROLE '||Role_Name;
            put_line('DROP ROLE '||Role_Name||' - OK');
        exception
            when ROLE_DOES_NOT_EXISTS then
                null;
            when others then
                put_line('DROP ROLE '||Role_Name||' - '||sqlerrm);
        end;
    end if;

    begin
        execute immediate 'CREATE ROLE '||Role_Name;
        put_line('CREATE ROLE '||Role_Name||' - OK');
    exception when ROLE_EXISTS then
        put_line('CREATE ROLE '||Role_Name||' - ALREADY EXISTS');
    end;

    exec_sql('GRANT EXECUTE ON CLEAR TO '||Role_Name,
                'GRANT EXECUTE ON CLEAR TO '||Role_Name);

    begin
        user_grants();
    exception when others then
        put_line('Unable to grant role '||Role_Name||' - '||sqlerrm);
    end;
end;
--
procedure grants(p_owner varchar2 default null) is
  n number;
  v_owner varchar2(30);
begin
  if aud_init then init; end if;
  for c in (select owner,schema_owner from owners where owner like nvl(p_owner,'%') and owner <> Aud_Owner) loop
    n := nvl(get_interval(c.owner,'VERSION'),3.4);
    put_line('--- '||c.owner||'.'||c.schema_owner||' Version: '||n);
    exec_sql('GRANT SELECT ON DIARY_ID TO '||c.schema_owner,'GRANT SELECT ON DIARY_ID TO '||c.schema_owner);
    exec_sql('GRANT SELECT ON VALS_ID TO '||c.schema_owner,'GRANT SELECT ON VALS_ID TO '||c.schema_owner);
    exec_sql('GRANT SELECT ON OSH_ID TO '||c.schema_owner,'GRANT SELECT ON OSH_ID TO '||c.schema_owner);
    exec_sql('GRANT SELECT ON AUDIT_SETTINGS TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON AUDIT_SETTINGS TO '||c.schema_owner);
    if n>=7.1 then
      exec_sql('GRANT EXECUTE ON SEND_NOTIFY_BIG TO '||c.schema_owner,'GRANT EXECUTE ON SEND_NOTIFY_BIG TO '||c.schema_owner);
    end if;
    if n>=6.5 then
      exec_sql('GRANT SELECT ON AUDIT_NOTIFICATIONS TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON AUDIT_NOTIFICATIONS TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON AUDIT_RECIPIENTS TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON AUDIT_RECIPIENTS TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON AUDIT_MESSAGES TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON AUDIT_MESSAGES TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON SEND_NOTIFY TO '||c.schema_owner,'GRANT EXECUTE ON SEND_NOTIFY TO '||c.schema_owner);
    end if;
    if n>=6.3 then
      exec_sql('GRANT SELECT ON EDH_ID TO '||c.schema_owner,'GRANT SELECT ON EDH_ID TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_EDH TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_EDH TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON EDH_INS TO '||c.schema_owner,'GRANT EXECUTE ON EDH_INS TO '||c.schema_owner);
    end if;
    if n>=6.1 then
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY7 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY7 TO '||c.schema_owner);
    end if;
    if n>=6.0 then
      exec_sql('GRANT SELECT ON OCH_ID TO '||c.schema_owner,'GRANT SELECT ON OCH_ID TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_OCH TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_OCH TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON OCH_INS TO '||c.schema_owner,'GRANT EXECUTE ON OCH_INS TO '||c.schema_owner);
    end if;
    if n>=5.4 then
      if c.owner=c.schema_owner then
        execute_sql('REVOKE SELECT ON DIARY FROM '||c.owner,'REVOKE SELECT ON DIARY FROM '||c.owner,true);
        execute_sql('REVOKE INSERT ON DIARY FROM '||c.owner,'REVOKE INSERT ON DIARY FROM '||c.owner,true);
        execute_sql('REVOKE SELECT ON DIARY_PARAM FROM '||c.owner,'REVOKE SELECT ON DIARY_PARAM FROM '||c.owner,true);
        execute_sql('REVOKE INSERT ON DIARY_PARAM FROM '||c.owner,'REVOKE INSERT ON DIARY_PARAM FROM '||c.owner,true);
        execute_sql('REVOKE SELECT ON OBJECT_STATE_HISTORY FROM '||c.owner,'REVOKE SELECT ON OBJECT_STATE_HISTORY FROM '||c.owner,true);
        execute_sql('REVOKE INSERT ON OBJECT_STATE_HISTORY FROM '||c.owner,'REVOKE INSERT ON OBJECT_STATE_HISTORY FROM '||c.owner,true);
        execute_sql('REVOKE SELECT ON VALUES_HISTORY FROM '||c.owner,'REVOKE SELECT ON VALUES_HISTORY FROM '||c.owner,true);
        execute_sql('REVOKE INSERT ON VALUES_HISTORY FROM '||c.owner,'REVOKE INSERT ON VALUES_HISTORY FROM '||c.owner,true);
      end if;
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY1 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY1 TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY2 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY2 TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY3 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY3 TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY4 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY4 TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY5 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY5 TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_DIARY6 TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DIARY6 TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_DP TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_DP TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_OSH TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_OSH TO '||c.schema_owner);
      exec_sql('GRANT SELECT ON '||c.owner||'_VALSH TO '||c.schema_owner||' WITH GRANT OPTION','GRANT SELECT ON '||c.owner||'_VALSH TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON OSH_INS TO '||c.schema_owner,'GRANT EXECUTE ON OSH_INS TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON VALSH_INS TO '||c.schema_owner,'GRANT EXECUTE ON VALSH_INS TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON DPARAM_INS TO '||c.schema_owner,'GRANT EXECUTE ON DPARAM_INS TO '||c.schema_owner);
      exec_sql('GRANT EXECUTE ON DIARYS_INS TO '||c.schema_owner,'GRANT EXECUTE ON DIARYS_INS TO '||c.schema_owner);
      write_log(c.owner,'U','AUDIT',get_msg('OWNER_GRANTS',c.schema_owner));
    elsif c.owner=c.schema_owner then
      exec_sql('GRANT SELECT ON DIARY TO '||c.owner||' WITH GRANT OPTION','GRANT SELECT ON DIARY TO '||c.owner);
      exec_sql('GRANT INSERT ON DIARY TO '||c.owner,'GRANT INSERT ON DIARY TO '||c.owner);
      exec_sql('GRANT SELECT ON DIARY_PARAM TO '||c.owner||' WITH GRANT OPTION','GRANT SELECT ON DIARY_PARAM TO '||c.owner);
      exec_sql('GRANT INSERT ON DIARY_PARAM TO '||c.owner,'GRANT INSERT ON DIARY_PARAM TO '||c.owner);
      exec_sql('GRANT SELECT ON OBJECT_STATE_HISTORY TO '||c.owner||' WITH GRANT OPTION','GRANT SELECT ON OBJECT_STATE_HISTORY TO '||c.owner);
      exec_sql('GRANT INSERT ON OBJECT_STATE_HISTORY TO '||c.owner,'GRANT INSERT ON OBJECT_STATE_HISTORY TO '||c.owner);
      exec_sql('GRANT SELECT ON VALUES_HISTORY TO '||c.owner||' WITH GRANT OPTION','GRANT SELECT ON VALUES_HISTORY TO '||c.owner);
      exec_sql('GRANT INSERT ON VALUES_HISTORY TO '||c.owner,'GRANT INSERT ON VALUES_HISTORY TO '||c.owner);
    end if;
  end loop;
  commit;
end;
--
function table_name(p_owner varchar2,p_type pls_integer,p_select boolean default true) return varchar2 is
  v_suffix  varchar2(50);
begin
  if p_select then
    select diary_suffix into v_suffix from diary_tables where diary_type = p_type and owner = p_owner;
  elsif p_type=VALSH then
    v_suffix := 'VALSH';
  elsif p_type=OSH then
    v_suffix := 'OSH';
  elsif p_type=OCH then
    v_suffix := 'OCH';
  elsif p_type=DP then
    v_suffix := 'DP';
  elsif p_type=EDH then
    v_suffix := 'EDH';
  else
    v_suffix := 'DIARY'||p_type;
  end if;
  return upper(p_owner||'_'||v_suffix);
exception when NO_DATA_FOUND then
  error('EXEC_ERROR','Can not find diary info for type: ' || p_type);
end;
--
function get_column_type(p_table varchar2, p_column varchar2, p_prec varchar2 default null) return varchar2 is
  v_typ varchar2(100);
  v_len pls_integer;
  v_prc pls_integer;
  v_scl pls_integer;
  i pls_integer;
begin
  select data_type, data_length, data_precision, data_scale
    into v_typ, v_len, v_prc, v_scl from user_tab_columns
   where table_name=p_table and column_name=p_column;
  if p_prec='1' then
    if v_prc is null then
      if v_len>0 and v_typ in ('RAW','CHAR','VARCHAR','VARCHAR2') then
        v_typ := v_typ||'('||v_len||')';
      end if;
    elsif v_scl<>0 then
      v_typ := v_typ||'('||v_prc||','||v_scl||')';
    else
      v_typ := v_typ||'('||v_prc||')';
    end if;
  else
    i := instr(v_typ,' ');
    if i>0 then
      v_typ := substr(v_typ,1,i-1);
    end if;
    i := instr(v_typ,'(');
    if i>0 then
      v_typ := substr(v_typ,1,i-1);
    end if;
  end if;
  return v_typ;
exception when no_data_found then
  return null;
end;
--
procedure create_views is
begin
  if aud_init then init; end if;
  exec_sql(
    'create or replace view audit_settings as' || LF ||
    '    select * from settings s' || LF ||
    '    where exists(select 1 from owners o where o.owner=s.owner and schema_owner=sys_context(schema_owner||''_SYSTEM'',''OWNER''))' || LF ||
    '       or userenv(''SCHEMAID'')=' || aud_uid || ' and owner<>''' || aud_owner || ''''
    ,'CREATE VIEW AUDIT_SETTINGS');
  exec_sql(
    'create or replace view audit_notifications as' || LF ||
    '    select * from notifications n' || LF ||
    '    where exists(select 1 from owners o where o.owner=n.owner and schema_owner=sys_context(schema_owner||''_SYSTEM'',''OWNER''))' || LF ||
    '        or userenv(''SCHEMAID'')=' || aud_uid || ' and owner<>''' || aud_owner || ''''
    ,'CREATE VIEW AUDIT_NOTIFICATIONS');
  exec_sql(
    'create or replace view audit_recipients as' || LF ||
    '    select * from recipients r' || LF ||
    '    where exists(select 1 from owners o where o.owner=r.owner and schema_owner=sys_context(schema_owner||''_SYSTEM'',''OWNER''))' || LF ||
    '       or userenv(''SCHEMAID'')=' || aud_uid || ' and owner<>''' || aud_owner || ''''
    ,'CREATE VIEW AUDIT_RECIPIENTS');
  exec_sql(
    'create or replace view audit_messages as' || LF ||
    '    select * from messages' || LF ||
    '    where topic in (''SUBJ'',''BODY'')'
    ,'CREATE VIEW AUDIT_MESSAGES');
end;
--
procedure create_procedures is
  v_set   varchar2(32767);
  v_och   varchar2(32767);
  v_osh   varchar2(32767);
  v_vals  varchar2(32767);
  v_dp    varchar2(32767);
  v_edh   varchar2(32767);
  v_dry   varchar2(32767);
  v_name  varchar2(50);
  v_time  varchar2(50);
  v_fields varchar2(200);
  v_params varchar2(200);
  n number;
  b boolean;
begin
  if aud_init then init; end if;
  for c in (select distinct owner from owners where owner <> Aud_Owner) loop
    n := nvl(get_interval(c.owner,'VERSION'), 3.4);
    if n >= 5.4 then
      b := n>=6.1;
      v_name := table_name(c.owner,utils.OSH,b);
      if b then
        v_time := 'SYSTIMESTAMP';
        v_fields := 'OBJ_ID,CLASS_ID,STATE_ID,AUDSID,USER_ID';
        v_params := ',P_OBJ_ID,P_CLASS_ID,P_STATE_ID,P_AUDSID,P_USER_ID';
      else
        v_time := 'SYSDATE';
        v_fields := 'OBJ_ID,STATE_ID,AUDSID,USER_ID';
        v_params := ',P_OBJ_ID,P_STATE_ID,P_AUDSID,P_USER_ID';
      end if;
      v_osh := v_osh ||'elsif p_owner='''||c.owner||''' then'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(OSH_ID.NEXTVAL,' || v_time||v_params || ');' || LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;' || LF;
--
      v_name := table_name(c.owner,utils.VALSH,b);
      if b then
        v_fields := 'OBJ_ID,CLASS_ID,AUDSID,USER_ID,QUAL,BASE_ID,VALUE';
        v_params := ',P_OBJ_ID,P_CLASS_ID,P_AUDSID,P_USER_ID,P_QUAL,P_BASE_ID,P_VALUE';
      else
        v_fields := 'OBJ_ID,AUDSID,USER_ID,QUAL,BASE_ID,VALUE';
        v_params := ',P_OBJ_ID,P_AUDSID,P_USER_ID,P_QUAL,P_BASE_ID,P_VALUE';
      end if;
      v_vals:= v_vals||'elsif p_owner='''||c.owner||''' then'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(VALS_ID.NEXTVAL,' || v_time||v_params || ');' || LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;' || LF;
--
      if n >= 6.0 then
        v_name := table_name(c.owner,utils.OCH,b);
        if b then
          v_fields := 'OBJ_ID,CLASS_ID,COLLECTION_ID,OBJ_PARENT,AUDSID,USER_ID';
          v_params := ',P_OBJ_ID,P_CLASS_ID,P_COLLECTION_ID,P_OBJ_PARENT,P_AUDSID,P_USER_ID';
        else
          v_fields := 'OBJ_ID,COLLECTION_ID,AUDSID,USER_ID';
          v_params := ',P_OBJ_ID,P_COLLECTION_ID,P_AUDSID,P_USER_ID';
        end if;
        v_och := v_och ||'elsif p_owner='''||c.owner||''' then'||LF
              ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(OCH_ID.NEXTVAL,' || v_time||v_params || ');'||LF
              ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF;
      end if;
--
      v_name := table_name(c.owner,utils.DP,b);
      if b then
        v_fields := 'TIME,QUAL,BASE_ID,TEXT';
        v_params := v_time||',P_QUAL,P_BASE_ID,P_TEXT';
      elsif get_column_type(v_name,'TIME') is null then
        v_fields := 'QUAL,TEXT';
        v_params := 'P_QUAL,P_TEXT';
      else
        v_fields := 'TIME,QUAL,TEXT';
        v_params := 'SYSDATE,P_QUAL,P_TEXT';
      end if;
      v_dp  := v_dp  ||'elsif p_owner='''||c.owner||''' then'||LF
            ||'  insert into ' || v_name || ' (DIARY_ID,' || v_fields || ') values(P_DIARY_ID,' || v_params || ');'||LF;
--
      v_fields := 'AUDSID,USER_ID,TOPIC,CODE,TEXT';
      v_params := ',P_AUDSID,P_USER_ID,P_TOPIC,P_CODE,P_TEXT';
      v_dry := v_dry ||'elsif p_owner='''||c.owner||''' then'||LF;
--
      v_name := table_name(c.owner,utils.DIARY1,b);
      if b then
        v_dry := v_dry ||' if p_topic=''L'' then'||LF
              ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
              ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF
              ||' elsif p_topic=''D'' then'||LF;
        v_name := table_name(c.owner,utils.DIARY7,b);
      else
        v_dry := v_dry ||' if p_topic in (''L'',''D'') then'||LF;
      end if;
      v_dry := v_dry
            ||'  if p_id is null then insert into ' || v_name || ' (ID, TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF;
--
      v_name := table_name(c.owner,utils.DIARY2,b);
      v_dry := v_dry ||' elsif p_topic=''P'' then'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF;
--
      v_name := table_name(c.owner,utils.DIARY3,b);
      v_dry := v_dry ||' elsif p_topic in (''U'',''E'') then'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF;
--
      v_name := table_name(c.owner,utils.DIARY5,b);
      v_dry := v_dry ||' elsif p_topic in (''I'',''J'') then'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF;
--
      v_name := table_name(c.owner,utils.DIARY6,b);
      v_dry := v_dry ||' elsif p_topic in (''H'',''N'') then'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID, ' || v_time||v_params || '); end if;'||LF;
--
      v_name := table_name(c.owner,utils.DIARY4,b);
      v_dry := v_dry ||' else'||LF
            ||'  if p_id is null then insert into ' || v_name || ' (ID, TIME,' || v_fields || ') values(DIARY_ID.NEXTVAL,' || v_time||v_params || ');'||LF
            ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_time||v_params || '); end if;'||LF
            ||' end if;'||LF;
--
      if n >= 6.3 then
          v_name := table_name(c.owner,utils.EDH,b);
          v_fields := 'OBJ_ID,CLASS_ID,AUDSID,USER_ID,TYPE_ID,CODE,TEXT';
          v_params := v_time||',P_OBJ_ID,P_CLASS_ID,P_AUDSID,P_USER_ID,P_TYPE_ID,P_CODE,P_TEXT';
          v_edh := v_edh ||'elsif p_owner='''||c.owner||''' then'||LF
                ||'  if p_id is null then insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(EDH_ID.NEXTVAL,' || v_params || ');' || LF
                ||'  else insert into ' || v_name || ' (ID,TIME,' || v_fields || ') values(P_ID,' || v_params || '); end if;' || LF;
      end if;
    end if;
  end loop;
  create_views;
  if v_osh is null then
    execute_sql('DROP PROCEDURE DIARYS_INS','DROP PROCEDURE DIARYS_INS',true);
    execute_sql('DROP PROCEDURE DPARAM_INS','DROP PROCEDURE DPARAM_INS',true);
    execute_sql('DROP PROCEDURE VALSH_INS','DROP PROCEDURE VALSH_INS',true);
    execute_sql('DROP PROCEDURE OSH_INS','DROP PROCEDURE OSH_INS',true);
    execute_sql('DROP TRIGGER USERS_CHANGES','DROP TRIGGER USERS_CHANGES',true);
    execute_sql('DROP TRIGGER AUDIT_SETTINGS_CHANGES','DROP TRIGGER AUDIT_SETTINGS_CHANGES',true);
    execute_sql('DROP TRIGGER NOTIFICATIONS_CHANGES','DROP TRIGGER NOTIFICATIONS_CHANGES',true);
    execute_sql('DROP TRIGGER RECIPIENTS_CHANGES','DROP TRIGGER RECIPIENTS_CHANGES',true);
    execute_sql('DROP TRIGGER DIARY_TABLES_CHANGES','DROP TRIGGER DIARY_TABLES_CHANGES',true);
    execute_sql('DROP TRIGGER DIARY_INDEXES_CHANGES','DROP TRIGGER DIARY_INDEXES_CHANGES',true);
    execute_sql('DROP TRIGGER DIARY_PARTITIONS_CHANGES','DROP TRIGGER DIARY_PARTITIONS_CHANGES',true);
  else
    exec_sql('CREATE OR REPLACE PROCEDURE OSH_INS(P_OWNER VARCHAR2,P_ID NUMBER,P_OBJ_ID VARCHAR2,P_STATE_ID VARCHAR2,P_AUDSID NUMBER,P_USER_ID VARCHAR2,P_CLASS_ID VARCHAR2 DEFAULT NULL) AS'||LF
            ||'begin'||LF||substr(v_osh,4)
            ||'else utils.error(''OWNER_NOT_REGISTERED'',P_OWNER); end if;'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE OSH_INS');
    exec_sql('CREATE OR REPLACE PROCEDURE VALSH_INS(P_OWNER VARCHAR2,P_ID NUMBER,P_OBJ_ID VARCHAR2,P_AUDSID NUMBER,P_USER_ID VARCHAR2,P_QUAL VARCHAR2,P_BASE_ID VARCHAR2,P_VALUE VARCHAR2,P_CLASS_ID VARCHAR2 DEFAULT NULL) AS'||LF
            ||'begin'||LF||substr(v_vals,4)
            ||'else utils.error(''OWNER_NOT_REGISTERED'',P_OWNER); end if;'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE VALSH_INS');
    exec_sql('CREATE OR REPLACE PROCEDURE DPARAM_INS(P_OWNER VARCHAR2,P_DIARY_ID NUMBER,P_QUAL VARCHAR2,P_TEXT VARCHAR2,P_BASE_ID VARCHAR2 DEFAULT NULL) AS'||LF
            ||'begin'||LF||substr(v_dp,4)
            ||'else utils.error(''OWNER_NOT_REGISTERED'',P_OWNER); end if;'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE DPARAM_INS');
    exec_sql('CREATE OR REPLACE PROCEDURE DIARYS_INS(P_OWNER VARCHAR2,P_ID NUMBER,P_AUDSID NUMBER,P_USER_ID VARCHAR2,P_TOPIC VARCHAR2,P_CODE VARCHAR2,P_TEXT VARCHAR2) AS'||LF
            ||'begin'||LF||substr(v_dry,4)
            ||'else utils.error(''OWNER_NOT_REGISTERED'',P_OWNER); end if;'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE DIARYS_INS');
    exec_sql('CREATE OR REPLACE PROCEDURE SEND_NOTIFY(P_OWNER VARCHAR2,P_EVENT VARCHAR2,'||LF
            ||'  P_SUBJ1 VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_SUBJ2 VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_SUBJ3 VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES1  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES2  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES3  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES4  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES5  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES6  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES7  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES8  VARCHAR2 DEFAULT NULL,'||LF
            ||'  P_MES9  VARCHAR2 DEFAULT NULL) IS'||LF
            ||'begin'||LF
            ||'  mail_mgr.send_notify(p_owner,p_event,p_subj1,p_subj2,p_subj3,'||LF
            ||'    p_mes1,p_mes2,p_mes3,p_mes4,p_mes5,p_mes6,p_mes7,p_mes8,p_mes9);'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE SEND_NOTIFY');
    exec_sql('CREATE OR REPLACE PROCEDURE SEND_NOTIFY_BIG(P_OWNER VARCHAR2,P_EVENT VARCHAR2,'||LF
            ||'  P_SUBJ VARCHAR2,'||LF
            ||'  P_BODY CLOB) IS'||LF
            ||'begin'||LF
            ||'  mail_mgr.send_notify(p_owner,p_event,p_subj, p_body);'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE SEND_NOTIFY_BIG');
    exec_sql('CREATE OR REPLACE TRIGGER USERS_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE ON USERS FOR EACH ROW'||LF
            ||'Declare s varchar2(2000);'||LF
            ||'Begin'||LF
            ||'if deleting then s:=utils.get_msg(''REVISOR_DELETED'',:old.username,:old.name);'||LF
            ||'elsif inserting then s:=utils.get_msg(''REVISOR_CREATED'',:new.username,:new.name);'||LF
            ||'elsif :old.name=:new.name and :old.username=:new.username then null;'||LF
            ||'else s:=utils.get_msg(''REVISOR_EDITED'',:new.username,:new.name,:old.name);'||LF
            ||'end if;'||LF
            ||'if not s is null then utils.write_log(null,''U'',''AUDIT'',s); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER USERS_CHANGES');
    exec_sql('CREATE OR REPLACE TRIGGER AUDIT_SETTINGS_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE OF NAME,VALUE ON SETTINGS FOR EACH ROW'||LF
            ||'Declare o varchar2(30); s varchar2(4100); c varchar2(16);'||LF
            ||'Begin'||LF
            ||'if deleting then o:=:old.owner; c:=''DELETE''; s:=:old.name||'',''||:old.value;'||LF
            ||'elsif :new.name=''BATTLE_PASS'' then null;'||LF
            ||'elsif inserting then o:=:new.owner; c:=''CREATE''; s:=:new.name||'',''||:new.value;'||LF
            ||'elsif :old.name=:new.name and :old.value=:new.value then null;'||LF
            ||'else o:=:new.owner; c:=''SET''; s := :new.name||'',''||:new.value||'' (''||:old.value||'')'';'||LF
            ||'end if;'||LF
            ||'if o<>'''||Aud_Owner||''' then utils.write_log(o,''G'',c,''AUDIT_SETTINGS-''||substr(s,1,1980)); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER AUDIT_SETTINGS_CHANGES');
    exec_sql('CREATE OR REPLACE TRIGGER NOTIFICATIONS_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE ON NOTIFICATIONS FOR EACH ROW'||LF
            ||'Declare o varchar2(30); s varchar2(2100); c varchar2(16);'||LF
            ||'Begin'||LF
            ||'if deleting then o:=:old.owner; c:=''DELETE''; s:=:old.event;'||LF
            ||'elsif inserting then o:=:new.owner; c:=''CREATE'';'||LF
            ||'  s:=:new.event||'',SENDER(''||:new.sender||'') STATUS('''||LF
            ||'   ||:new.status||'') SUBJECT(''||:new.subject||'') MESSAGE(''||:new.message||'')'';'||LF
            ||'else'||LF
            ||'  if :old.sender=:new.sender then null;'||LF
            ||'  else s:=''SENDER(''||:new.sender||'' - ''||:old.sender||'') ''; end if;'||LF
            ||'  if :old.status=:new.status then null;'||LF
            ||'  else s:=s||''STATUS(''||:new.status||'' - ''||:old.status||'')''; end if;'||LF
            ||'  if :old.subject=:new.subject then null;'||LF
            ||'  else s:=s||''SUBJECT(''||:new.subject||'' - ''||:old.subject||'') ''; end if;'||LF
            ||'  if :old.message=:new.message then null;'||LF
            ||'  else s:=s||''MESSAGE(''||:new.message||'' - ''||:old.message||'') ''; end if;'||LF
            ||'  if not s is null then o:=:new.owner; c:=''SET''; s:=:new.event||'',''||s; end if;'||LF
            ||'end if;'||LF
            ||'if o<>'''||Aud_Owner||''' then utils.write_log(o,''G'',c,''AUDIT_NOTIFICATIONS-''||s); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER NOTIFICATIONS_CHANGES');
    exec_sql('CREATE OR REPLACE TRIGGER RECIPIENTS_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE ON RECIPIENTS FOR EACH ROW'||LF
            ||'Declare o varchar2(30); s varchar2(2100); c varchar2(16);'||LF
            ||'Begin'||LF
            ||'if deleting then o:=:old.owner; c:=''DELETE''; s:=:old.event||'',''||:old.email;'||LF
            ||'elsif inserting then o:=:new.owner; c:=''CREATE'';'||LF
            ||'  s:=:new.event||'',''||:new.email||'',STATUS(''||:new.status||'')'';'||LF
            ||'else'||LF
            ||'  if :old.email=:new.email then null;'||LF
            ||'  else s:=:new.email||'' (''||:old.email||'')''; end if;'||LF
            ||'  if :old.status=:new.status then null;'||LF
            ||'  else'||LF
            ||'    if s is null then s:=:new.email; end if;'||LF
            ||'    s:=s||'',STATUS(''||:new.status||'' - ''||:old.status||'')'';'||LF
            ||'  end if;'||LF
            ||'  if not s is null then o:=:new.owner; c:=''SET''; s:=:new.event||'',''||s; end if;'||LF
            ||'end if;'||LF
            ||'if o<>'''||Aud_Owner||''' then utils.write_log(o,''G'',c,''AUDIT_RECIPIENTS-''||s); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER RECIPIENTS_CHANGES');
    exec_sql('CREATE OR REPLACE TRIGGER DIARY_TABLES_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE ON DIARY_TABLES FOR EACH ROW'||LF
            ||'Declare o varchar2(30); s varchar2(2000); c varchar2(16);'||LF
            ||'Begin'||LF
            ||'if deleting then o:=:old.owner; c:=''DELETE''; s:=o||''_''||:old.diary_suffix;'||LF
            ||'elsif inserting then o:=:new.owner; c:=''CREATE'';'||LF
            ||'  s:=o||''_''||:new.diary_suffix||'',TABLESPACE_NAME(''||:new.tablespace_name||'') IDX_TABLESPACE_NAME('''||LF
            ||'   ||:new.idx_tablespace_name||'') STORAGE_INITIAL(''||:new.storage_initial||'') STORAGE_NEXT(''||:new.storage_next||'')'';'||LF
            ||'else'||LF
            ||'  if :old.tablespace_name=:new.tablespace_name then null;'||LF
            ||'  else s:=''TABLESPACE_NAME(''||:new.tablespace_name||'' - ''||:old.tablespace_name||'') ''; end if;'||LF
            ||'  if :old.idx_tablespace_name=:new.idx_tablespace_name then null;'||LF
            ||'  else s:=s||''IDX_TABLESPACE_NAME(''||:new.idx_tablespace_name||'' - ''||:old.idx_tablespace_name||'') ''; end if;'||LF
            ||'  if :old.storage_initial=:new.storage_initial then null;'||LF
            ||'  else s:=s||''STORAGE_INITIAL(''||:new.storage_initial||'' - ''||:old.storage_initial||'') ''; end if;'||LF
            ||'  if :old.storage_next=:new.storage_next then null;'||LF
            ||'  else s:=s||''STORAGE_NEXT(''||:new.storage_next||'' - ''||:old.storage_next||'')''; end if;'||LF
            ||'  if not s is null then o:=:new.owner; c:=''SET''; s:=o||''_''||:new.diary_suffix||'',''||s; end if;'||LF
            ||'end if;'||LF
            ||'if not o is null then utils.write_log(o,''G'',c,''DIARY_TABLES-''||s); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER DIARY_TABLES_CHANGES');
    exec_sql('CREATE OR REPLACE TRIGGER DIARY_INDEXES_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE ON DIARY_INDEXES FOR EACH ROW'||LF
            ||'Declare o varchar2(30); s varchar2(2000); c varchar2(16);'||LF
            ||'Begin'||LF
            ||'if deleting then o:=:old.owner; c:=''DELETE''; s:=utils.table_name(o,:old.diary_type)||''_''||:old.index_suffix;'||LF
            ||'elsif inserting then o:=:new.owner; c:=''CREATE'';'||LF
            ||'  s:=utils.table_name(o,:new.diary_type)||''_''||:new.index_suffix'||LF
            ||'   ||'',STORAGE_INITIAL(''||:new.storage_initial||'') STORAGE_NEXT(''||:new.storage_next||'')'';'||LF
            ||'else'||LF
            ||'  if :old.storage_initial=:new.storage_initial then null;'||LF
            ||'  else s:=''STORAGE_INITIAL(''||:new.storage_initial||'' - ''||:old.storage_initial||'') ''; end if;'||LF
            ||'  if :old.storage_next=:new.storage_next then null;'||LF
            ||'  else s:=s||''STORAGE_NEXT(''||:new.storage_next||'' - ''||:old.storage_next||'')''; end if;'||LF
            ||'  if not s is null then o:=:new.owner; c:=''SET''; s:=utils.table_name(o,:new.diary_type)||''_''||:new.index_suffix||'',''||s; end if;'||LF
            ||'end if;'||LF
            ||'if not o is null then utils.write_log(o,''G'',c,''DIARY_INDEXES-''||s); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER DIARY_INDEXES_CHANGES');
    exec_sql('CREATE OR REPLACE TRIGGER DIARY_PARTITIONS_CHANGES'||LF
            ||'AFTER INSERT OR DELETE OR UPDATE ON DIARY_PARTITIONS FOR EACH ROW'||LF
            ||'Declare o varchar2(30); s varchar2(2000); c varchar2(16);'||LF
            ||'Begin'||LF
            ||'if deleting then o:=:old.owner; c:=''DELETE''; s:=:old.diary_step||''_''||:old.step_number||'')'';'||LF
            ||'elsif inserting then o:=:new.owner; c:=''CREATE'';'||LF
            ||'  s:=:new.diary_step||''_''||:new.step_number||''),TABLESPACE_NAME(''||:new.tablespace_name||'') IDX_TABLESPACE_NAME(''||:new.idx_tablespace_name||'')'';'||LF
            ||'else'||LF
            ||'  if :old.tablespace_name=:new.tablespace_name then null;'||LF
            ||'  else s:=''TABLESPACE_NAME(''||:new.tablespace_name||'' - ''||:old.tablespace_name||'') ''; end if;'||LF
            ||'  if :old.idx_tablespace_name=:new.idx_tablespace_name then null;'||LF
            ||'  else s:=s||''IDX_TABLESPACE_NAME(''||:new.idx_tablespace_name||'' - ''||:old.idx_tablespace_name||'')''; end if;'||LF
            ||'  if not s is null then o:=:new.owner; c:=''SET''; s:=:new.diary_step||''_''||:new.step_number||''),''||s; end if;'||LF
            ||'end if;'||LF
            ||'if not o is null then utils.write_log(o,''G'',c,''DIARY_PARTITIONS-PARTITION(''||s); end if;'||LF
            ||'End;'||LF
             ,'CREATE TRIGGER DIARY_PARTITIONS_CHANGES');
  end if;
  if v_och is null then
    execute_sql('DROP PROCEDURE OCH_INS','DROP PROCEDURE OCH_INS',true);
  else
    exec_sql('CREATE OR REPLACE PROCEDURE OCH_INS(P_OWNER VARCHAR2,P_ID NUMBER,P_OBJ_ID VARCHAR2,P_COLLECTION_ID NUMBER,P_AUDSID NUMBER,P_USER_ID VARCHAR2,P_CLASS_ID VARCHAR2 DEFAULT NULL,P_OBJ_PARENT VARCHAR2 DEFAULT NULL) AS'||LF
            ||'begin'||LF||substr(v_och,4)
            ||'else utils.error(''OWNER_NOT_REGISTERED'',P_OWNER); end if;'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE OCH_INS');
  end if;
  if v_edh is null then
    execute_sql('DROP PROCEDURE EDH_INS','DROP PROCEDURE EDH_INS',true);
  else
    exec_sql('CREATE OR REPLACE PROCEDURE EDH_INS(P_OWNER VARCHAR2,P_ID NUMBER,P_OBJ_ID VARCHAR2,P_CLASS_ID VARCHAR2,P_AUDSID NUMBER,P_USER_ID VARCHAR2,P_TYPE_ID VARCHAR2,P_CODE VARCHAR2,P_TEXT VARCHAR2) AS'||LF
            ||'begin'||LF||substr(v_edh,4)
            ||'else utils.error(''OWNER_NOT_REGISTERED'',P_OWNER); end if;'||LF
            ||'end;'||LF
             ,'CREATE PROCEDURE EDH_INS');
  end if;
end;
--
function tableexists(p_table varchar2) return boolean is
    c number;
begin
    select count(1) into c from user_tables where table_name = p_table;
    return (c = 1);
end;
--
procedure del_owner(p_owner varchar2,p_only_grants boolean default true,p_data boolean default false) is
    n   number;
    x   number;
    s   varchar2(200);
    v_owner varchar2(30);
begin
    if aud_init then init; end if;
    v_owner := p_owner;
    select count(1) into n from owners where owner=v_owner and rownum<2;
    if n=0 then
      begin
        select owner into v_owner
          from owners where schema_owner=p_owner and rownum<2;
        x := 1;
      exception when no_data_found then
        return;
      end;
    else
      x := 0;
    end if;
    if n+x>0 then
      FOR c IN (SELECT --+ RULE
                       p.Table_Name,p.Privilege,o.schema_owner
                  FROM All_Tab_Privs p, owners o
                 WHERE p.Grantor = Aud_Owner AND p.Grantee = o.schema_owner
                   AND o.owner=v_owner and (x=0 or o.schema_owner=p_Owner)
      ) LOOP
        s := 'REVOKE '||c.Privilege||' ON '||Aud_Owner||'.'||c.Table_Name|| ' FROM '|| c.schema_owner;
        exec_sql(s,s);
      END LOOP;
      if p_data or not p_only_grants then
        n := nvl(get_interval(v_owner,'VERSION'),3.4);
        if not p_data then
          write_log(v_owner,'U','AUDIT',get_msg('OWNER_DELETED',p_owner));
        end if;
        if x>0 then
          delete owners where owner=v_owner and schema_owner=p_owner;
        else
          delete settings where owner=p_owner;
          put_line('Deleted '||sql%rowcount||' settings for '||p_owner);
          delete owners where owner=p_owner;
        end if;
        put_line('Deleted '||sql%rowcount||' owners for '||v_owner);
        commit;
        if n>=5.4 then
          create_procedures;
        end if;
      end if;
    end if;
    if p_data and x=0 then
      for c in (
        select diary_suffix from diary_tables t1
         where owner=p_owner and not exists
               (select 1 from diary_tables t2 where t2.owner=upper(p_owner)
                   and t1.owner<>t2.owner and t2.diary_type=t1.diary_type)
      ) loop
        s := upper(p_owner||'_'||c.diary_suffix);
        if tableexists(s) then
          s := 'DROP TABLE '||s;
          exec_sql(s,s);
        end if;
      end loop;
      delete diary_partitions where owner=p_owner;
      put_line('Deleted '||sql%rowcount||' rows from diary_partitions for '||p_owner);
      delete diary_indexes where owner=p_owner;
      put_line('Deleted '||sql%rowcount||' rows from diary_indexes for '||p_owner);
      delete diary_tables where owner=p_owner;
      put_line('Deleted '||sql%rowcount||' rows from diary_tables for '||p_owner);
      commit;
    end if;
end;
-----------------------------------------------------
-- Diary tables management (Internals)
-----------------------------------------------------
function get_partition(p_end boolean) return varchar2 is
begin
    if p_end then
        return 'P99';
    else
        return 'P00';
    end if;
end get_partition;
--
function get_name(p_step_type varchar2, p_date date) return varchar2 is
begin
    if p_step_type = 'Q' then
        return chr(ascii('A') + to_number(to_char(p_date, 'Q')) - 1);
    else
        return to_char(p_date, 'MM');
    end if;
end;
function get_partition(p_step_type varchar2, p_date date) return varchar2 is
begin
    return 'P' || to_char(p_date - 1, 'YY') || '_' ||  get_name(p_step_type, p_date - 1);
end get_partition;
--
procedure get_tablespaces(p_owner varchar2, p_step_type varchar2, p_step pls_integer,
                          p_tablespace out nocopy varchar2, p_idx_tablespace out nocopy varchar2) is
begin
  select tablespace_name, idx_tablespace_name into p_tablespace, p_idx_tablespace
    from diary_partitions
   where diary_step = p_step_type and step_number = p_step and owner = p_owner;
exception when no_data_found then
  p_tablespace := null;
  p_idx_tablespace := null;
end get_tablespaces;
--
function get_tablespace(p_owner varchar2, p_step_type varchar2, p_step pls_integer,
                        p_tablespace out nocopy varchar2, p_idx boolean := false) return boolean is
  v_tab varchar2(100);
  v_idx varchar2(100);
begin
  get_tablespaces(p_owner,p_step_type,p_step,v_tab,v_idx);
  if p_idx then
    v_tab := v_idx;
  end if;
  p_tablespace := v_tab;
  return not v_tab is null;
end get_tablespace;
--
function get_number(p_step_type varchar2, p_date date) return pls_integer is
begin
    if p_step_type = 'Q' then
        return to_number(to_char(p_date, 'Q'));
    else
        return to_number(to_char(p_date, 'MM'));
    end if;
end get_number;
function get_tablespace(p_owner varchar2, p_step_type varchar2, p_date date, p_tablespace out nocopy varchar2, p_idx boolean := false) return boolean is
begin
    return get_tablespace(p_owner, p_step_type, get_number(p_step_type, p_date - 1), p_tablespace, p_idx);
end get_tablespace;
--
function get_max_date(p_table varchar2,p_partition varchar2,p_where varchar2 default null) return date is
    d date;
    v_tbl varchar2(100);
begin
    if p_partition is null then
      v_tbl := p_table;
    else
      v_tbl := p_table||' partition('||p_partition||')';
    end if;
    execute immediate 'select max(time) from '||v_tbl||p_where into d;
    return d;
exception when others then
    error('EXEC_ERROR','Can not evaluate max(time) in '||v_tbl||LF||'error: ' || sqlerrm);
end;
--
function stmt_to_date(stmt varchar2) return date is
    high_value date;
begin
    execute immediate 'select ' || stmt || ' from dual' into high_value;
    return high_value;
exception when others then
    error('EXEC_ERROR','Can not execute high_value stmt to get date.' || LF ||
        'stmt: ' || stmt || '.'|| LF || 'error: ' || sqlerrm);
end stmt_to_date;
--
procedure table_partitions(p_table varchar2,
                           p_part in out nocopy varchar2,
                           p_degr in out nocopy varchar2) is
begin
    select partitioned,degree into p_part, p_degr
      from user_tables where table_name = p_table;
exception when NO_DATA_FOUND then
    error('EXEC_ERROR','Table ' ||p_table|| ' does not exist');
end;
--
procedure check_table(owner varchar2, tab_type pls_integer, must_exist boolean,
                      tab_rec  in out nocopy diary_tables%ROWTYPE, p_check_part boolean default true) is
    v_part  varchar2(10);
    v_degr  varchar2(30);
begin
    begin
      select * into tab_rec from diary_tables where diary_type = tab_type and owner = check_table.owner;
    exception when NO_DATA_FOUND then
      error('EXEC_ERROR','Can not find diary info for type: ' || tab_type);
    end;
    tab_rec.owner := upper(tab_rec.owner);
    tab_rec.diary_suffix := upper(tab_rec.diary_suffix);
    tab_rec.diary_step := upper(nvl(tab_rec.diary_step,'M'));
    if must_exist then
      table_partitions(tab_rec.owner||'_'||tab_rec.diary_suffix,v_part,v_degr);
      if p_check_part and v_part <> 'YES' then
        error('EXEC_ERROR','Table ' ||
            tab_rec.owner || '_' || tab_rec.diary_suffix || ' is not partitioned');
      end if;
    end if;
end check_table;
--
procedure get_storage(query in out nocopy varchar2, p_tspace varchar2,
                      p_init varchar2, p_next varchar2, p_lists varchar2, p_idx boolean) is
begin
  if p_idx then
    query := query|| '  pctfree 0 initrans 2 maxtrans 255';
  else
    query := query|| '  pctfree 0 pctused 50 initrans 1 maxtrans 255';
  end if;
  if not p_tspace is null then
    query := query  || ' tablespace ' || p_tspace || ' ';
  end if;
  query := query  || LF || '  storage (';
  if not p_init is null then
    query := query  || 'initial ' || p_init || ' ';
  end if;
  if not p_next is null then
    query := query  || 'next ' || p_next || ' ';
  end if;
  if not p_lists is null then
    query := query  || 'freelists ' || p_lists || ' ';
  end if;
  query := query  || 'minextents 1 maxextents UNLIMITED pctincrease 0)' || LF;
end;
--
procedure find_index(p_rec in out nocopy diary_indexes%rowtype, p_owner varchar2, p_type pls_integer, p_name varchar2) is
begin
  select * into p_rec from diary_indexes
   where owner=p_owner and diary_type=p_type
     and substr(p_name,instr(p_name,index_suffix,-1))=index_suffix;
exception when no_data_found then
  p_rec := null;
end;
--
procedure check_paral(p_owner varchar2) is
begin
  if cur_owner = p_owner then
    return;
  end if;
  cur_owner := p_owner;
  cur_paral := force_parallel(p_owner);
  if cur_paral>0 then
    if use_paral then
      use_paral := false;
      execute immediate 'alter session enable parallel ddl';
    end if;
  end if;
end;
--
procedure rebuild_indexes(tab_rec diary_tables%ROWTYPE,start_date date) is
    query varchar2(32767);
    idx_tablespace_name varchar2(100);
    v_rec    diary_indexes%rowtype;
    v_table  varchar2(100);
    v_date   date;
    v_step   pls_integer;
begin
  v_table := tab_rec.owner || '_' || tab_rec.diary_suffix;
  check_paral(tab_rec.owner);
  for idx_rec in (select index_name, status, partitioned,
                         decode(ltrim(degree),'1','0','DEFAULT','1',ltrim(degree)) paral
                    from user_indexes where table_name=v_table
  ) loop
    if to_char(cur_paral)<>idx_rec.paral then
      query := 'alter index '|| idx_rec.index_name;
      if cur_paral>0 then
        query := query||' parallel';
        if cur_paral>1 then
          query := query||' '||cur_paral;
        end if;
      else
        query := query||' noparallel';
      end if;
      exec_sql(query,query);
    end if;
    if idx_rec.partitioned='YES' then
      for prt_rec in (select partition_name, high_value, status
                        from user_ind_partitions
                       where index_name=idx_rec.index_name
      ) loop
          if lower(prt_rec.high_value) = 'maxvalue' then
            if tab_rec.diary_step='Q' then
              v_step := 5;
            else
              v_step := 13;
            end if;
            v_date := start_date+1;
          else
            v_date := stmt_to_date(prt_rec.high_value);
            if prt_rec.partition_name=get_partition(false) then
              v_step := 0;
            else
              v_step := get_number(tab_rec.diary_step,v_date-1);
            end if;
          end if;
          if prt_rec.status<>'USABLE' or start_date<v_date then
            get_tablespaces(tab_rec.owner,tab_rec.diary_step,v_step,v_rec.owner,idx_tablespace_name);
            find_index(v_rec,tab_rec.owner,tab_rec.diary_type,idx_rec.index_name);
            query := 'alter index ' || idx_rec.index_name || ' rebuild partition ' || prt_rec.partition_name||LF;
            get_storage(query,idx_tablespace_name,v_rec.storage_initial,v_rec.storage_next,tab_rec.storage_freelists,true);
            --query := query||'  compute statistics';
            exec_sql(query, 'Altering partition ' || prt_rec.partition_name
                || ' of index ' || idx_rec.index_name);
          end if;
      end loop;
	elsif idx_rec.status<>'USABLE' or start_date<sysdate or tab_rec.diary_type = OSH then
      query := 'alter index ' || idx_rec.index_name || ' rebuild';
      find_index(v_rec,tab_rec.owner,tab_rec.diary_type,idx_rec.index_name);
      get_storage(query,tab_rec.idx_tablespace_name,v_rec.storage_initial,v_rec.storage_next,tab_rec.storage_freelists,true);
      --query := query||'  compute statistics';
	  --PLATFORM-1835
	  if tab_rec.diary_type = OSH then
	  	query := query || ' reverse';
	  end if;
      exec_sql(query, 'Altering index ' || idx_rec.index_name);
    end if;
  end loop;
end rebuild_indexes;
-----------------------------------------------------
-- Diary tables management (Interface)
-----------------------------------------------------
function table_exists(owner varchar2, tab_type pls_integer) return boolean is
    v_tbl varchar2(100);
begin
    v_tbl := table_name(owner,tab_type,true);
    return tableexists(v_tbl);
end table_exists;
--
function table_partitioned(owner varchar2, tab_type pls_integer) return boolean is
    v_part  varchar2(10);
    v_degr  varchar2(30);
begin
    table_partitions(table_name(owner,tab_type,true),v_part,v_degr);
    return v_part = 'YES';
end table_partitioned;
--
function get_diary_step(p_owner varchar2, p_code pls_integer) return varchar2 is
  tab_rec diary_tables%ROWTYPE;
begin
  check_table(p_owner, p_code, false, tab_rec);
  return tab_rec.diary_step;
end get_diary_step;
--
procedure get_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace out nocopy varchar2, p_idx_tablespace out nocopy varchar2) is
  tab_rec diary_tables%ROWTYPE;
begin
  check_table(p_owner, p_code, false, tab_rec);
  if p_step is null then
    p_tablespace := tab_rec.tablespace_name;
    p_idx_tablespace := tab_rec.idx_tablespace_name;
  else
    get_tablespaces(tab_rec.owner,tab_rec.diary_step,p_step,p_tablespace,p_idx_tablespace);
  end if;
end get_tablespaces;
--
procedure set_tablespaces(p_owner in varchar2, p_code in pls_integer, p_step in pls_integer,
                          p_tablespace in varchar2, p_idx_tablespace in varchar2) is
  tab_rec diary_tables%ROWTYPE;
begin
  check_table(p_owner, p_code, false, tab_rec);
  if p_step is null then
    update diary_tables set tablespace_name=p_tablespace, idx_tablespace_name=p_idx_tablespace
     where diary_type = p_code and owner = p_owner;
  else
    update diary_partitions set tablespace_name=p_tablespace, idx_tablespace_name=p_idx_tablespace
     where diary_step = tab_rec.diary_step and step_number = p_step and owner = p_owner;
  end if;
end set_tablespaces;
--
procedure get_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent out nocopy varchar2, p_next_extent out nocopy varchar2) is
  tab_rec diary_tables%ROWTYPE;
begin
  check_table(p_owner, p_code, false, tab_rec);
  if p_idx then
    select storage_initial, storage_next into p_initial_extent, p_next_extent
      from diary_indexes where owner=p_owner and diary_type=p_code and rownum=1;
  else
    p_initial_extent := tab_rec.storage_initial;
    p_next_extent := tab_rec.storage_next;
  end if;
exception when no_data_found then
  p_initial_extent := null;
  p_next_extent := null;
end;
--
procedure set_extents(p_owner in varchar2, p_code in pls_integer, p_idx boolean,
                      p_initial_extent varchar2, p_next_extent varchar2) is
  tab_rec diary_tables%ROWTYPE;
begin
  check_table(p_owner, p_code, false, tab_rec);
  if p_idx then
    update diary_indexes set
      storage_initial = p_initial_extent,
      storage_next = p_next_extent
     where owner=p_owner and diary_type=p_code;
  else
    update diary_tables set
      storage_initial = p_initial_extent,
      storage_next = p_next_extent
     where owner=p_owner and diary_type=p_code;
  end if;
end;
--
function get_end_date(owner varchar2, p_code pls_integer) return date is
  tab_rec diary_tables%ROWTYPE;
  table_name varchar2(100);
begin
  check_table(owner, p_code, true, tab_rec);
  table_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
  for part_rec in (select partition_name, high_value, partition_position
                     from user_tab_partitions
                    where table_name = get_end_date.table_name
                    order by partition_position desc) loop
      if lower(part_rec.high_value) <> 'maxvalue' then
          return stmt_to_date(part_rec.high_value);
      end if;
  end loop;
  return null;
end get_end_date;
--
procedure nearest_trunc_date(owner varchar2, tab_type pls_integer, date_to in out nocopy date) is
    tab_rec diary_tables%ROWTYPE;
    table_name varchar2(100);
    real_date_to date;
begin
    if date_to <= trunc(sysdate) - MAX_INTERVAL then
        return;
    end if;
    check_table(owner, tab_type, true, tab_rec);
    table_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
    for part_rec in (select partition_name, high_value, partition_position
                        from user_tab_partitions
                        where table_name = nearest_trunc_date.table_name
                        order by partition_position desc) loop
        if lower(part_rec.high_value) <> 'maxvalue' then
            real_date_to := stmt_to_date(part_rec.high_value);
            if real_date_to <= date_to then
                date_to := real_date_to;
                return;
            end if;
        end if;
    end loop;
    date_to := trunc(sysdate) - MAX_INTERVAL;
end nearest_trunc_date;
--
procedure create_table(owner varchar2, tab_type pls_integer, start_date date, end_date date,
                       p_table_name varchar2 default null) is
    query varchar2(32767);
    table_name varchar2(100);
    tablespace_name varchar2(100);
    cur_date date;
    step pls_integer;
    end_step pls_integer;
    tab_rec diary_tables%ROWTYPE;
    part_rec diary_partitions%ROWTYPE;
begin
    check_table(owner, tab_type, false, tab_rec);
    check_paral(owner);
    cur_date := nvl(start_date, sysdate);
    if tab_rec.diary_step = 'Q' then
        cur_date := trunc(cur_date, 'Q');
        step := 3;
        end_step := 5;
    else
        cur_date := trunc(cur_date, 'MM');
        step := 1;
        end_step := 13;
    end if;
    if p_table_name is null then
      table_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
    else
      table_name := p_table_name;
    end if;
    query := 'create table ' || table_name || LF||
        '  (' || upper(tab_rec.diary_fields) || ')'|| LF;
    get_storage(query,tab_rec.tablespace_name,tab_rec.storage_initial,tab_rec.storage_next,tab_rec.storage_freelists,false);
    if AudPartitions then
      query := query  ||
          '  partition by range (TIME) (' || LF ||
          '    partition ' || get_partition(false) || ' values less than (to_date(''' || to_char(cur_date, 'DD/MM/YYYY') || ''', ''DD/MM/YYYY''))';
      if get_tablespace(owner, tab_rec.diary_step, 0, tablespace_name) then
          query := query  || LF || '      tablespace ' || tablespace_name;
      end if;
      query := query  || ',' || LF;
      cur_date := add_months(cur_date, step);
      while cur_date <= end_date loop
          query := query  || '    partition ' || get_partition(tab_rec.diary_step, cur_date) || ' values less than (to_date(''' || to_char(cur_date, 'DD/MM/YYYY') || ''', ''DD/MM/YYYY''))';
          if get_tablespace(owner, tab_rec.diary_step, cur_date, tablespace_name) then
              query := query || LF || '      tablespace ' || tablespace_name;
          end if;
          query := query  || ',' || LF;
          cur_date := add_months(cur_date, step);
      end loop;
      query := query  || '    partition ' || get_partition(true) || ' values less than (maxvalue)' || LF;
      if get_tablespace(owner, tab_rec.diary_step, end_step, tablespace_name) then
          query := query  || '      tablespace ' || tablespace_name || LF;
      end if;
      query := query  || '  )' || LF;
    end if;
    if cur_paral>0 then
      query := query||' parallel';
      if cur_paral>1 then
        query := query||' '||cur_paral;
      end if;
    else
      query := query||' noparallel';
    end if;
    execute_sql(query, 'Creating table ' || table_name);
end create_table;
--
procedure upgrade_table(owner varchar2, tab_type pls_integer) is
    tab_rec diary_tables%ROWTYPE;
    tab_name varchar2(100);
    col varchar2(300);
    typ varchar2(100);
    col_name varchar2(100);
    i   pls_integer;
    pos pls_integer;
    old_pos pls_integer := 1;
begin
    check_table(owner, tab_type, false, tab_rec);
    tab_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
    table_partitions(tab_name,col,typ);
    check_paral(owner);
    typ := ltrim(typ);
    if typ='DEFAULT' then typ:='1';
    elsif typ='1' then typ:='0'; end if;
    if typ<>to_char(cur_paral) then
      col := 'alter table '||tab_name;
      if cur_paral>0 then
        col := col||' parallel';
        if cur_paral>1 then
          col := col||' '||cur_paral;
        end if;
      else
        col := col||' noparallel';
      end if;
      exec_sql(col,col);
    end if;
    loop
      pos := instr(tab_rec.diary_fields, ',', old_pos);
      if pos > 0 then
        col := trim(substr(tab_rec.diary_fields, old_pos, pos - old_pos));
      else
        col := trim(substr(tab_rec.diary_fields, old_pos));
      end if;
      i := instr(col, ' ');
      if substr(col, 1, 1) = '"' then
        col_name := substr(col, 2, instr(col, 2, '"') - 1);
      else
        col_name := upper(substr(col, 1, i - 1));
      end if;
      col := upper(substr(col, i + 1 ));
      typ := get_column_type(tab_name,col_name,'1');
      if typ is null then
        exec_sql('alter table '||tab_name||' add '||col_name||' '||col,
                    'Adding column ' || col_name || ' to table ' || tab_name);
      else
        if typ like 'TIMESTAMP%' then
          col := replace(col,'(6)');
          typ := replace(typ,'(6)');
        end if;
        if replace(col,' ')<>replace(typ,' ') then
          exec_sql('alter table '||tab_name||' modify '||col_name||' '||col,
                      'Changing column ' || col_name || ' of table ' || tab_name);
        end if;
      end if;
      exit when pos <= 0;
      old_pos := pos + 1;
    end loop;
end upgrade_table;
--
function check_table_columns(owner varchar2, tab_type pls_integer) return varchar2 is
    tab_rec diary_tables%ROWTYPE;
    tab_name varchar2(100);
    col varchar2(300);
    col_name varchar2(100);
    col_type varchar2(100);
    old_type varchar2(100);
    i   pls_integer;
    pos pls_integer;
    old_pos pls_integer := 1;
    v_ret   varchar2(1000);
    v_upgrade boolean;
    v_part    boolean;
begin
    v_part := utils.table_partitioned(owner, tab_type);
    v_upgrade := v_part=AudPartitions;
    check_table(owner, tab_type, false, tab_rec);
    tab_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
    loop
      pos := instr(tab_rec.diary_fields, ',', old_pos);
      if pos > 0 then
        col := trim(substr(tab_rec.diary_fields, old_pos, pos - old_pos));
      else
        col := trim(substr(tab_rec.diary_fields, old_pos));
      end if;
      i := instr(col, ' ');
      if substr(col, 1, 1) = '"' then
        col_name := substr(col, 2, instr(col, 2, '"') - 1);
      else
        col_name := upper(substr(col, 1, i - 1));
      end if;
      col_type := upper(substr(col, i + 1));
      if col_name='TIME' then
        col_type := replace(replace(col_type,' '),'(6)');
        old_type := replace(replace(get_column_type(tab_name,col_name,'1'),' '),'(6)');
        if not old_type is null then
          v_ret:= v_ret||col_name||',';
        end if;
        v_upgrade:= v_upgrade and (col_type like old_type||'%' or (old_type='DATE' and col_type='TIMESTAMP' and not v_part));
      else
        old_type := get_column_type(tab_name,col_name);
        if not old_type is null then
          v_ret:= v_ret||col_name||',';
        end if;
        v_upgrade:= v_upgrade and col_type like old_type||'%';
      end if;
      exit when pos <= 0;
      old_pos := pos + 1;
    end loop;
    if v_upgrade then
      v_ret:= null;
    end if;
    return rtrim(v_ret,',');
end check_table_columns;
--
procedure create_indexes(owner varchar2, tab_type pls_integer) is
    query varchar2(32767);
    tab_rec diary_tables%ROWTYPE;
    idx_tablespace_name varchar2(100);
    table_name varchar2(100);
    index_name varchar2(100);
    end_step  pls_integer;
    do_create boolean;
begin
    check_table(owner, tab_type, true, tab_rec, false);
    check_paral(owner);
    table_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
    if tab_rec.diary_step = 'Q' then
        end_step := 5;
    else
        end_step := 13;
    end if;
    for idx_rec in (select * from diary_indexes where diary_type = tab_type and owner = create_indexes.owner) loop
        if idx_rec.is_unique = 'T' then
            index_name := 'UNQ_';
        else
            index_name := 'IDX_';
        end if;
        index_name := index_name || table_name || '_' || idx_rec.index_suffix;
        do_create := true;
        for idx in (select partitioned from user_indexes
            where index_name = create_indexes.index_name)
        loop
            if AudPartitions and idx.partitioned='YES' or not AudPartitions and idx.partitioned<>'YES' then
                do_create := false;
            else
                execute immediate 'drop index ' || index_name;
            end if;
        end loop;
        if do_create then
            query := 'create ';
            if idx_rec.is_unique = 'T' then
                query := query || 'unique index ';
            else
                query := query || 'index ';
            end if;
            query := query || index_name
                || ' on ' || table_name || '(' || upper(idx_rec.index_fields) || ')'|| LF;
            get_storage(query,tab_rec.idx_tablespace_name,idx_rec.storage_initial,idx_rec.storage_next,tab_rec.storage_freelists,true);
            if AudPartitions then
              query := query  || '  local (' || LF;
              for part_rec in (select partition_name, high_value
                                  from user_tab_partitions
                                  where table_name = create_indexes.table_name
                                  order by partition_position) loop
                  query := query || '    partition ' || part_rec.partition_name;
                  if lower(part_rec.high_value) = 'maxvalue' then
                      if get_tablespace(owner, tab_rec.diary_step, end_step, idx_tablespace_name, true) then
                          query := query || ' tablespace ' || idx_tablespace_name;
                      end if;
                   elsif part_rec.partition_name = get_partition(false) then
                      if get_tablespace(owner, tab_rec.diary_step, 0, idx_tablespace_name, true) then
                          query := query || ' tablespace ' || idx_tablespace_name;
                      end if;
                  else
                      if get_tablespace(owner, tab_rec.diary_step, stmt_to_date(part_rec.high_value), idx_tablespace_name, true) then
                          query := query || ' tablespace ' || idx_tablespace_name;
                      end if;
                  end if;
                  query := query || ',' || LF;
              end loop;
              query := substr(query, 1, length(query) - 2) || ')';
            end if;
            if cur_paral>0 then
              query := query||' parallel';
              if cur_paral>1 then
                query := query||' '||cur_paral;
              end if;
            else
              query := query||' noparallel';
            end if;
			--PLATFORM-1835
			if tab_rec.diary_type = OSH then
				query := query || ' reverse';
			end if;
            exec_sql(query, 'Creating index '
               || table_name || '_' || upper(idx_rec.index_suffix));
        end if;
    end loop;
end create_indexes;
--
procedure drop_indexes(owner varchar2, tab_type pls_integer) is
    tab_rec diary_tables%ROWTYPE;
    v_idx   dbms_sql.varchar2s;
    query   varchar2(100);
    v_table varchar2(100);
begin
    check_table(owner, tab_type, true, tab_rec, false);
    v_table := tab_rec.owner || '_' || tab_rec.diary_suffix;
    select index_name bulk collect into v_idx
      from user_indexes where table_name=v_table;
    for i in 1..v_idx.count loop
      query := 'DROP INDEX '||v_idx(i);
      exec_sql(query,query);
    end loop;
end;
--
procedure add_partitions(owner varchar2, tab_type pls_integer, end_date date,
                         p_table out nocopy varchar2, p_ok_parts out nocopy varchar2) is
    query varchar2(2000);
    tab_rec diary_tables%ROWTYPE;
    tablespace_name varchar2(100);
    idx_tablespace_name varchar2(100);
    last_partition_name varchar2(100);
    v_table varchar2(100);
    v_part  varchar2(100);
    v_degr  varchar2(30);
    start_date date;
    cur_date date;
    v_step  pls_integer;
    v_parts varchar2(4000);
    step pls_integer;
begin
    check_table(owner, tab_type, false, tab_rec);
    v_table := tab_rec.owner || '_' || tab_rec.diary_suffix;
    p_table := v_table;  
    table_partitions(v_table,v_part,v_degr);
    if v_part <> 'YES' then
      error('EXEC_ERROR','Table ' || v_table || ' is not partitioned');
    end if;
    check_paral(owner);
    v_degr := ltrim(v_degr);
    if v_degr='DEFAULT' then v_degr:='1';
    elsif v_degr='1' then v_degr:='0'; end if;
    if v_degr<>to_char(cur_paral) then
      query := 'alter table '||v_table;
      if cur_paral>0 then
        query := query||' parallel';
        if cur_paral>1 then
          query := query||' '||cur_paral;
        end if;
      else
        query := query||' noparallel';
      end if;
      exec_sql(query,query);
    end if;
    for part_rec in (select partition_name, high_value from user_tab_partitions
                        where table_name = v_table
                        order by partition_position desc) loop
        if lower(part_rec.high_value) <> 'maxvalue' then
            start_date := stmt_to_date(part_rec.high_value);
            exit;
        end if;
        last_partition_name := part_rec.partition_name;
    end loop;
    cur_date := nvl(start_date, sysdate);
    if tab_rec.diary_step = 'Q' then
        cur_date := trunc(cur_date, 'Q');
        step := 3;
    else
        cur_date := trunc(cur_date, 'MM');
        step := 1;
    end if;
    if not start_date is null then
        cur_date := add_months(cur_date, step);
    end if;
    if last_partition_name is null then
        start_date := null;
        while cur_date <= end_date loop
            v_part:= get_partition(tab_rec.diary_step, cur_date);
            query := 'alter table ' || v_table || ' add partition ' || v_part ||
                ' values less than (to_date(''' || to_char(cur_date, 'DD/MM/YYYY') || ''', ''DD/MM/YYYY''))'||LF;
            v_step := get_number(tab_rec.diary_step,cur_date);
            get_tablespaces(tab_rec.owner,tab_rec.diary_step,v_step,tablespace_name,idx_tablespace_name);
            get_storage(query,tablespace_name,tab_rec.storage_initial,tab_rec.storage_next,tab_rec.storage_freelists,false);
            execute_sql(query, 'Adding partition '||v_table||'.'||v_part);
            v_parts := v_parts||', '||v_part;
            if start_date is null then
              start_date := cur_date;
            end if;
            cur_date:= add_months(cur_date, step);
        end loop;
        last_partition_name := get_partition(true);
        query := 'alter table '||v_table||' add partition '||last_partition_name||
            ' values less than maxvalue'||LF;
        get_storage(query,tab_rec.tablespace_name,tab_rec.storage_initial,tab_rec.storage_next,tab_rec.storage_freelists,false);
        execute_sql(query, 'Adding partition '||v_table||'.'||last_partition_name);
        v_parts := v_parts||', '||last_partition_name;
    else
        start_date := get_max_date(v_table,last_partition_name);
        if not start_date is null then
          if tab_rec.diary_step = 'Q' then
            cur_date := add_months(trunc(start_date,'Q'),3);
          else
            cur_date := add_months(trunc(start_date,'MM'),1);
          end if;
        end if;
        start_date := null;
        while cur_date <= end_date loop
            v_part:= get_partition(tab_rec.diary_step, cur_date);
            query := 'alter table ' || v_table ||
                ' split partition ' || last_partition_name || LF ||
                ' at (to_date(''' || to_char(cur_date, 'DD/MM/YYYY') || ''', ''DD/MM/YYYY''))' || LF || ' into (';
            query := query  || 'partition ' || v_part;
            v_step := get_number(tab_rec.diary_step,cur_date);
            get_tablespaces(tab_rec.owner,tab_rec.diary_step,v_step,tablespace_name,idx_tablespace_name);
            get_storage(query,tablespace_name,tab_rec.storage_initial,tab_rec.storage_next,tab_rec.storage_freelists,false);
            query := query || ', partition ' || last_partition_name || LF;
            get_storage(query,tab_rec.tablespace_name,tab_rec.storage_initial,tab_rec.storage_next,tab_rec.storage_freelists,false);
            query := query || ')';
            execute_sql(query, 'Splitting partition '||v_table||'.'||last_partition_name||' to '
               || v_part || ' and ' || last_partition_name);
            v_parts := v_parts||', '||v_part;
            if start_date is null then
              start_date := cur_date;
            end if;
            cur_date:= add_months(cur_date, step);
        end loop;
    end if;
    rebuild_indexes(tab_rec,start_date-1);
    p_ok_parts := substr(v_parts,3);
end add_partitions;
--
procedure delete_data(p_table varchar2, p_date date,  p_nrows pls_integer,
                      p_count out nocopy pls_integer, p_error out nocopy varchar2) is
  s varchar2(2000);
  c integer;
  m pls_integer;
  n pls_integer;
begin
  m := 0;
  c := dbms_sql.open_cursor;
  dbms_sql.parse(c,'delete '||p_table||' where time<:d and rownum<=:n',dbms_sql.native);
  dbms_sql.bind_variable(c, ':d', p_date);
  dbms_sql.bind_variable(c, ':n', p_nrows);
  loop
    n := dbms_sql.execute(c);
    m := m + n;
    commit;
    exit when n < p_nrows;
  end loop;
  dbms_sql.close_cursor(c);
  p_count := m;
exception when others then
  p_error := sqlerrm;
  rollback;
  if dbms_sql.is_open(c) then
    dbms_sql.close_cursor(c);
  end if;
end;
--
procedure truncate_partitions(owner varchar2, tab_type pls_integer, date_to date,
                              p_table out nocopy varchar2, p_ok_parts out nocopy varchar2, p_faild_parts out nocopy varchar2) is
    query varchar2(200);
    tab_rec diary_tables%ROWTYPE;
    table_name varchar2(100);
begin
    check_table(owner, tab_type, true, tab_rec);
    table_name := tab_rec.owner || '_' || tab_rec.diary_suffix;
    for part_rec in (select partition_name, high_value
                        from user_tab_partitions
                        where table_name = truncate_partitions.table_name
                        order by partition_position desc) loop
        if lower(part_rec.high_value) <> 'maxvalue' and stmt_to_date(part_rec.high_value) <= date_to then
          if not get_max_date(table_name,part_rec.partition_name,' where rownum=1') is null then
            query := 'alter table ' || table_name || ' truncate partition ' || part_rec.partition_name||' drop storage';
            begin
              execute_sql(query, 'Truncating partition ' ||
                          part_rec.partition_name || ' of ' || table_name);
              if not p_ok_parts is null then
                p_ok_parts := p_ok_parts || ', ';
              end if;
              p_ok_parts := p_ok_parts || part_rec.partition_name;
            exception when others then
              if not p_faild_parts is null then
                p_faild_parts := p_faild_parts || ', ';
              end if;
              p_faild_parts := p_faild_parts || part_rec.partition_name;
            end;
          end if;
        end if;
    end loop;
    p_table := table_name;
end truncate_partitions;
--
procedure drop_partitions(owner varchar2, tab_type pls_integer, date_to date,
                          p_table out nocopy varchar2, p_ok_parts out nocopy varchar2, p_faild_parts out nocopy varchar2) is
    query varchar2(200);
    tab_rec diary_tables%ROWTYPE;
    idx pls_integer;
    v_parts dbms_sql.varchar2s;
    v_table varchar2(100);
begin
    check_table(owner, tab_type, true, tab_rec);
    idx := 0;
    v_table := tab_rec.owner || '_' || tab_rec.diary_suffix;
    for part_rec in (select partition_name, high_value
                       from user_tab_partitions
                      where table_name = v_table
                      order by partition_position) loop
      if lower(part_rec.high_value) <> 'maxvalue' then
        if stmt_to_date(part_rec.high_value) <= date_to then
          idx := idx+1;
          v_parts(idx) := part_rec.partition_name;
        else
          exit;
        end if;
      end if;
    end loop;
    for i in 1..idx loop
      begin
        if i<idx then
          query := 'alter table ' || v_table || ' drop partition ' || v_parts(i);
          execute_sql(query, 'Dropping partition ' ||v_parts(i)||' of '||v_table);
        else
          query := 'alter table ' || v_table || ' truncate partition ' || v_parts(i)||' drop storage';
          execute_sql(query, 'Truncating partition ' ||v_parts(i)||' of '||v_table);
        end if;
        if not p_ok_parts is null then
          p_ok_parts := p_ok_parts || ', ';
        end if;
        p_ok_parts := p_ok_parts || v_parts(i);
      exception when others then
        if not p_faild_parts is null then
          p_faild_parts := p_faild_parts || ', ';
        end if;
        p_faild_parts := p_faild_parts || v_parts(i);
      end;
    end loop;
    if idx>0 and p_faild_parts is null and v_parts(idx)<>get_partition(false) then
      query := 'alter table ' || v_table || ' rename partition '||v_parts(idx)||' to '||get_partition(false);
      exec_sql(query,query);
    end if;
    p_table := v_table;
end;
--
procedure rebuild_indexes(owner varchar2, tab_type pls_integer, start_date date default null) is
    tab_rec diary_tables%ROWTYPE;
begin
    check_table(owner, tab_type, true, tab_rec, false);
    rebuild_indexes(tab_rec, start_date);
end rebuild_indexes;
--
procedure reset_message (p_topic varchar2, p_code  varchar2) is
begin
  if p_topic is null or p_code is null then
    mes.delete;
  else
    mes.delete(p_topic||'.'||p_code);
  end if;
end;
--
function  set_message (p_topic varchar2, p_code  varchar2, p_text varchar2) return boolean is
  s varchar2(2000);
begin
  if p_topic is null or p_code is null then
    raise value_error;
  end if;
  reset_message(p_topic,p_code);
  if p_text is null then
    delete messages where topic = p_topic and code = p_code;
    return null;
  end if;
  s := replace(replace(p_text,CR),LF,'\n');
  update messages set text = s
   where topic = p_topic and code = p_code;
  if sql%notfound then
    insert into messages(topic,code,text)
    values(p_topic,p_code,s);
    return true;
  end if;
  return false;
end;
--
function  gettext ( p_topic varchar2,
                    p_code  varchar2,
                    p1      varchar2 default NULL,
                    p2      varchar2 default NULL,
                    p3      varchar2 default NULL,
                    p4      varchar2 default NULL,
                    p5      varchar2 default NULL,
                    p6      varchar2 default NULL,
                    p7      varchar2 default NULL,
                    p8      varchar2 default NULL,
                    p9      varchar2 default NULL
                  ) return varchar2 is
    s varchar2(8000);
begin
    s := p_topic||'.'||p_code;
    if mes.exists(s) then
      s := mes(s);
    else
      begin
        select /*+ INDEX(messages) */ text into s
          from messages
         where topic = p_topic and code = p_code;
      exception when NO_DATA_FOUND then
        s := null;
      end;
      if s is null then
        s := '%1 %2 %3 %4 %5 %6 %7 %8 %9';
      end if;
      mes(p_topic||'.'||p_code) := s;
    end if;
--
    s := replace(s,'\n',chr(10));
    s := replace(s,'%1',p1);
    s := replace(s,'%2',p2);
    s := replace(s,'%3',p3);
    s := replace(s,'%4',p4);
    s := replace(s,'%5',p5);
    s := replace(s,'%6',p6);
    s := replace(s,'%7',p7);
    s := replace(s,'%8',p8);
    s := replace(s,'%9',p9);
    return rtrim(s);
--
exception when VALUE_ERROR then
    return null;
end gettext;
--
function  get_text( p_topic varchar2,
                    p_code  varchar2,
                    p1      varchar2 default NULL,
                    p2      varchar2 default NULL,
                    p3      varchar2 default NULL,
                    p4      varchar2 default NULL,
                    p5      varchar2 default NULL,
                    p6      varchar2 default NULL,
                    p7      varchar2 default NULL,
                    p8      varchar2 default NULL,
                    p9      varchar2 default NULL
                  ) return varchar2 is
begin
  return p_topic||'-'||p_code||': '||gettext(p_topic,p_code,p1,p2,p3,p4,p5,p6,p7,p8,p9);
end get_text;
--
function get_msg(p_msg varchar2,
                 p1    varchar2 default NULL,
                 p2    varchar2 default NULL,
                 p3    varchar2 default NULL,
                 p4    varchar2 default NULL,
                 p5    varchar2 default NULL,
                 p6    varchar2 default NULL,
                 p7    varchar2 default NULL,
                 p8    varchar2 default NULL,
                 p9    varchar2 default NULL
                ) return varchar2 is
begin
  return gettext('MSG',p_msg,p1,p2,p3,p4,p5,p6,p7,p8,p9);
end get_msg;
--
procedure error( p_msg varchar2,
                 p1    varchar2 default NULL,
                 p2    varchar2 default NULL,
                 p3    varchar2 default NULL,
                 p4    varchar2 default NULL,
                 p5    varchar2 default NULL,
                 p6    varchar2 default NULL,
                 p7    varchar2 default NULL,
                 p8    varchar2 default NULL,
                 p9    varchar2 default NULL
                ) is
begin
  raise_application_error(-20999,get_text('MSG',p_msg,p1,p2,p3,p4,p5,p6,p7,p8,p9));
end;
--
function  get_error_stack(p_backtrace boolean default true) return varchar2 is
  l_err_stack varchar2(2000);
begin
  l_err_stack := dbms_utility.format_error_stack;
  if p_backtrace then
    return l_err_stack||dbms_utility.format_error_backtrace;
  end if;
  return l_err_stack;
end;    
--
end;
/
show err package body utils
