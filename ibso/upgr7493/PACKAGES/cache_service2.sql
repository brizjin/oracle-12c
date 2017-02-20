prompt cache_service body
create or replace package body
 /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/cache_service2.sql $
  *  $Author: sasa $
  *  $Revision: 55024 $
  *  $Date:: 2014-11-11 15:53:50 #$
  */
cache_service is
--
type object_t is record (
    class_id varchar2(16),
    cascade  varchar2(16)
);
type object_list_t is table of object_t index by varchar2(128);
--
type class_t is record (
    cnt pls_integer,
    cascade varchar2(16)
);
type class_list_t is table of class_t index by varchar2(16);
--
type event_t is record (
    code  pls_integer,
    event varchar2(512),
    pipe  varchar2(100)
);
type event_list_t is table of event_t index by varchar2(512);
--
type addr_event_t is table of boolean index by varchar2(100);
--
objects  object_list_t;
classes  class_list_t;
events   event_list_t;
uaddrs   addr_event_t;
cur_user rtl.users_info;
--use_static_event  boolean;
use_cache_pipes boolean;
commit_disabled boolean;
commit_nostack  boolean;
cls_no_pipes    varchar2(2000);
--
max_cnt constant pls_integer := 5;
pip_siz constant pls_integer := 65536;
locktag constant varchar2(10) := '<LOCK>';
freetag constant varchar2(10) := '<FREE>';
prefix  constant varchar2(30) := 'CACHE$'||Inst_info.owner||'#';
--
numeric_overflow exception;
pragma exception_init(numeric_overflow,-1426);
--
function get_version return varchar2 is
begin
    return '1.0';
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
function Hash_Str(p_str varchar2) return pls_integer is
begin
  return dbms_utility.get_hash_value(p_str,-2147483647,2147483647);
end;
--
function bchar(p_ok boolean) return varchar2 is
begin
  if p_ok then
    return 'TRUE ';
  end if;
  return 'FALSE';
end;
--
function get_commit_disabled return boolean is
begin
  if commit_disabled is null then
    if sys_context(INST_INFO.Owner || '_SYSTEM', 'COMMIT_DISABLED') = '1' then
      commit_disabled := true;
    else
      commit_disabled := false;
    end if;
  end if;
  if commit_disabled and commit_nostack is null then
    commit_nostack := upper(nvl(substr(rtl.setting('CLS_CHECK_COMMIT_STACK'),1,1),'Y')) not in ('Y','1');
  end if;
  return commit_disabled;
end;
--
procedure set_commit_disabled(p_disable boolean) is
begin
  if p_disable then
    commit_disabled := true;
  else
    commit_disabled := false;
  end if;
  rtl.set_context('COMMIT_DISABLED',rtl.bool_char(commit_disabled));
end;
--
procedure check_disabled(p_commit_msg boolean) is
  v_str varchar2(20);
begin
  if commit_nostack or instr(dbms_utility.format_call_stack,inst_info.owner||'.Z') > 0 then
    if p_commit_msg then
      v_str := 'COMMIT_DISABLED';
    else
      v_str := 'ROLLBACK_DISABLED';
    end if;
    message.err(-20999,constant.EXEC_ERROR,'EXCEPTION',message.gettext(constant.EXEC_ERROR,v_str));
  end if;
end;
--
procedure check_commit(p_commit_msg boolean default true) is
begin
  if get_commit_disabled then
    check_disabled(p_commit_msg);
  end if;
end;
--
procedure check_addr_cache(p_class varchar2) is
begin
  if use_cache_pipes is null then
    use_cache_pipes := upper(nvl(substr(rtl.setting('CLS_USE_CACHE_PIPES'),1,1),'Y')) in ('Y','1');
    if use_cache_pipes then
      cls_no_pipes := upper(trim(rtl.setting('CLS_NO_CACHE_PIPES')))||',SYSTEM,';
      if substr(cls_no_pipes,1,1) <> ',' then
        cls_no_pipes := ','||cls_no_pipes;
      end if;
    end if;
  end if;
  if use_cache_pipes then
    if uaddrs.exists(p_class) then
      return;
    end if;
    if rtl.db_readonly then
      uaddrs(p_class) := false;
    else
      uaddrs(p_class) := instr(cls_no_pipes,','||upper(p_class)||',') = 0;
    end if;
  end if;
