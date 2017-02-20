prompt aud_mgr body
create or replace
package body &&audmgr..aud_mgr is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUDM/aud2.sql $
 *  $Author: petrushov $
 *  $Revision: 93492 $
 *  $Date:: 2016-02-10 10:29:48 #$
 */
--
    READ_TIME_OUT constant pls_integer := 10;
    KEEP_HISTORY  constant pls_integer := 30;
    DEBUG_PIPE    constant varchar2(10):= 'AUD_MGR';
    VERSION       constant varchar2(15):= 'Version 9.4';
    DAY_DATE      constant varchar2(15):= 'DD/MM/YYYY';
    TIME_DATE     constant varchar2(15):= 'HH24:MI:SS ';
    FULL_DATE     constant varchar2(25):= 'YYYY-MM-DD HH24:MI:SS';
    FULL_TIME     constant varchar2(40):= 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM';
    AUDM_OWNER    constant varchar2(30):= '&&audmgr';
    LF            constant varchar2(1) := chr(10);
--
type owner_list is table of varchar2(30) index by binary_integer;
type vers_list is table of number index by binary_integer;
    auditor     varchar2(30);
    cur_status  varchar2(100);
    cur_owner   varchar2(100);
    cur_date    timestamp(6) with time zone;
    cur_clear   date;
    cur_part    date;
    cur_keep    number;
    cur_wait    number;
    cur_level   pls_integer := 0;
    db_version  number;
--
    revoke_nd_exp varchar2(100);
    revoke_nd     date;
    curr_id       varchar2(30);
--
procedure err(p_text varchar2) is
begin
    raise_application_error(-20900,p_text);
end;
--
function  get_value(p_name varchar2) return varchar2 is
    str   varchar2(100);
begin
    select value into str from settings where name=p_name;
    return str;
exception when no_data_found then return null;
end;
--
function  get_num(p_name varchar2) return number is
    n number;
begin
    select value into n from settings where name=p_name;
    return nvl(n,0);
exception when others then return 0;
end;
--
procedure set_value(p_name varchar2, p_value varchar2) is
begin
    update settings set value=p_value where name=p_name;
    if sql%rowcount=0 then
        insert into settings(name,value) values (p_name,p_value);
    end if;
end;
--
procedure set_status(p_value varchar2) is
begin
    set_value('STATUS',p_value); commit;
end;
procedure set_date is
begin
    set_value('DATE_SCAN', to_char(cur_date,FULL_DATE));
    set_value('TIME_SCAN', to_char(cur_date,FULL_TIME));
    commit;
end;
procedure set_clear is
begin
    set_value('DATE_CLEAR',to_char(cur_clear,DAY_DATE));
end;
--
procedure debug(p_text varchar2,p_level pls_integer default 1) is
    n   integer;
begin
  if cur_level>=p_level and not p_text is null then
    dbms_pipe.reset_buffer;
    dbms_pipe.pack_message(substr(to_char(sysdate,TIME_DATE)||p_text,1,4090));
    n:=dbms_pipe.send_message(debug_pipe, 0, 64000);
  end if;
exception when others then null;
end;
--
procedure calc_revoke_nd is
    exp varchar2(150) := 'begin :nd := '||revoke_nd_exp||'; end;';
begin
    if revoke_nd_exp is null then
      revoke_nd := null;
    else
      begin
        execute immediate exp using out revoke_nd;
        debug(exp, 3);
        if not revoke_nd is null then
          debug('Next date to revoke privs: ' || to_char(revoke_nd, FULL_DATE));
          if revoke_nd <= sysdate then
            revoke_nd := null;
            debug('Next date to revoke privs must be in future');
          end if;
        end if;
      exception when others then
        revoke_nd := null;
        debug(sqlerrm);
        debug(exp,2);
      end;
    end if;
    if revoke_nd is null then
        debug('Revoke privs procedure disabled');
    end if;
end;
--
procedure get_revoke_nd_exp is
    revoke_nd_exp2 varchar2(100);
    res boolean;
begin
    revoke_nd_exp2 := get_value('REVOKE_NEXT_DATE');
    if revoke_nd_exp2 is null then
        res := revoke_nd_exp is null;
    elsif revoke_nd_exp is null then
        res := false;
    else
        res := (revoke_nd_exp = revoke_nd_exp2);
    end if;
    if not res then
        revoke_nd_exp := revoke_nd_exp2;
        calc_revoke_nd;
    end if;
end;
--
procedure get_settings(p_init boolean default false) is
begin
    auditor := nvl(get_value('AUDITOR'),'AUD');
    cur_owner := get_value('OWNERS');
    cur_status:= nvl(get_value('STATUS'),'TEST');
    begin
        cur_wait := nvl(get_value('TIMEOUT'),0);
        cur_keep := nvl(get_value('KEEP_HISTORY'),0);
        cur_level:= nvl(get_value('DEBUG_LEVEL'),0);
    exception when others then
        cur_wait := 0;
        cur_keep := 0;
        cur_level:= 0;
    end;
    if cur_wait<=0 then cur_wait := READ_TIME_OUT; end if;
    if cur_keep<=0 then cur_keep := KEEP_HISTORY;  end if;
    if cur_level<0 then cur_level:= 0;  end if;
    if p_init then
      begin
        cur_date := to_timestamp_tz(get_value('TIME_SCAN'),FULL_TIME);
        if cur_date is null then
          cur_date := to_date(get_value('DATE_SCAN'),FULL_DATE);
        end if;

        if cur_date is null then
          cur_date := systimestamp;
        end if;
      exception when others then
        cur_date := systimestamp;
      end;

      begin
        cur_clear:= nvl(to_date(get_value('DATE_CLEAR'),DAY_DATE),trunc(sysdate));
      exception when others then
        cur_clear:= trunc(sysdate);
      end;

      set_value('AUDITOR',auditor);
      set_value('OWNERS',cur_owner);
      set_value('TIMEOUT',cur_wait);
      set_value('KEEP_HISTORY',cur_keep);
      set_value('DEBUG_LEVEL',cur_level);
      set_clear;
      set_date;
    end if;
end;
--
function hash_idx(p_str varchar2) return pls_integer is
begin
    return dbms_utility.get_hash_value(p_str,1,1073741824);
