prompt runproc_pkg body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Runproc2.sql $
 *  $Author: verkhovskiy $
 *  $Revision: 34686 $
 *  $Date:: 2013-12-12 16:29:22 #$
 */
runproc_pkg as
    -- Global variables
    glFirst boolean := true;
    last_date   date;
    selfsid     number;
    selfuser    varchar2(30);
    selfosuser  varchar2(30);
    selfprogram varchar2(100);
    -- Global constants
    C_PIPE_EXEC     constant varchar2(30):= 'RUNPROC$EXEC$'||Inst_info.owner;
    C_PIPE_ANSW     constant varchar2(30):= 'RUNPROC$ANSW$'||Inst_info.owner;
    VERSION         constant varchar2(20):= 'Version 3.0';
    WRITE_TIME_OUT  constant pls_integer := 1;
    READ_TIME_OUT   constant pls_integer := 15;
    EXIT_STATUS     constant pls_integer := 10;
    DEBUG_STATUS    constant pls_integer := 11;
    PIPEWAIT_STATUS constant pls_integer := 12;
    PTIMEOUT_STATUS constant pls_integer := 13;
    RESOURCE_BUSY   exception;
    PRAGMA EXCEPTION_INIT( RESOURCE_BUSY, -54 ); -- ORA-00054: resource busy and acquire with NOWAIT specified
------------------------------------------------------------------------
--                GetQuery
------------------------------------------------------------------------
    -- GetQuery - Получить запрос по rowid
    --
    -- pType =  'B' - PL/SQL блок кода
    --          'P' - PID процесса для killer'а
    --          'E' - экспорт
    --          'I' - импорт
    -- return  0 - все O'key
    --         1 - что то не ладно
    --
function GetQuery (   -- @METAGS GetQuery
                       pRowid in  varchar2  -- rowid запроса в таблице gc.queries
                      ,pText  out nocopy varchar2  -- тело запроса
                      ,pType  out nocopy varchar2  -- тип запроса
                      ,pId    out nocopy varchar2  -- ID запроса
                  ) return number as
    rQ  queries%rowtype;
begin
    select * into rQ from queries where rowid = chartorowid ( pRowid );
    -- Удаляем без ответные запросы
    if rQ.TYPE = 'B' then
        delete queries where rowid = chartorowid ( pRowid );
        commit;
    end if;
    -- возвращаемые параметры
    pText   := rQ.Text;
    pType   := rQ.Type;
    pID     := rQ.ID;
    return 0;
exception
    when OTHERS  then return sqlcode;
end GetQuery;
-------------------------------------------------------
--                Chk4Reset
-------------------------------------------------------
procedure ResetQueries is
  s varchar2(40);
  n number;
begin
  last_date := sysdate+READ_TIME_OUT/1440;
  s := '% for '||inst_info.owner;
  select count(1) into n from v$session
   where username=selfuser and osuser=selfosuser and program=selfprogram
     and status<>'INACTIVE' and action like s and sid<>selfsid and rownum=1;
  if n=0 then
    for c in (
      select rowid from queries where type='B' and code='EXECUTING' for update nowait
    ) loop
      update queries set code='EXECUTE' where rowid=c.rowid;
    end loop;
    commit;
  end if;
exception when resource_busy then
  rollback;
end;
--
procedure Chk4Reset as
    v_module    varchar2(100);
    v_action    varchar2(100);
    v_sid       integer;
begin
    if glFirst then
        v_module := 'RUNPROC server';
        v_action := 'Jobs for '||inst_info.owner;
        dbms_application_info.set_module ( v_module, v_action  );
        dbms_application_info.set_client_info(VERSION);
        select sid, username, osuser, program
          into selfsid, selfuser, selfosuser, selfprogram
          from v$session
         where sid = (select sid from v$mystat where rownum=1);
        dbms_pipe.purge( C_PIPE_EXEC );
        dbms_pipe.purge( C_PIPE_ANSW );
        dbms_pipe.reset_buffer;
        glFirst := false;
        ResetQueries;
    end if;
end;
------------------------------------------------------------------------
--          PUT_COMMAND - пoслать команду серверу RUNPROC
------------------------------------------------------------------------
procedure PUT_COMMAND(p_cmd varchar2) is
begin
    stdio.put_line_pipe( p_cmd, C_PIPE_EXEC, WRITE_TIME_OUT );