end;
--
procedure reset_class_cache(p_class varchar2,p_param varchar2) is
begin
  cache_reset(p_class, trim(upper(p_param))='TRUE', null);
end;
--
procedure send$pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2);
--
procedure send_reset_cache_events is
    oidx varchar2(512);
    cidx varchar2(100);
begin
    oidx := objects.first;
    if not oidx is null then
      loop
        cidx := objects(oidx).class_id;
        if max_cnt < classes(cidx).cnt then
          classes(cidx).cnt := 0;
          if uaddrs.exists(cidx) and uaddrs(cidx) then
            send$pipe_events(cidx,12,cidx||'..'||classes(cidx).cascade);
          else
            rtl.send_events(12,cidx||'..'||classes(cidx).cascade);
          end if;
        elsif 0 < classes(cidx).cnt then
          if uaddrs.exists(cidx) and uaddrs(cidx) then
            send$pipe_events(cidx,12,cidx||'.'||oidx||'.'||objects(oidx).cascade);
          else
            rtl.send_events(12,cidx||'.'||oidx||'.'||objects(oidx).cascade);
          end if;
        end if;
        oidx := objects.next(oidx);
        exit when oidx is null;
      end loop;
      objects.delete;
    end if;
    --
    cidx := classes.first;
    if not cidx is null then
      loop
        if max_cnt < classes(cidx).cnt then
          if uaddrs.exists(cidx) and uaddrs(cidx) then
            send$pipe_events(cidx,12,cidx||'..'||classes(cidx).cascade);
          else
            rtl.send_events(12,cidx||'..'||classes(cidx).cascade);
          end if;
        end if;
        cidx := classes.next(cidx);
        exit when cidx is null;
      end loop;
      classes.delete;
    end if;
    --
    oidx := events.first;
    if not oidx is null then
      loop
        if events(oidx).code = 12 then
          reset_class_cache(events(oidx).event,'TRUE ');
        else
          cidx := events(oidx).pipe;
          if cidx is not null and uaddrs.exists(cidx) and uaddrs(cidx) then
            send$pipe_events(cidx,events(oidx).code,events(oidx).event);
          else
            rtl.send_events(events(oidx).code,events(oidx).event);
          end if;
        end if;
        oidx := events.next(oidx);
        exit when oidx is null;
      end loop;
      events.delete;
    end if;
end;
--
procedure cache_commit(p_autonom boolean default false) is
begin
    if p_autonom then
      commit;
      return;
    elsif get_commit_disabled then
      check_disabled(true);
    end if;
    commit;
    if p_autonom is null then
      return;
    end if;
    --
    send_reset_cache_events;
end;
--
procedure cache_set_savepoint(savepointname varchar2) is
begin
    dbms_transaction.savepoint(savepointname);
end;
--
procedure cache_rollback(savepointname varchar2 default null,p_autonom boolean default false) is
begin
    if savepointname is null then
      if not nvl(p_autonom,false) and get_commit_disabled then
        check_disabled(false);
      end if;
      rollback;
    else
      dbms_transaction.rollback_savepoint(savepointname);
    end if;
    cache_clear('1');
    if p_autonom then
      return;
    end if;
    if savepointname is null or get_commit_disabled then
        classes.delete;
        objects.delete;
        events.delete;
    end if;
end;
--
procedure reg_class(id varchar2, cascade boolean, new_obj boolean) is
begin
    if new_obj is null then
        if classes.exists(id) then
          if classes(id).cnt>1 then
            classes(id).cnt := classes(id).cnt - 1;
          else
            classes.delete(id);
          end if;
        end if;
    elsif classes.exists(id) then
        if new_obj then
            classes(id).cnt := classes(id).cnt + 1;
        end if;
        if cascade then
            classes(id).cascade := bchar(true);
        end if;
    else
        if not new_obj then
            message.err(-20999,'CLS','CACHE_ERROR',id,'<NEW_OBJ>');
        end if;
        classes(id).cascade := bchar(cascade);
        classes(id).cnt := 1;
        check_addr_cache(id);
    end if;