end;
--
procedure get_prop(str varchar2, prop varchar2, pos out nocopy pls_integer, len out nocopy pls_integer ) is
    i   pls_integer;
    j   pls_integer;
begin
    i := instr(str,'|'||prop);
    if i>0 then
        j := instr(str,'|',i+1);
        if j=0 then
            j := length(str)+1;
        end if;
        len := j-i-1;
    else
        len := 0;
    end if;
    pos := i;
end;
/***************************************************/
function exec_sql(p_query varchar2) return varchar2 is
    s   varchar2(2000);
begin
    execute immediate p_query;
    debug(p_query,3);
    return null;
exception
when others then
    s:=sqlerrm;
    debug('EXEC_SQL: '||s);
    debug(p_query,2);
    return s;
end;
--
function exec_log ( p_owner varchar2,
                    p_date1 timestamp_tz_unconstrained, p_date2  timestamp_tz_unconstrained,
                    p_version number, p_gowner varchar2, p_list varchar2) return integer is
    v_query varchar2(4000);
    v_col   varchar2(50);
    v_tcol  varchar2(20);
    v_tcol_sel  varchar2(100);
    n   integer;
    v10 boolean;
    v_time1 timestamp;
    v_time2 timestamp;
    v_date1 date;
    v_date2 date;
begin
    v10 := db_version>=10;
    if v10 then
      v_tcol     := 'ntimestamp#';
      v_tcol_sel := 'from_tz(t.ntimestamp#,''00:00'') at time zone '''||to_char(p_date2,'TZH:TZM')||''' time_val';
      v_time1 := sys_extract_utc(p_date1);
      v_time2 := sys_extract_utc(p_date2);
    else
      v_tcol     := 'timestamp';
      v_tcol_sel := 't.timestamp time_val';
      v_date1 := p_date1;
      v_date2 := p_date2;
    end if;
    if p_version>=6.5 then
      v_col := ',substr(t.comment_text,1,200) text';
      v_query := '
    '||audm_owner||'.aud_mgr.notify('''||p_owner||''',''BAD_CONNECT'',u,c.os_username,c.terminal,c.text,c.time_val,c.sessionid,c.returncode);';
    end if;
    v_query:='
    b:='||audm_owner||'.aud_mgr.is_supervisor(c.orauser,:LIST);
    if b is null or b then
      u := c.orauser;'||v_query||'
    else
      u := c.username;
    end if;
    if not u is null then';
    if p_version>=5.4 then
      v_query := v_query||'
      u:=substr(u||''.''||c.os_username,1,70);
      t:=aud_mgr.get_msg(aud_mgr.MSG_LOGON_ERROR, c.terminal, c.name, sqlerrm(-c.returncode));
      insert into '||auditor||'.'||p_gowner||'_diary3(id,time,audsid,user_id,topic,code,text)
      values('||auditor||'.diary_id.nextval,c.time_val,c.sessionid,u,''E'',''LOGON'',t);';
    else
      v_query := v_query||'
      u:=substr(u||''.''||c.os_username,1,50);
      t:=substr(''LOGON: ''||c.terminal||'' - ''||c.name||'' : ''||sqlerrm(-c.returncode),1,2000);
      insert into '||auditor||'.diary(id,time,owner,user_id,topic,text)
      values('||auditor||'.diary_id.nextval,c.time_val,'''||p_owner||''',u,''E'',t);';
    end if;
    v_query:=
'declare n integer:=0; u varchar2(70); t varchar2(2000); b boolean;
begin
  for c in (
  select nvl(u.name,upper(t.username)||'' Manager'') name,u.username,upper(t.username) orauser,
         t.os_username,t.terminal,t.sessionid,t.returncode,'||v_tcol_sel||v_col||'
    from dba_audit_trail t, '||p_owner||'.users u
   where t.action=100 and t.'||v_tcol||'>=:D1 and t.'||v_tcol||'<:D2
     and t.returncode<>0 and upper(t.username)=u.username(+)
  )loop'||v_query||'
      n:=n+1;
    end if;
  end loop;
  commit;
  :R0:=n;
end;';
    n := 0;
    if v10 then
      execute immediate v_query using v_time1,v_time2,p_list, in out n;
    else
      execute immediate v_query using v_date1,v_date2,p_list, in out n;
    end if;
    debug(v_query,3);
    return n;
exception
when others then
    debug('EXEC_LOG: '||sqlerrm);
    debug(v_query,2);
    --raise;
    return -2;
end;
--
function exec_lock(p_owner varchar2, p_date date, p_version number, p_gowner varchar2) return integer is
    v_query      varchar2(4000);
    v_user_locked varchar2(20);
    n   integer;
begin
    if p_version>=5.4 then
        v_query:='
    insert into '||auditor||'.'||p_gowner||'_diary3(id,time,audsid,user_id,topic,code,text)
    values('||auditor||'.diary_id.nextval,systimestamp,';
        if p_version>=6.4 then
            v_query := v_query||'nvl(substr(c.user_locked, 1, instr(c.user_locked, ''.'') - 1), 0),';
            v_query := v_query||'nvl(substr(c.user_locked, instr(c.user_locked, ''.'') + 1), '''||audm_owner||'''),';
            v_user_locked := ',user_locked';
        else
            v_query := v_query||'0,'''||audm_owner||''',';
        end if;
        v_query := v_query||'''U'',''AUD_MGR'',t);';
    else
        v_query:='
    insert into '||auditor||'.diary(id,time,owner,user_id,topic,text)
    values('||auditor||'.diary_id.nextval,sysdate,'''||p_owner||''',c.username,''U'',t);';
    end if;
    if p_version>=6.6 then
        v_query := v_query||'if substr(c.user_locked, 1, 4) <> ''ORA$'' then
        dbms_alert.signal(substr(c.user_locked, 1, 30), substr(t, 1, 1800)); end if;';
    end if;
    v_query:=
'declare n integer:=0; i pls_integer; l pls_integer; j pls_integer;
    s varchar2(20); t varchar2(2000); msg pls_integer;