end;
------------------------------------------------------------------------
--          TEST_SERVER - проверка активности сервера RUNPROC
------------------------------------------------------------------------
function TEST_SERVER return boolean is
    s   integer;
    str varchar2(1000);
begin
    dbms_pipe.purge( C_PIPE_ANSW );
    put_command( 'TEST' );
    s := stdio.get_line_pipe( str, C_PIPE_ANSW, 5 );
    return s=0;
end;
------------------------------------------------------------------------
--          STOP_SERVER - останов сервера RUNPROC
------------------------------------------------------------------------
procedure STOP_SERVER(p_quit boolean default false) is
begin
  if test_server then
    if p_quit then
      put_command('QUIT');
    else
      put_command('EXIT');
    end if;
  end if;
end;
------------------------------------------------------------------------
--          GET_QUEUE - извлечение ID запроса на выполнение задания по расписанию
------------------------------------------------------------------------
procedure GET_QUEUE( p_id      in out nocopy varchar2,
                     p_status  in out nocopy pls_integer,
                     p_timeout pls_integer default null
                    ) is
  s      pls_integer;
  v_cnt  pls_integer;
  v_time pls_integer;
  v_wait pls_integer;
  v_str  varchar2(1000);
begin
  Chk4Reset;
  p_status := 1;
  v_cnt:= 0;
  v_time := 0;
  if p_timeout>0 then
    v_wait := p_timeout;
  else
    v_wait := READ_TIME_OUT;
  end if;
  while v_cnt<10 loop
    dbms_pipe.reset_buffer;
    s := stdio.get_line_pipe(v_str,C_PIPE_EXEC,v_time);
    if s=0 then
        v_cnt := 0;
        v_time := 0;
        if v_str='TEST' then
            stdio.put_line_pipe( v_str, C_PIPE_ANSW, WRITE_TIME_OUT );
        elsif v_str='EXIT' then
            p_status := EXIT_STATUS;
            return;
        elsif v_str='QUIT' then
            p_status := -EXIT_STATUS;
            return;
        elsif v_str like 'DEBUG:%' then
          if p_id is null then
            p_id := substr(v_str,7);
            p_status := DEBUG_STATUS;
            return;
          end if;
        elsif v_str like 'PIPEWAIT:%' then
          if p_id is null then
            p_id := substr(v_str,10);
            p_status := PIPEWAIT_STATUS;
            return;
          end if;
        elsif v_str like 'PTIMEOUT:%' then
          if p_id is null then
            p_id := substr(v_str,10);
            p_status := PTIMEOUT_STATUS;
            return;
          end if;
        elsif v_str='CLEAR' then
            delete queries;
            commit;
        elsif v_str='REFRESH' then
            glFirst:=true;
            Chk4Reset;
            return;
        elsif v_str='DELETE' then
            delete queries where type='B' and code='EXECUTED';
            commit;
        elsif v_str='NULL'  then
            null;
        else
            p_status := -1;
            return;
        end if;
    elsif s=1 then
        if v_time<v_wait then
          v_cnt := 0;
          if v_time=0 then
            v_time := 1;
          elsif p_id is null then
            v_time := v_wait;
          else
            p_status := 0;
            return;
          end if;
        else
          v_cnt := v_cnt+1;
        end if;
    else
        raise_application_error(-20000-s, 'Error:'||to_char(s)||' receiving from pipe');
    end if;
    if p_id is null then
      begin
        for c in (select id from queries
                   where created<=sysdate and type='B' and code='EXECUTE' and rownum=1
                     for update nowait)
        loop
          p_id  := c.id;
        end loop;
        if not p_id is null then
          update queries set code='EXECUTING' where id=p_id and type='B';
          commit;
          p_status := 0;
          return;
        end if;
        commit;
      exception when resource_busy then
        rollback;
        if v_time>1 then
          v_time := 1;
        end if;
      end;
    end if;
    if last_date<sysdate then
      ResetQueries;
    end if;
  end loop;
end;
------------------------------------------------------------------------
--          GET_MSG - чтение строки из pipe
------------------------------------------------------------------------
function GET_MSG(   PIPENAME  in  varchar2
                   ,BUF       out nocopy varchar2
                   ,BUFTYPE   out nocopy varchar2
                 ) return number is
  vId varchar2(30);