end;
--
procedure reg_obj_change(class_id varchar2, obj_id varchar2, cascade boolean) is
    cidx varchar2(16);
    n number;
begin
  $IF $$LOG_CALL $THEN
    cache_service_test.reg_obj_change(class_id, obj_id, cascade);
  $END
  $IF $$TEST_CORE $THEN
    if test_utils.is_stub_unit('cache_service.reg_obj_change') then
      return;
    end if;
  $END
  if objects.exists(obj_id) then
    cidx := objects(obj_id).class_id;
    if class_id=cidx then
      reg_class(class_id, cascade, false);
      if cascade then
        objects(obj_id).cascade := bchar(true);
      end if;
    else
      begin
        select 1 into n from class_relations
          where parent_id=class_id and child_id=cidx;
        reg_class(cidx, true, false);
      exception when no_data_found then
        reg_class(class_id, true, true);
        objects(obj_id).class_id:= class_id;
        reg_class(cidx, true, null);
      end;
      objects(obj_id).cascade := bchar(true);
    end if;
  else
    reg_class(class_id, cascade, true);
    objects(obj_id).class_id:= class_id;
    objects(obj_id).cascade := bchar(cascade);
  end if;
end;
--
procedure reg_change(class_id varchar2, cascade boolean) is
begin
  $IF $$LOG_CALL $THEN
    cache_service_test.reg_change(class_id, cascade);
  $END
  $IF $$TEST_CORE $THEN
    if test_utils.is_stub_unit('cache_service.reg_change') then
      return;
    end if;
  $END
  if classes.exists(class_id) then
    classes(class_id).cnt := classes(class_id).cnt + max_cnt;
  else
    classes(class_id).cnt := max_cnt + 1;
    check_addr_cache(class_id);
  end if;
  if cascade then
    classes(class_id).cascade := bchar(cascade);
  end if;
end;
--
procedure reg_event(p_code pls_integer, p_event varchar2, p_pipe varchar2 default null) is
  idx varchar2(512);
begin
  if p_code=12 then
    if rtl.db_readonly then
      return;
    end if;
    idx := '12.'||p_event;
    events(idx).code := p_code;
    events(idx).event:= p_event;
  elsif rtl.info_open then
    if p_code=0 then
      check_addr_cache(p_event);
      idx := '0.'||p_event;
      events(idx).pipe := p_event;
    else
      if p_code<0 or p_code=3 then
        idx := substr(p_code||'.'||p_event,1,512);
      else
        idx := p_code||'.'||p_event;
      end if;
      if p_pipe is not null then
        check_addr_cache(p_pipe);
        events(idx).pipe := p_pipe;
      end if;
    end if;
    events(idx).code := p_code;
    events(idx).event:= p_event;
  end if;
end;
--
procedure reg_clear (p_code pls_integer default null) is
  idx varchar2(512);
  str varchar2(30);
begin
  if p_code is null then
    classes.delete;
    objects.delete;
    events.delete;
    return;
  elsif p_code = 12 then
    classes.delete;
    objects.delete;
  end if;
  idx := p_code||'.';
  if not events.exists(idx) then
    idx := events.next(idx);
  end if;
  if idx is not null then
    str := p_code||'.%';
    loop
      if events(idx).code = p_code then
        events.delete(idx);
      end if;
      idx := events.next(idx);
      exit when idx is null or idx not like str;
    end loop;
  end if;
end;
--
procedure write_cache is
begin
    null;
end;
--
procedure cache_flush(info varchar2 default null) is
begin
    null;
end;
--
procedure cache_clear(info varchar2 default null) is
  idx varchar2(512);
  b boolean;
begin
  idx := classes.first;
  if not idx is null then
    loop
      reset_class_cache(idx,classes(idx).cascade);
      idx := classes.next(idx);
      exit when idx is null;
    end loop;
  end if;
  --
  idx := events.first;
  if not idx is null then
    b := cur_user.id=rtl.uid$ or rtl.get_user_info(cur_user);
    b := info = '1';
    loop
      if events(idx).code = 12 then
        reset_class_cache(events(idx).event,'TRUE ');
      elsif b then
        rtl.send_event(cur_user.id,events(idx).code,events(idx).event);
      end if;
      idx := events.next(idx);
      exit when idx is null;
    end loop;
  end if;