begin
  for c in (
  select name,username'||v_user_locked||',lock_status,date_lock,date_unlock,properties,rowid
    from '||p_owner||'.users u
   where type=''U'' and lock_status is not null
     and (lock_status in (''TO_DELETE'',''TO_EXPIRE'')
       or lock_status=''TO_LOCK'' and date_lock<=:D0
       or lock_status=''TO_UNLOCK'' and date_unlock<=:D0)
  )loop
    j := aud_mgr.user_exists(c.username);
    s := substr(c.lock_status,4);
    if s=''EXPIRE'' then
      t:='' PASSWORD EXPIRE''; aud_mgr.get_prop(c.properties,s,i,l);
      msg := aud_mgr.MSG_PASSWORD_EXPIRED;
      if l>0 then
        if l>7 then t:=substr(c.properties,i+7,l-6)||t;
          if t like '' "%"%'' then
            t:='' IDENTIFIED BY''||t||'' ACCOUNT UNLOCK'';
            msg := aud_mgr.MSG_PASSWORD_CHANGED_EXPIRED;
          end if;
        if j=0 then msg := aud_mgr.MSG_ACCOUNT_REFRESHED; j := 2; end if;
        end if;
        update '||p_owner||'.users set lock_status=null,
           properties=substr(c.properties,1,i)||substr(c.properties,i+l+2)
         where rowid=c.rowid; commit;
      end if;
    elsif s=''UNLOCK'' then
      t:='' ACCOUNT UNLOCK'';
    else
      t:='' ACCOUNT LOCK'';
    end if;
    if j=1 then t:=aud_mgr.exec_sql(''ALTER USER ''||c.username||t); else t:=null; end if;
    if t is null then n:=n+1;
      if s=''LOCK'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_ACCOUNT_LOCKED, c.username, c.name);
        if c.date_unlock>c.date_lock then
          s:=''TO_UNLOCK'';
        else
          s:=''LOCKED'';
        end if;
      elsif s=''UNLOCK'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_ACCOUNT_UNLOCKED, c.username, c.name); s:=null;
      elsif s=''EXPIRE'' then
        t:=aud_mgr.get_msg(msg, c.username, c.name);
        if j=2 then s:=null; else s:=''EXPIRED''; end if;
      elsif s=''DELETE'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_USER_DELETED, c.username, c.name); s:=''DELETED'';
      end if;
      update '||p_owner||'.users set lock_status=s where rowid=c.rowid;
    else
      if s=''LOCK'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_LOCK_ERROR, c.username, c.name, t);
      elsif s=''UNLOCK'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_UNLOCK_ERROR, c.username, c.name, t);
      elsif s=''EXPIRE'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_EXPIRE_ERROR, c.username, c.name, t);
      elsif s=''DELETE'' then
        t:=aud_mgr.get_msg(aud_mgr.MSG_DELETE_ERROR, c.username, c.name, t);
      end if;
    end if;'||v_query||'
    commit;
  end loop;
  :R0:=n;
end;';
    n := 0;
    execute immediate v_query using p_date, in out n;
    debug(v_query,3);
    return n;
exception
when others then
    debug('EXEC_LOCK: '||sqlerrm);
    debug(v_query,2);
    --raise;
    return -2;
end;
--
function exec_fresh(p_owner varchar2, p_version number, p_gowner varchar2) return integer is
    v_query      varchar2(4000);
    n   integer;
begin
    if p_version>=5.4 then
        v_query:='
    insert into '||auditor||'.'||p_gowner||'_diary3(id,time,audsid,user_id,topic,code,text)
    values('||auditor||'.diary_id.nextval,systimestamp,'||nvl(curr_id,'0')||','''||audm_owner||''',''U'',''AUD_MGR'',t);';
    else
        v_query:='
    insert into '||auditor||'.diary(id,time,owner,user_id,topic,text)
    values('||auditor||'.diary_id.nextval,sysdate,'''||p_owner||''',c.username,''U'',t);';
    end if;
    v_query:=
'declare n integer:=0; s varchar2(32); t varchar2(2000); dl date; du date;
begin
  for c in (select name,username,lock_status,date_lock,date_unlock,rowid
    from  '||p_owner||'.users u
   where type=''U''
 and (lock_status in (''LOCKED'',''TO_UNLOCK'') and exists
     (select 1 from dba_users d where d.username=u.username and d.account_status not like ''%LOCKED%'')
  or lock_status=''EXPIRED'' and exists
     (select 1 from dba_users d where d.username=u.username and (d.account_status=''OPEN''
          or d.account_status like ''%LOCKED%''))
  or lock_status is null  and exists
     (select 1 from dba_users d where d.username=u.username and (d.account_status like ''%LOCKED%''
          or d.account_status like ''%EXPIRED%'' and d.account_status not like ''%GRACE%'' ))))
  loop
    dl:=c.date_lock; du:=c.date_unlock;
    select account_status into s from dba_users where username=c.username;
    if s like ''%LOCKED%'' then
      if c.lock_status=''EXPIRED'' and du>sysdate then
        s := ''TO_UNLOCK'';
      else
        s:=''LOCKED'';
      end if;
      dl:=sysdate;
      t:=aud_mgr.get_msg(aud_mgr.MSG_ACCOUNT_LOCKED_EXT, c.username, c.name);
    elsif c.lock_status=''EXPIRED'' then
      s:=null;
      t:=aud_mgr.get_msg(aud_mgr.MSG_PASSWORD_REFRESHED, c.username, c.name);
    elsif s like ''%EXPIRED%'' and s not like ''%GRACE%'' then
      s:=''EXPIRED'';
      t:=aud_mgr.get_msg(aud_mgr.MSG_PASSWORD_EXPIRED_EXT, c.username, c.name);
    else
      du:=sysdate; s:=null;
      t:=aud_mgr.get_msg(aud_mgr.MSG_ACCOUNT_UNLOCKED_EXT, c.username, c.name);
    end if;
    update '||p_owner||'.users set lock_status=s,date_lock=dl,date_unlock=du where rowid=c.rowid;'||v_query||'
    commit;
    n:=n+1;
  end loop;
  :R0:=n;
end;';
    n := 0;
    execute immediate v_query using in out n;
    debug(v_query,3);
    return n;