begin return  get_msg(pipename,buf,buftype,vId); end;
--
function GET_MSG(   PIPENAME  in  varchar2
                   ,BUF       out nocopy varchar2
                   ,BUFTYPE   out nocopy varchar2
                   ,ID        out nocopy varchar2   -- ID запроса
                   ) return number is
  S      pls_integer;
  v_time pls_integer := 0;
  RPTR   varchar2(1000);
begin
  Chk4Reset;
  loop
    dbms_pipe.reset_buffer;
    S := stdio.get_line_pipe(RPTR,PIPENAME,v_time);
    if s=0 then s := 1;
        if RPTR='TEST' then
            stdio.put_line_pipe( RPTR, C_PIPE_ANSW, WRITE_TIME_OUT );
        elsif RPTR='NULL'  then null;
        elsif RPTR='CLEAR' then
            delete queries; commit;
        elsif RPTR='REFRESH' then
            glFirst:=true; Chk4Reset;
        elsif RPTR='DELETE' then
            delete queries where type='B' and code='EXECUTED'; commit;
        elsif RPTR in ('EXIT','QUIT') then
            raise_application_error(-20001, 'Termination signal received from pipe');
        elsif instr(RPTR,':')>0 then
            null;
        else
            S := GETQUERY( RPTR,BUF,BUFTYPE,ID );
        end if;
    elsif s<>1 then
        raise_application_error(-20000-s, 'Error:'||to_char(S)||' receiving from pipe');
    end if;
    exit when s<>1;
    for c in (select id,rowid from queries
               where created<=sysdate and type='B' and code='EXECUTE')
    loop
        BUFTYPE := 'B';
        ID  := c.id;
        BUF := 'begin '||inst_info.owner||'.runproc_pkg.execquery('''||c.id||'''); end;';
        update queries set code='EXECUTING' where rowid=c.rowid;
        commit;
        s := 0;
        exit;
    end loop;
    exit when s<>1;
    if last_date<sysdate then
        ResetQueries;
    end if;
    v_time:= READ_TIME_OUT;
  end loop;
  return S;
exception
  when others then
    if sqlcode=-6508 then raise; end if;
    return SQLCODE;
end GET_MSG;
------------------------------------------------------------------------
--           SendQueries - послать ответ
------------------------------------------------------------------------
function SendQuery(     pText   varchar2
                       ,pType   varchar2
                       ,pId     varchar2
                       ,pCode   varchar2 := null 
                       ,pMaxFailures number := null) return number as
    vText   varchar2(2000);
    vRowid  rowid;
begin
    -- проверка длины кода
    if length(pText) > 2000  then
         vText := substr(pText,-2000);
    else vText := pText;     end if;
    -- Проверка типа
    --if pType not in ('0','1') then    return 1;    end if;
    begin
        -- вставим в таблицу
        insert into queries (type,text,id, username, created, code ,repeat_error )
            values (pType, vText, pId, user, sysdate, pCode, pMaxFailures )
            returning rowid into vRowid;
    exception
        when OTHERS then
            return SQLCODE;
    end;
    COMMIT;
    if pType='B' then
        stdio.put_line_pipe( rowidtochar(vRowid), C_PIPE_EXEC, WRITE_TIME_OUT );
    else
        stdio.put_line_pipe( rowidtochar(vRowid), C_PIPE_ANSW, WRITE_TIME_OUT );
    end if;
    return 0;
end SendQuery;
------------------------------------------------------------------------
--          PUT_MESS - послать сообщение-ответ
------------------------------------------------------------------------
-- return  0 - все O'key
--         1 - что то не ладно
function PUT_MESS(    MSG in  varchar2
                     ,pID in varchar2 )
return number as
begin  return SendQuery(MSG,'1'/*type*/,pID); end PUT_MESS;
------------------------------------------------------------------------
--          PUT_END - послать завершение-ответ
------------------------------------------------------------------------
-- return  0 - все O'key
--         1 - что то не ладно
function PUT_END(     MSG in  varchar2
                     ,CODE    in  varchar2
                     ,pID in varchar2 )
return number as
begin return SendQuery(MSG,'0'/*type*/,pID,CODE); end PUT_END;
------------------------------------------------------------------------
--          PUT_MSG - запись строки в pipe
------------------------------------------------------------------------
function PUT_MSG( PIPENAME in varchar2,MSG in  varchar2 ) return number
is
begin
  return 0;
end;
------------------------------------------------------------------------
function  Put_Query(     pText   varchar2
                       ,pId     varchar2
                       ,pCode   varchar2 := null
                       ,pMaxFailures number := null ) return number is
begin return SendQuery(pText,'B',pId,pCode,pMaxFailures); end;
------------------------------------------------------------------------
--           AddQuery - добавить запрос
------------------------------------------------------------------------
function AddQuery( pText   varchar2,
                   pTime   date     default null,
                   pCode   varchar2 default null,
                   pType   varchar2 default null,
                   pMaxFailures number default null) return number is
    vText   varchar2(2000);
    vCode   varchar2(15) := nvl(substr(pCode,1,15),'EXECUTE');
    vType   varchar2(1)  := nvl(substr(pType,1,1),'B');
    vTime   date;
    vId     number;
begin
    -- проверка длины кода
    if length(pText) > 2000  then
         vText := substr(pText,1,2000);
    else vText := pText;     end if;
    vTime := nvl(pTime,sysdate);
    begin
        -- вставим в таблицу
        insert into queries (type, text, id, username, created, code, repeat_error )
            values (vType, vText, queries_id.nextval, user, vTime, vCode, pMaxFailures)
            returning id into vId;
    exception
        when OTHERS then
            return SQLCODE;
    end;
    return vId;
end AddQuery;
------------------------------------------------------------------------
procedure DropQuery(    pType   varchar2
                       ,pId     varchar2 ) is
begin
    delete queries where type=pType and id=pId;
end;
------------------------------------------------------------------------
procedure CheckQuery(  pType   varchar2
                      ,pId     varchar2 ) is
    s   number;
begin
    select 1 into s from queries
     where type=pType and id=pId;
end;
------------------------------------------------------------------------
function  Get_Sys_Max_Failures return number is
begin return nvl(stdio.num_set('JOBS_MAX_FAILURES'),10); end;
------------------------------------------------------------------------
procedure UpdQuery(  pId     varchar2,
                     pDate   date,
                     pBroken varchar2,
                     pCheck  boolean default false,
                     pFail   number  default null,
                     pMaxFailures number default null) is
    vCode   varchar2(15);
    vFail   number := nvl(pFail,0);
    vDate   date := pDate;
begin
    if pBroken='1' then
        vCode := 'BROKEN';
    else
        vCode := 'EXECUTE';
        if vFail>nvl(pMaxFailures,Get_Sys_Max_Failures) then
            vCode := 'EXECUTED';
        elsif vFail>0 then
            vDate := sysdate+(vFail/2880);
        elsif pCheck and vDate<=sysdate then
            vCode := 'EXECUTED';
        end if;
    end if;
    update queries
       set code=vCode, created=vDate, failures=vFail
     where id=pId and type='B';
end;
------------------------------------------------------------------------
procedure ExecQuery(  pId     varchar2 ) is
    vRowid  rowid;
    vJob    integer;
    vFail   integer;
    vBroken varchar2(1);
    vText   varchar2(2000);
    vNext   date;
    pMaxFailures number;
begin
  vJob := pId;
  select text,created,rowid,failures,repeat_error into vText,vNext,vRowid,vFail,pMaxFailures
    from queries q where type='B' and id=pId;
  begin
    update queries set code='EXECUTING' where rowid=vRowid;
    commit;
    execute immediate
        'declare job number:=-:job; next_date date:=:next; broken boolean:=false;'||chr(10)||
        'begin :brok:=''0'';'||chr(10)||
        vText||chr(10)||
        ':next:=next_date; if broken then :brok:=''1''; end if;'||chr(10)||
        'end;'
        using in vJob, in out vNext, in out vBroken;
    UpdQuery( pId, vNext, vBroken, true);
    commit;
    dbms_application_info.set_module ( 'RUNPROC - '||inst_info.owner, 'Sleeping' );
  exception when others then
    Rollback;
    vFail := nvl(vFail,0)+1;
    UpdQuery( pId, vNext, vBroken, true, vFail, pMaxFailures);
    commit;
    raise;
  end;
end;
------------------------------------------------------------------------
end runproc_pkg;
/
sho err package body runproc_pkg