end;
--
procedure lru_touch(idx varchar2, lru_list in out nocopy cache_mgr.lru_list_t) is
    p varchar2(128);
    n varchar2(128);
begin
    if lru_list.prev.exists(idx) then
        p := lru_list.prev(idx);
        if p is null then
            return;
        end if;
        n := lru_list.next(idx);
        if n is null then
            lru_list.next(p) := null;
            lru_list.last := p;
        else
            lru_list.prev(n) := p;
            lru_list.next(p) := n;
        end if;
    end if;
    if lru_list.first is null then
        lru_list.last := idx;
    else
        lru_list.prev(lru_list.first) := idx;
    end if;
    lru_list.next(idx) := lru_list.first;
    lru_list.prev(idx) := null;
    lru_list.first := idx;
end;
--
function lru_remove(lru_list in out nocopy cache_mgr.lru_list_t) return varchar2 is
    l varchar2(128);
begin
    if lru_list.last is null then
        return null;
    end if;
    l := lru_list.last;
    lru_remove(lru_list.last, lru_list);
    return l;
end;
--
procedure lru_remove(idx varchar2, lru_list in out nocopy cache_mgr.lru_list_t) is
    p varchar2(128) := lru_list.prev(idx);
    n varchar2(128) := lru_list.next(idx);
begin
    lru_list.prev.delete(idx);
    lru_list.next.delete(idx);
    if p is null then
        lru_list.first := n;
    else
        lru_list.next(p) := n;
    end if;
    if n is null then
        lru_list.last := p;
    else
        lru_list.prev(n) := p;
    end if;
end;
--
procedure lru_clear(lru_list in out nocopy cache_mgr.lru_list_t) is
begin
    lru_list.last := null;
    lru_list.first := null;
    lru_list.prev.delete;
    lru_list.next.delete;
end;
--
procedure send_pipe(p_pipe varchar2,p_repeat pls_integer) is
  i pls_integer;
begin
  i := dbms_pipe.send_message(p_pipe,0,pip_siz);
  if i<>0 and p_repeat>0  then
    for j in 1..p_repeat loop
      i := dbms_pipe.send_message(p_pipe,0,pip_siz*2);
      exit when i = 0;
    end loop;
    if i = 1 then
      i := dbms_pipe.send_message(p_pipe,0,pip_siz*4);
    end if;
  end if;
  if i<>0 then
    rtl.lock_put(p_pipe,'RETRY','Error '||i||' writing cache pipe');
  end if;
end;
--
function lock_pipe(p_pipe varchar2) return boolean is
  s varchar2(40);
  p varchar2(100);
  i pls_integer;
  t pls_integer;
  b boolean;
begin
  $IF $$LOG_CALL $THEN
    cache_service_test.lock_pipe(p_pipe);
  $END
  t := 1;
  p := '$'||p_pipe;
  for x in 1..20 loop
    dbms_pipe.reset_buffer;
    i := dbms_pipe.receive_message(p,0);
    if i = 1 then
      i := dbms_pipe.receive_message(p,t);
    end if;
    if i = 0 then
      dbms_pipe.unpack_message(s);
      while dbms_pipe.receive_message(p,0) = 0 loop
        dbms_pipe.reset_buffer;
      end loop;
      dbms_pipe.reset_buffer;
      dbms_pipe.pack_message(locktag);
      send_pipe(p,3);
      if s = freetag then
        return true;
      end if;
    elsif i = 1 and t = 1 then
      dbms_pipe.reset_buffer;
      dbms_pipe.pack_message(locktag);
      send_pipe(p,3);
      return true;
    end if;
    if x = 19 then
      t := 1;
    else
      t := 0;
    end if;
    dbms_lock.sleep(0.01);
  end loop;
  return false;
end;
--
procedure unlock_pipe(p_pipe varchar2) is
  p varchar2(100);