exception
when others then
    debug('EXEC_FRESH: '||sqlerrm);
    debug(v_query,2);
    --raise;
    return -2;
end;
--
function exec_clear return integer is
    v_query      varchar2(200);
    n   integer;
    d   date;
begin
    if db_version>=10 then
      v_query := 'NTIMESTAMP#';
    else
      v_query := 'TIMESTAMP#';
    end if;
    v_query:='DELETE FROM SYS.AUD$ WHERE '||v_query||'<:D AND ACTION# BETWEEN 100 AND 102';
    d := cur_clear+cur_keep;
    execute immediate v_query using d;
    debug(v_query,3);
    return sql%rowcount;
exception
when others then
    debug('EXEC_CLEAR: '||sqlerrm);
    debug(v_query,2);
    --raise;
    return -2;
end;
--
/***************************************************/
function get_list(owners owner_list) return varchar2 is
    s   varchar2(100);
    i   pls_integer;
begin
    i := owners.first;
    while not i is null loop
        if s is null then
            s := owners(i);
        else
            s := s||','||owners(i);
        end if;
        i := owners.next(i);
    end loop;
    return s;
end;
--
function user_exists(p_user varchar2) return pls_integer is
  n pls_integer;
begin
  select count(1) into n from dba_users where username=p_user;
  return n;
end;
--
procedure get_owners(owners in out nocopy owner_list) is
    v_str varchar2(100);
    i   pls_integer;
    j   pls_integer;
    ii  pls_integer := 1;
    l   pls_integer := length(cur_owner);
begin
    owners.delete;
    while ii<=l loop
        i := instr(cur_owner,',',ii);
        if i>ii then
            v_str := ltrim(rtrim(substr(cur_owner,ii,i-ii)));
        elsif i=0 then
            i := l;
            v_str := ltrim(rtrim(substr(cur_owner,ii)));
        else
            v_str := null;
        end if;
        if i>1 and not v_str is null and user_exists(v_str)>0 then
            j := hash_idx(v_str);
            owners(j) := v_str;
        end if;
        ii := i+1;
    end loop;
end;
--
function table_exists(p_table varchar2,p_owner varchar2) return pls_integer is
  n pls_integer;
begin
  select count(1) into n from dba_objects
   where owner=p_owner and object_name=p_table and object_type='TABLE';
  return n;
end;
--
procedure get_versions(versions in out nocopy vers_list,gowners in out nocopy owner_list, owners owner_list) is
    own varchar2(30);
    ver varchar2(30);
    str varchar2(100);
    i   pls_integer;
    n   number;
    b   boolean;
begin
    versions.delete; gowners.delete;
    i := owners.first;
    if not i is null then
      b := table_exists('OWNERS',auditor)>0;
      while not i is null loop
        own := owners(i);
        ver := own;
        if b then
          begin
            execute immediate
              'select owner from '||auditor||'.owners where schema_owner=:OWN'
              into ver using own;
          exception when others then null;
          end;
        end if;
        gowners(i) := ver;
        begin
          execute immediate
            'select value from '||auditor||'.settings where owner=:OWN and name=:NAM'
            into str using ver,'VERSION';
          n := to_number(str,'999.9');
        exception when others then n:= null;
        end;
        n := nvl(n,3.4);
        if n=6.3 then
          select count(1) into n from dba_tab_columns
           where owner=own and table_name='USERS' and column_name='USER_LOCKED';
          if n>0 then
            n := 6.4;
          else
            n := 6.3;
          end if;
        end if;
        versions(i) := n;
        i := owners.next(i);
      end loop;
    end if;
exception when others then
    debug('GET_VERSIONS: '||sqlerrm);
end;
--
procedure add_owner(p_owner varchar2) is
    v_owner varchar2(100):=upper(ltrim(rtrim(p_owner)));
    v_list  varchar2(200);
    owners  owner_list;
    gowners owner_list;
    versions vers_list;
    n   pls_integer;
