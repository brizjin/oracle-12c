prompt runproc_mgr body
create or replace package body
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/Run_mgr2.sql $
 *  $Author: Alexey $
 *  $Revision: 15072 $
 *  $Date:: 2012-03-06 13:41:17 #$
 */
runproc_mgr as
    LF              constant varchar2(1) := chr(10);
    DAT_FORMAT      constant varchar2(20):= 'HH24:MI:SS DD/MM/YY';
    JOB_BODY        constant varchar2(70):= 'runproc_mgr.run_job(job,next_date,broken);';
    RESOURCE_BUSY   exception;
    PRAGMA EXCEPTION_INIT( RESOURCE_BUSY, -54 ); -- ORA-00054: resource busy and acquire with NOWAIT specified
------------------------------------------------------------------------
function run_process ( path varchar2, p_stop pls_integer) return pls_integer
    is language C
    name "Run_Process"
    library librunproc
    PARAMETERS (path    STRING,
                p_stop  INT,
                RETURN  INT);
--
function  run_server(p_check boolean default true)  return pls_integer is
begin
  if p_check and runproc_pkg.test_server then
    stdio.put_line_buf('RUNPROC_MGR: Server is active...');
    return null;
  end if;
  return run_process(nvl(stdio.setting('JOBS_RUNPROC_INI'),'runproc.ini'),0);
end;
--
function find_job return number is
begin
  for c in (select job from dba_jobs
             where schema_user=inst_info.owner and priv_user=inst_info.owner
               and what=job_body)
  loop
    return c.job;
  end loop;
  return null;
end;
--
procedure stop_job(p_quit boolean default false) is
  j number;
begin
  loop
    j := find_job;
    exit when j is null;
    stdio.put_line_buf('RUNPROC_MGR: job ('||j||') removed...');
    dbms_job.remove(j);
  end loop;
  runproc_pkg.stop_server(p_quit);
  delete queries where id='0' and type='J';
  commit;
end;
--
procedure submit_job is
  j number;
  s varchar2(100);
  d date;
begin
  j := find_job;
  if not j is null then
    stdio.put_line_buf('RUNPROC_MGR: job ('||j||') is already exists...');
    return;
  end if;
  if runproc_pkg.test_server then
    stdio.put_line_buf('RUNPROC_MGR: Server is active...');
    return;
  end if;
  delete queries where id='0' and type='J';
  dbms_job.submit(j,job_body);
  s := 'SUBMIT - '||to_char(SYSDATE,DAT_FORMAT)||LF;
  insert into queries(id,type,code,username,created,failures,text)
    values('0','J',j,user,sysdate,0,s);
  commit;
  stdio.put_line_buf('RUNPROC_MGR: job ('||j||') submitted...');
end;
--
procedure run_job ( p_job number, p_date in out nocopy date, p_broken in out nocopy boolean ) is
  i pls_integer;
  s varchar2(2000);
  n number;
  b boolean;
  function lock_job(p_busy boolean) return boolean is
  begin
    select failures, text into n, s
      from queries where id='0' and type='J' for update nowait;
    return true;
  exception
    when no_data_found then
      return false;
    when resource_busy then
      if p_busy then
        return null;
      end if;
      raise;
  end;
  procedure fix_job(p_text varchar2) is
    l pls_integer;
  begin
    l := 1999-length(p_text);
    loop
      if length(s)>l then
        i := instr(s,LF);
        if i>0 then
          s := substr(s,i+1);
        else
          s := substr(s,length(s)-l+1);
          exit;
        end if;
      else
        exit;
      end if;
    end loop;
    s := s||p_text||LF;
    update queries
       set failures=n, created=sysdate, code=p_job, text=s
     where id='0' and type='J';
  end;
begin
  begin
    select id1 into n from v$lock
     where type='JQ' and id2=p_job and sid=(select sid from v$mystat where rownum=1);
  exception when no_data_found then
    stdio.put_line_buf('RUNPROC_MGR: '||p_job||' is not a job...');
    return;
  end;
  if not lock_job(false) then
    return;
  end if;
  n := nvl(n,0);
  fix_job('START - '||to_char(SYSDATE,DAT_FORMAT));
  commit;
  dbms_application_info.set_module ( 'RUNPROC - '||inst_info.owner, 'Job' );
  begin
    if runproc_pkg.test_server then
      raise_application_error(-20001,'RUNPROC_MGR: Server is active...');
    end if;
    i := run_process(nvl(stdio.setting('JOBS_RUNPROC_INI'),'runproc.ini'),0);
    if lock_job(true) then
      fix_job('STOP: '||i||' - '||to_char(SYSDATE,DAT_FORMAT));
    end if;
  exception when others then
    if lock_job(true) then
      if n<5 then
        n := n+1;
        p_date := sysdate + n/8640;
      end if;
      fix_job(sqlerrm);
    end if;
  end;
  commit;
end;
------------------------------------------------------------------------
end runproc_mgr;
/
sho err package body runproc_mgr