begin
  $IF $$LOG_CALL $THEN
    cache_service_test.unlock_pipe(p_pipe);
  $END
  p := '$'||p_pipe;
  while dbms_pipe.receive_message(p,0) = 0 loop
    dbms_pipe.reset_buffer;
  end loop;
  dbms_pipe.reset_buffer;
  dbms_pipe.pack_message(freetag);
  send_pipe(p,3);
end;
--
procedure get_ulist(p_pipe varchar2, u in out nocopy rtl.integer_table, p_get boolean) is
  i pls_integer;
  j pls_integer;
  s varchar2(40);
begin
  $IF $$LOG_CALL $THEN
    cache_service_test.get_ulist(p_pipe, u, p_get);
  $END
  for x in 1..2 loop
    while dbms_pipe.receive_message(p_pipe,0) = 0 loop
      dbms_pipe.unpack_message(s);
      i := instr(s,'.');
      if i>1 then
        j := substr(s,1,i-1);
        i := substr(s,i+1);
        if p_get and j<>cur_user.id or not p_get and (j=cur_user.id or rtl.session_exists(j,i)) then
          u(j) := i;
        end if;
      end if;
    end loop;
  end loop;
end;
--
procedure reg_pipe_events (p_pipe varchar2, p_add boolean) is
  b boolean;
  i pls_integer;
  p varchar2(100);
  u rtl.integer_table;
begin
check_addr_cache(p_pipe);
if uaddrs.exists(p_pipe) and uaddrs(p_pipe) then
  b := cur_user.id=rtl.uid$ or rtl.get_user_info(cur_user);
  p := prefix||p_pipe;
  b := lock_pipe(p);
  if p_add is null and cur_user.id > 0 then
    dbms_pipe.reset_buffer;
    dbms_pipe.pack_message(cur_user.id||'.'||cur_user.sid);
    send_pipe(p,2);
  elsif b or nvl(p_add,true) then
    get_ulist(p,u,true);
    b := nvl(p_add,true);
    if b then
      u(cur_user.id) := cur_user.sid;
    else
      b := u.count>0;
    end if;
    dbms_pipe.reset_buffer;
    if b then
      i := u.first;
      while not i is null loop
        dbms_pipe.pack_message(i||'.'||u(i));
        send_pipe(p,2);
        i := u.next(i);
      end loop;
    end if;
  end if;
  unlock_pipe(p);
end if;
end;
--
procedure send$pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2) is
  b boolean;
  i pls_integer;
  p varchar2(100);
  u rtl.integer_table;
  -- содержит все SID and AUDSID найденые со всех pipe
  u_all rtl.integer_table;
  res boolean := true;
begin
  b := cur_user.id=rtl.uid$ or rtl.get_user_info(cur_user);

  -- находим все дочерние ТБП от текущего ТБП
  for c in(select child_id as c_pipe
            from class_relations
              where
                parent_id = p_pipe and
                (select dict_mgr.get_cached(child_id) from dual) <> 0)
  loop
    p := prefix||c.c_pipe;
    if lock_pipe(p) then
      u.delete();
      get_ulist(p,u,false);
      b := u.count>0;
      dbms_pipe.reset_buffer;
      if b then
        i := u.first;
        -- после того как мы вычитали AUDSID.SID, кладем их обратно в pipe
        -- положить мы должны только те AUDSID.SID, которые вычитали
        while not i is null loop
          u_all(i) := u(i);
          dbms_pipe.pack_message(i||'.'||u(i));
          send_pipe(p,3);
          i := u.next(i);
        end loop;
      end if;
      unlock_pipe(p);
    else
      res := false;
      exit;
    end if;
  end loop;

  if res then
    if p_code is null then return; end if;
    b := u_all.count > 0;
    if b then
      rtl.read(null);
      i := u_all.first;
      while not i is null loop
        if i<>cur_user.id then
          rtl.send_event(i,p_code,p_event,-1,u_all(i));
        end if;
        i := u_all.next(i);
      end loop;
    end if;
    if rtl.rtl_nodes > 0 then
      rtl.send_events(p_code,p_event,'.');
    end if;
  else
    if p_code is null then return; end if;
    rtl.send_events(p_code,p_event);
  end if;