begin
    if v_owner is null then
        err('Owner name cannot be null...');
    end if;
    if user_exists(v_owner)=0 then
        err(v_owner||' is not an Oracle user...');
    end if;
    if table_exists('USERS',v_owner)=0 then
        err(v_owner||' has not USERS table...');
    end if;
    select count(1) into n from dba_tab_columns
     where owner=v_owner and table_name='USERS'
       and column_name in ('DATE_LOCK','DATE_UNLOCK','LOCK_STATUS');
    if n<3 then
        err(v_owner||'.USERS table structure is not valid...');
    end if;
    get_settings;
    get_owners(owners);
    n := hash_idx(v_owner);
  if owners.exists(n) then
    n := 0;
  else
    v_list := get_list(owners);
    if v_list is null then
        v_list := v_owner;
    else
        v_list := v_list||','||v_owner;
    end if;
    if length(v_list)>100 then
        err('OWNERS list is full...');
    end if;
    set_value('OWNERS',v_list); commit;
  end if;
  debug(nvl(exec_sql('CREATE OR REPLACE TRIGGER TRG_SETTINGS_INS_UPD
  BEFORE INSERT OR UPDATE ON SETTINGS FOR EACH ROW
begin
  :new.name:=upper(:new.name);
  if sys_context(''USERENV'',''SESSION_USER'') not in (''SYS'','''||audm_owner||''') then
    if :new.name in (''AUDITOR'',''OWNERS'') or :new.name like ''PROTECT%'' then
      raise aud_mgr.NO_PRIVILEGES;
    end if;
  end if;
  :new.value:=upper(:new.value);
end;'),'Trigger TRG_SETTINGS_INS_UPD created'));
  owners.delete;
  owners(0) := v_owner;
  get_versions(versions,gowners,owners);
  if versions(0) >= 6.4 then
      debug(nvl(exec_sql('CREATE OR REPLACE TRIGGER '||v_owner||'_USERS
BEFORE INSERT OR UPDATE OF LOCK_STATUS,DATE_UNLOCK,USER_LOCKED
ON '||v_owner||'.USERS FOR EACH ROW
begin
aud_mgr.chk_subject(:new.username);
aud_mgr.chk_status(:old.lock_status,:new.lock_status,:new.date_lock,:new.date_unlock,inserting);
if sys_context(''USERENV'',''SESSION_USER'') not in (''SYS'', '''||audm_owner||''') or :old.user_locked is null then
  :new.user_locked := aud_mgr.chk_user('''||v_owner||'''); end if;
end;'),'Trigger '||v_owner||'_USERS created'));
  else
      debug(nvl(exec_sql('CREATE OR REPLACE TRIGGER '||v_owner||'_USERS
BEFORE INSERT OR UPDATE OF LOCK_STATUS,DATE_UNLOCK
ON '||v_owner||'.USERS FOR EACH ROW
begin
aud_mgr.chk_subject(:new.username);
aud_mgr.chk_status(:old.lock_status,:new.lock_status,:new.date_lock,:new.date_unlock,inserting);
end;'),'Trigger '||v_owner||'_USERS created'));
  end if;
  if n=0 then
    err(v_owner||' is already present in the OWNERS list...');
  end if;
end;
--
procedure del_owner(p_owner varchar2) is
    v_owner varchar2(100):=upper(ltrim(rtrim(p_owner)));
    v_list  varchar2(500);
    owners  owner_list;
    n   pls_integer;
begin
    if v_owner is null then return; end if;
    get_settings;
    get_owners(owners);
    n := hash_idx(v_owner);
    owners.delete(n);
    v_list := get_list(owners);
    set_value('OWNERS',v_list); commit;
    debug(nvl(exec_sql('DROP TRIGGER '||v_owner||'_USERS'),'Trigger '||v_owner||'_USERS dropped'));
end;
--
procedure notify (p_owner varchar2, p_event varchar2,
                  p_user  varchar2, p_osusr varchar2,
                  p_term  varchar2, p_conn  varchar2,
                  p_time  date, p_ses number, p_err number) is
  v_err   varchar2(100);
  v_db    varchar2(30);
  n number;
begin
  execute immediate
    'select count(1) from '||auditor||'.notifications where owner=:OWN and event=:EVT and status=''ACTIVE'''
    into n using p_owner,p_event;
  debug('NOTIFY: '||p_owner||'.'||p_event||':'||p_user||' '||p_osusr||' '||p_term||' '||p_conn);
  if n>0 then
    v_db := sys_context('USERENV','DB_NAME');
    if p_err>0 then
      v_err  := substr(sqlerrm(-p_err),1,100);
    end if;
    execute immediate 'begin '||auditor||'.send_notify(:O,:E,:S1,:S2,:S3,:T1,:T2,:T3,:T4,:T5,:T6,:T7); end;'
      using p_owner,p_event,v_db,p_user,p_term,
            v_db,to_char(p_time,FULL_DATE),p_user,p_osusr,p_term,'AudSid='||p_ses||', '||p_conn,v_err;
  end if;
exception when others then
    debug('NOTIFY: '||sqlerrm);
end;
--
function get_audsid return number is
  v_ses number;
begin
  v_ses := SYS_CONTEXT('USERENV', 'BG_JOB_ID');
  if v_ses is null then
    v_ses := SYS_CONTEXT('USERENV', 'SESSIONID');
    if v_ses > 2147483647 then
      v_ses := dbms_utility.get_hash_value(dbms_session.unique_session_id,1073741824,1073741824);
    end if;
  elsif v_ses > 2147483647 then
    v_ses := dbms_utility.get_hash_value(dbms_session.unique_session_id,1073741824,1073741824);
  else
    v_ses := -v_ses;
  end if;
  return v_ses;
end;
--
procedure notify1(p_owner varchar2, p_event varchar2) is
  v_str varchar2(100);
begin
  select program into v_str from v$session where sid = sys_context('USERENV','SID');
  if not v_str is null then
    v_str := ', Program: '||v_str;
  end if;
  notify(p_owner,p_event,sys_context('USERENV','SESSION_USER'),sys_context('USERENV','OS_USER'),sys_context('USERENV','TERMINAL'),
         'IP='||sys_context('USERENV','IP_ADDRESS')||v_str,sysdate,get_audsid,0);
end;
--
function is_supervisor(p_user varchar2,p_list varchar2) return boolean is
  v_user varchar2(30);
  v_list varchar2(200);
begin
  if p_user is null then
    if sys_context('USERENV','ISDBA')='TRUE' then
      return null;
    end if;
    v_user := sys_context('USERENV','SESSION_USER');
  else
    v_user := p_user;
  end if;
  if v_user in ('SYS',audm_owner,auditor) then
    return null;
  end if;
  if p_list is null then
    v_list := ','||get_value('SUPERVISORS')||',';
  else
    v_list := p_list;
  end if;
  return instr(','||cur_owner||v_list,','||v_user||',')>0;
end;
--
procedure init_contexts is
    s   varchar2(30);
    q   varchar2(100);
    i   pls_integer;
    b   boolean;
    owners  owner_list;
begin
    cur_owner := get_value('OWNERS');
    cur_level := get_num('DEBUG_LEVEL');
    auditor := nvl(get_value('AUDITOR'),'AUD');
    b := is_supervisor(null,null);
    if b is null or b then
      /*select count(1) into i from v$lock where type='JQ' and sid=(select sid from v$mystat where rownum=1);
      if i>0 then
        b := false;
      end if;*/
      if sys_context('USERENV','BG_JOB_ID') is not null then
        b := false;
      end if;
    end if;
    get_owners(owners);
    i := owners.first;
    while not i is null loop
      s := owners(i);
      if b is null or b then
        q := ' if n>6.4 then '||audm_owner||'.aud_mgr.notify1('''||s||''',''CONNECT''); end if;';
        if b is null then
          q := q||' return;';
        end if;
      else
        q := null;
      end if;
      debug(exec_sql(
'DECLARE
  n number; u varchar2(30);
BEGIN
  n := to_number('||s||'.inst_info.version,''999.9'');'||q||'
  if n>7.0 or (n>5.1 and '||s||'.sysinfo.getvalue(''SYS_CONTEXT'')=''1'') then
    u := sys_context(''USERENV'',''SESSION_USER'');
    if u != '''||s||''' then
      select 1 into n from '||s||'.users where username=u and type=''U''
         and properties like ''%|CONTEXT%'' and (lock_status is null or lock_status=''TO_LOCK'' and date_lock>sysdate);
    end if;
    '||s||'.executor.dummy;
    '||audm_owner||'.aud_mgr.debug(''Contexts for '||s||'.''||u||''.''||sys_context(''USERENV'',''SESSIONID'')||'' created'');
  end if;
exception when no_data_found then null;
END;'));
      i := owners.next(i);
    end loop;
end;
--
procedure exec_revoke(owners owner_list, versions vers_list) is
    owner varchar2(30);
    query varchar2(200);
    i pls_integer;
begin
    i := owners.first;
    while not i is null loop
      if versions(i)>=6.4 then
        owner := owners(i);
        query :=
'BEGIN
  begin
    '||owner||'.SecAdmin.BecomeUser;
  exception when others then
    null;
  end;
  '||owner||'.SecAdmin.RevokePrivs;
  '||audm_owner||'.aud_mgr.debug(''RevokePrivs for '||owner||''');
END;';
        debug(exec_sql(query));
      end if;
      i := owners.next(i);
    end loop;
end;
--
procedure check_job_lic(owners owner_list, versions vers_list) is
    i pls_integer;
    d date;
begin
  i := owners.first;
  while not i is null loop
    if versions(i)>=6.6 then
      begin
        execute immediate 'select min(nvl(check_time,sysdate-2)) from '||auditor||'.license_settings where owner=:own'
          into d using owners(i);
      exception when others then
        d := sysdate;
      end;
      if d<trunc(sysdate)-0.5 then
        debug(exec_sql(
        'BEGIN
        '||audm_owner||'.aud_mgr.debug(''Check job opt_mgr for '||owners(i)||''');
        '||owners(i)||'.opt_mgr.submit;
        END;'));
      end if;
    end if;
    i := owners.next(i);
  end loop;
end;
--
function check_partitions(owners   owner_list,
                          gowners  owner_list,
                          versions vers_list) return boolean is
  owner varchar2(30);
  query varchar2(2000);
  i     pls_integer;
  b     boolean;
  d     date;
begin
  d := add_months(trunc(cur_part, 'MM'), 6);
  i := owners.first;
  while not i is null loop
    if versions(i) >= 6.5 then
      owner := owners(i);
      b     := true;
      query := 'declare
  d date := :dat; o varchar2(30) := :own; dd date;
begin
  for c in (select diary_type,diary_suffix,diary_step from ' ||
               auditor || '.diary_tables where owner=o) loop
    if d>' || auditor || '.clear.get_end_date(o,c.diary_type) then
      ' || audm_owner || '.aud_mgr.debug(''Add partitions for ''||o||''_''||c.diary_suffix);
      if c.diary_step=''Q'' then dd:=trunc(d,''Q''); if dd<d then dd:=add_months(dd,3); end if; else dd:=d; end if;
      ' || auditor || '.clear.add_partitions(o,c.diary_type,dd);
    end if;
  end loop;
end;';
      begin
        execute immediate query
          using d, gowners(i);
        debug(query, 3);
      exception
        when others then
          debug('ADD_PARTITIONS: ' || sqlerrm);
          debug(query, 2);
      end;
    end if;
    i := owners.next(i);
  end loop;
  set_value('DATE_PARTITIONS', to_char(add_months(cur_part, 1), FULL_DATE));
  commit;
  return b;
end;
--
procedure logoff is
    s   varchar2(30);
    i   pls_integer;
    owners  owner_list;
begin
  if sys_context('USERENV','SESSION_USER')<>audm_owner then
      if cur_owner is null then
        cur_owner := get_value('OWNERS');
        cur_level := get_num('DEBUG_LEVEL');
      end if;
      get_owners(owners);
      i := owners.first;
      while not i is null loop
          s := owners(i);
          debug(exec_sql(
'DECLARE
  n number;
BEGIN
  n := to_number('||s||'.inst_info.version,''999.9'');
  if n>=6.3 then
    n := sys_context('''||s||'_SYSTEM'',''STATUS'');
    if n is not null then
      if bitand(n,1) > 0 then
        n := sys_context('''||s||'_SYSTEM'',''ID'');
        '||audm_owner||'.aud_mgr.debug(''Opened session '||s||'.''||n);
        if n > -1073741824 then '||s||'.rtl.close; else '||s||'.rtl.lock_reset; end if;
      end if;
      '||s||'.edoc_mgr.logoff;
      '||audm_owner||'.aud_mgr.debug(''Logoff '||s||'.''||sys_context(''USERENV'',''SESSION_USER'')||''.''||sys_context(''USERENV'',''SESSIONID''));
    end if;
  end if;
END;'));
          i := owners.next(i);
      end loop;
  end if;
end;
--
procedure chk_status(p_old varchar2,p_new varchar2,p_start date,p_end date,p_insert boolean) is
begin
  if sys_context('USERENV','SESSION_USER') not in ('SYS',audm_owner) then
    if p_insert then
      if not p_new is null  then
        err('LOCK_STATUS should be null while inserting...');
      end if;
    elsif not p_new is null then
      if p_new='TO_LOCK' and (p_old is null or p_old in ('TO_LOCK','EXPIRED','TO_UNLOCK')) then
        if p_start is null then
          err('DATE_LOCK should not be null...');
        end if;
      elsif p_new='TO_DELETE' or p_new='TO_EXPIRE' and (p_old is null or p_old in ('EXPIRED','LOCKED','TO_UNLOCK')) then
        null;
      elsif p_new='TO_UNLOCK' and p_old in ('LOCKED','TO_UNLOCK') then
        if p_end is null then
          err('DATE_UNLOCK should not be null...');
        end if;
      else
        err('LOCK_STATUS should not be modified...');
      end if;
      if get_value('STATUS')='STARTED' then null; else
        err('AUD_MGR should be active to perform this function...');
      end if;
    elsif not p_old is null then
      err('LOCK_STATUS and DATE_UNLOCK should not be modified...');
    end if;
  end if;
end;
--
function chk_user(p_owner varchar2) return varchar2 is
  audsid varchar2(30) := SYS_CONTEXT(p_owner||'_SYSTEM', 'ID');
begin
  if audsid is null then
    return get_audsid||'.'||
        SYS_CONTEXT('USERENV', 'SESSION_USER')||'.'||
        SYS_CONTEXT('USERENV', 'OS_USER');
  else
    return audsid||'.'||
        SYS_CONTEXT(p_owner||'_SYSTEM', 'USER')||'.'||
        SYS_CONTEXT(p_owner||'_SYSTEM', 'OSUSER');
  end if;
end;
--
procedure chk_subject(p_name varchar2) is
    v_name  varchar2(32) := upper(ltrim(rtrim(p_name)));
begin
  if sys_context('USERENV','SESSION_USER') not in ('SYS',audm_owner) then
    if v_name in ('SYS','SYSTEM',audm_owner) then
      raise NO_PRIVILEGES;
    else
      v_name := ','||v_name||',';
      for c in (select value from settings where name='OWNERS' or name like 'PROTECT%') loop
        if instr(','||replace(upper(ltrim(rtrim(c.value))),' ')||',',v_name)>0 then
          raise NO_PRIVILEGES;
        end if;
      end loop;
    end if;
  end if;
end;
--
function server_test return boolean is
    ok  boolean;
begin
    get_settings(true);
    if cur_status='HELD' then
        return false;
    end if;
    set_status('TEST');
    for i in 1..2 loop
        dbms_lock.sleep(cur_wait+1);
        cur_status:=get_value('STATUS');
        if cur_status='STARTED' then
            return true;
        end if;
    end loop;
    return false;
end;
--
function find_job return dba_jobs%rowtype is
    j   dba_jobs%rowtype;
begin
    for c in (select * from dba_jobs
               where schema_user=audm_owner
                 and what='aud_mgr.job(job,next_date,broken);')
    loop
      if j.job is null then
        j := c;
      else
        dbms_job.remove(c.job);
        commit;
      end if;
    end loop;
    return j;
end;
--
procedure submit is
    j   dba_jobs%rowtype;
begin
    if server_test then
        err('AUD_MGR is already running...');
    end if;
    j := find_job;
    if j.job is null then
        dbms_job.submit(j.job,'aud_mgr.job(job,next_date,broken);');
        commit;
        debug('Job '||j.job||' submitted');
    elsif j.next_date+3/864<sysdate then
        err('BACKROUND process cannot start job '||j.job);
    else
        debug('Job '||j.job||' is waiting execution');
    end if;
end;
--
procedure hold( p_hold boolean ) is
    j   dba_jobs%rowtype;
begin
    if p_hold then
        cur_status:='HELD';
    else
        cur_status:='RUN';
        j := find_job;
        if not j.job is null then
            dbms_job.broken(j.job,false,sysdate);
        end if;
    end if;
    set_status(cur_status);
end;
--
procedure job ( p_job integer, p_date in out nocopy date, p_broken in out nocopy boolean ) is
    s   varchar2(10);
    e   varchar2(100);
    n   pls_integer;
begin
  s:=substr(get_value('STATUS'),1,10);
  begin
    run;
    if cur_status in ('RESTART','HELD') then
        p_broken := cur_status='HELD';
        p_date := sysdate+1/8640;
    end if;
  exception when others then
    e := substr(sqlerrm,1,98);
    n := 1;
    if instr(s,'*ORA-')=2 then
      begin
        n:=substr(s,1,1)+1;
      exception when others then n:=1;
      end;
    end if;
    set_status(n||'*'||e);
    if n<6 then
        p_date := sysdate + n/8640;
    end if;
  end;
  dbms_session.free_unused_user_memory;
end;
--
procedure stop is
    j   dba_jobs%rowtype;
begin
    j := find_job;
    if not j.job is null then
        dbms_job.remove(j.job);
    end if;
    set_status('STOP');
end;
--
procedure run is
    str varchar2(1000);
    n   integer;
    cnt pls_integer;
    d   date;
    t   timestamp(6) with time zone;
    ok  boolean;
    i   pls_integer;
    v_module    varchar2(100);
    v_action    varchar2(100);
    v_info      varchar2(100);
    v_list      varchar2(120);
    owners      owner_list;
    gowners     owner_list;
    versions    vers_list;
  --
  procedure RemoveOldInheritedCritAccess(owner varchar2) is
    v_query varchar2(200);
    begin
      v_query := 
        'begin'||LF||
        owner || '.SecAdmin.RemoveOldInheritedCritAccess(100);'||LF||
        'end;';
      debug(exec_sql(v_query));
    end;
  --
begin
    select value into str from v$parameter where upper(name)='AUDIT_TRAIL';
	-- 'TRUE','DB_EXTENDED' only for backward-compatibility with Oracle version lower than 11g
	-- "'DB,EXTENDED'" only for backward-compatibility with Oracle version lower than 10.1
    if regexp_replace(upper(str),'[ '']') in ('TRUE','DB_EXTENDED','DB','DB,EXTENDED','EXTENDED,DB') then null; else
        err('System AUDIT_TRAIL parameter is not TRUE');
    end if;
    select count(1) into n from dba_priv_audit_opts
     where privilege='CREATE SESSION' and rownum<2;
    if n=0 then
        err('No currently Auditing Sessions...');
    end if;
    if server_test then
        err('AUD_MGR is already running...');
    end if;
    dbms_utility.db_version( v_module, v_action );
    db_version := substr(v_module,1,instr(v_module,'.')-1);
    if db_version>=10 then
      debug(exec_sql('alter session set time_zone=dbtimezone'));
    end if;
    curr_id := get_audsid;
    dbms_application_info.read_module( v_module, v_action );
    dbms_application_info.read_client_info( v_info );
    dbms_application_info.set_module ( 'AUD_MGR', 'Auditing sessions' );
    dbms_application_info.set_client_info( VERSION );
    cnt := 0;
    while cur_status not in ('HELD','STOP','RESTART') loop
      set_status('STARTED');
      --
      if mod(cnt,100)=0 then
        get_owners(owners);
        get_versions(versions,gowners,owners);
        v_list := ','||get_value('SUPERVISORS')||',';
        cur_part := to_date(get_value('DATE_PARTITIONS'),FULL_DATE);
        if mod(cnt,1000)=0 then
          cnt := 0;
          -- проверка наличия джобов для контроля лицензионной информации
          check_job_lic(owners,versions);
          dbms_application_info.set_client_info( VERSION );
        end if;
      end if;
      cnt := cnt+1;
      i := owners.first;
      ok:= not i is null;
      d := sysdate;
      t := systimestamp;
      if ok then
        while not i is null loop
          n:=exec_log(owners(i),cur_date,t,versions(i),gowners(i),v_list);
          str:='log records: '||n;
          if n<0 then ok:=false; end if;
          n:=exec_lock(owners(i),d,versions(i),gowners(i));
          if n>=0 then str:=str||', processed rows: '||n; end if;
          n:=exec_fresh(owners(i),versions(i),gowners(i));
          if n>=0 then str:=str||', freshen rows: '||n; end if;
          RemoveOldInheritedCritAccess(owners(i));
          debug(owners(i)||'('||versions(i)||') - '||str);
          i:=owners.next(i);
        end loop;
      end if;
      if ok then
        if d>cur_clear+(cur_keep*2) then
          n:=exec_clear;
          if n>=0 then
            cur_clear:=cur_clear+cur_keep;
            debug('Deleted SYS.AUD$: '||n);
          end if;
        end if;
        if revoke_nd <= d then
          exec_revoke(owners,versions);
          calc_revoke_nd;
          dbms_application_info.set_client_info( VERSION );
        end if;
        if d>cur_part then
          ok := check_partitions(owners,gowners,versions);
          cur_part := to_date(get_value('DATE_PARTITIONS'),FULL_DATE);
          dbms_application_info.set_client_info( VERSION );
        else
          ok := to_char(t,'DD')<>to_char(cur_date,'DD');
        end if;
        if ok then
          set_status('RESTART');
        end if;
        cur_date := t;
      end if;
      set_clear;
      set_date;
      --
      dbms_lock.sleep(cur_wait);
      get_settings;
      get_revoke_nd_exp;
    end loop;
    if cur_status='STOP' then
        set_status('FINISHED');
    end if;
    owners.delete; versions.delete;
    dbms_application_info.set_module( v_module, v_action );
    dbms_application_info.set_client_info( v_info );
end;
--
function get_msg(p_msg pls_integer,
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
    s varchar2(2000);
begin
    if p_msg = MSG_LOGON_ERROR then
        s := '%1 - %2: %3';
    elsif p_msg = MSG_EXPIRE_ERROR then
        s := '%1, %2 - ошибка изменения пароля: %3';
    elsif p_msg = MSG_LOCK_ERROR then
        s := '%1, %2 - ошибка блокировки: %3';
    elsif p_msg = MSG_UNLOCK_ERROR then
        s := '%1, %2 - ошибка разблокировки: %3';
    elsif p_msg = MSG_DELETE_ERROR then
        s := '%1, %2 - ошибка удаления: %3';
    elsif p_msg = MSG_ACCOUNT_LOCKED then
        s := '%1, %2 - пользователь блокирован';
    elsif p_msg = MSG_ACCOUNT_UNLOCKED then
        s := '%1, %2 - пользователь разблокирован';
    elsif p_msg = MSG_PASSWORD_EXPIRED then
        s := '%1, %2 - установлен признак "Пароль устарел"';
    elsif p_msg = MSG_PASSWORD_CHANGED_EXPIRED then
        s := '%1, %2 - изменен пароль, установлен признак "Пароль устарел"';
    elsif p_msg = MSG_ACCOUNT_REFRESHED then
        s := '%1, %2 - пользователь обновлен';
    elsif p_msg = MSG_USER_DELETED then
        s := '%1, %2 - пользователь удален';
    elsif p_msg = MSG_ACCOUNT_LOCKED_EXT then
        s := '%1, %2 - пользователь блокирован администратором';
    elsif p_msg = MSG_PASSWORD_REFRESHED then
        s := '%1, %2 - пароль обновлен';
    elsif p_msg = MSG_PASSWORD_EXPIRED_EXT then
        s := '%1, %2 - пароль сброшен администратором';
    elsif p_msg = MSG_ACCOUNT_UNLOCKED_EXT then
        s := '%1, %2 - пользователь разблокирован администратором';
    else
        s := '%1 %2 %3 %4 %5 %6 %7 %8 %9';
    end if;
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
    return substr(rtrim(s), 1, 2000);
exception when VALUE_ERROR then
    return null;
end get_msg;
--
procedure ora_user_password_set(
  p_user_name varchar2,
  p_password  varchar2
) is
  v_user_full_name varchar2(100);
  v_actor          varchar2(200);
  --
  procedure journal(p_actor varchar2, p_text varchar2) is
    v_audsid number;
    v_usr    varchar2(100);
    v_text   varchar2(4000);
  begin
    v_audsid := to_number(nvl(substr(p_actor, 1, instr(p_actor, '.') - 1), 0));
    v_usr    := substr(p_actor, instr(p_actor, '.') + 1);
    v_text   := substr(replace(p_text, '''', ''''''), 1, 4000);
    execute immediate
      'begin'||LF||
      '  insert into '||auditor||'.'||cur_owner||'_diary3'||LF||
      '    (id, time, audsid, user_id, topic, code, text)'||LF||
      '  values'||LF||
      '    ('||auditor||'.diary_id.nextval, systimestamp, '||v_audsid||', '''||v_usr||''', ''U'', ''AUD_MGR'', '''||v_text||''');'||LF||
      '  commit;'||LF||
      'end;';
  end;
  --
  function get_user_full_name return varchar2 is
    v_result varchar2(100);
  begin
    execute immediate
      'select name from '||cur_owner||'.users where username = :1'
       into v_result
      using in p_user_name;
    return v_result;
  end;
  --
begin
  v_actor := chk_user(cur_owner);
  v_user_full_name := get_user_full_name;
  execute immediate 'alter user '||p_user_name||' identified by "'||p_password||'" password expire';
  journal(v_actor, get_msg(MSG_PASSWORD_CHANGED_EXPIRED, p_user_name, v_user_full_name));
exception when others then
  journal(v_actor, get_msg(MSG_EXPIRE_ERROR, p_user_name, v_user_full_name, sqlerrm));
  raise;
end;
-----------------------------------------------------
end;
/
show errors package body &&audmgr..aud_mgr