end;
--
procedure send_pipe_events(p_pipe varchar2, p_code pls_integer, p_event varchar2) is
begin
  check_addr_cache(p_pipe);
  if uaddrs.exists(p_pipe) and uaddrs(p_pipe) then
    send$pipe_events(p_pipe,p_code,p_event);
  elsif p_code is not null then
    rtl.send_events(p_code,p_event);
  end if;
end;
--
procedure refresh_cache_pipes(p_init_classes boolean default null) is
  v_name  varchar2(40);
  v_cls   varchar2(30);
  b boolean;
  l pls_integer;
begin
  if p_init_classes then
    for c in (
     select class_id from class_tables ct where cached>1 or cached<-1 or cached=1
        and exists (select 1 from class_tab_columns cc
             where cc.class_id=ct.class_id and cc.static='1' and cc.deleted='0' and rownum=1)
    ) loop
      send_pipe_events(c.class_id,null,null);
    end loop;
    return;
  end if;
  v_name := '$'||prefix||'%';
  l := length(prefix)+2;
  for c in ( select name from v$db_pipes where name like v_name ) loop
    v_cls := substr(c.name,l);
    if p_init_classes is null then
      b := false;
      for t in (
        select class_id from class_tables ct where class_id=v_cls and (cached>1 or cached<-1 or cached=1
           and exists (select 1 from class_tab_columns cc
                where cc.class_id=ct.class_id and cc.static='1' and cc.deleted='0' and rownum=1))
      ) loop
        b := true; exit;
      end loop;
    else
      b := true;
    end if;
    if b then
      send$pipe_events(v_cls,null,null);
    end if;
  end loop;
end;
--
procedure cache_reset(p_class in varchar2, p_cascade boolean, p_id in varchar2) is
  idx_obj varchar2(128) := p_id;
  p_str varchar2(4000);
  l_Cursor number;
  l_Ignore number;
begin
  $IF $$LOG_CALL $THEN
    cache_service_test.cache_reset(p_class, p_cascade, p_id);
  $END
  $IF $$TEST_CORE $THEN
    if test_utils.is_stub_unit('cache_service.cache_reset') then
      return;
    end if;
  $END
  if p_id is null then
    -- если пришло сообщение о сбросе всего кэша
    p_str := 'BEGIN ' || class_mgr.interface_package(p_class) || '.CACHE_DEL(NULL,TRUE);';

    -- Сброс кэша дочерних ТБП нужен только для варианта сброс всего кэша ТБП
    for c in(select child_id
              from class_relations
                where
                  parent_id = p_class and
                  child_id<>PARENT_ID and
                  (select dict_mgr.get_cached(child_id) from dual) <> '0')
    loop
      p_str := p_str || class_mgr.interface_package(c.child_id) || '.CACHE_DEL(NULL,FALSE);'||chr(10);
    end loop;

  else
    -- если пришло сообщение о сбросе кэша для экземпляра
    p_str := 'declare l_obj varchar2(128) := :OBJ;'||chr(10);
    -- если p_cascade = TRUE, значит,
    -- можно сбрасывать каскадно кэш для ТБП, идя от дочернего к родительскому ТБП,
    -- начиная с ТПБ найденного нами экземпляра.
    p_str := p_str || 'BEGIN '||class_mgr.interface_package(p_class)||'.CACHE_DEL(l_obj,' || case when p_cascade then 'TRUE' else 'FALSE' end || ');';

  end if;

  p_str := p_str || 'END;';


  l_Cursor := DBMS_SQL.open_cursor;
  DBMS_SQL.PARSE(l_Cursor, p_str, DBMS_SQL.NATIVE);

  if p_id is not null then
    DBMS_SQL.BIND_VARIABLE(l_Cursor, ':OBJ', idx_obj);
  end if;
  l_Ignore := DBMS_SQL.EXECUTE(l_Cursor);
  DBMS_SQL.CLOSE_CURSOR(l_Cursor);
exception when others then
  If l_Cursor > 0 then
    DBMS_SQL.CLOSE_CURSOR(l_Cursor);
  end if;
  raise;
end cache_reset;
--
end cache_service;
/
show err package body cache_service

