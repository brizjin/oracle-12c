rem *********************************************************
rem –аздача грантов и создание синонимов дл€ отчетов
rem «апускаетс€ из-под SQL*Plus
rem *********************************************************

var sMode char(30);
exec :sMode:= '&&reproles';

var sCrSyn char(30);
exec :sCrSyn:= '&&crsyn';

set feedback off
set heading off
set newpage 0
set pagesize 0
set echo off
set termout off
set verify off
set linesize 250
set arraysize 1
set trimspool on
set trimout on
set recsep off
set timi off

column xxx new_value oxxx noprint
select user xxx from dual;

var cntroles number;
var grproles number;
var reproles number;
var v_AdminGrp  number;
var v_all_users number;


set serveroutput off

declare
    sMode   varchar2(100);
    sCrSyn  varchar2(100);
    crsyn_old   varchar2(1);
    v_cntroles  pls_integer;
    v_grproles  boolean;
begin
    :v_AdminGrp := 0;
    :v_All_users:= null;
    :grproles := null;
    :reproles := 0;

    sMode := upper(ltrim(rtrim(:sMode)));
    sCrSyn:= nvl(substr(upper(ltrim(rtrim(:sCrSyn))),1,1),'N');
    if sCrSyn not in ('Y','N','S','F') then
      sCrSyn:= 'N';
    end if;

    v_cntroles := storage_mgr.get_storage_parameter('GLOBAL', 'MAX_REPORT_ROLES');
    if substr(sMode,1,1)='Y' then
      :cntroles := 140;
    elsif substr(sMode,1,1)='N' then
      :cntroles := 0;
    else
      begin
         :cntroles := to_number(sMode);
      exception when others then null;
      end;
    end if;
    :cntroles := greatest(least(nvl(:cntroles,nvl(v_cntroles,0)),140),0);

    crsyn_old := upper(substr(stdio.get_resource('DEFAULT','CREATE_SYNONYMS'),1,1));
    if crsyn_old is null then
      crsyn_old := 'Y';
      stdio.set_resource('DEFAULT','CREATE_SYNONYMS',crsyn_old,'—оздавать пользовательские синонимы дл€ объектов отчетов');
    end if;
    if crsyn_old <> sCrSyn then  --  дл€ версий >= 7.1 отслеживать изменение умолчательного профил€
      if sCrSyn in ('Y','N') then
        stdio.set_resource('DEFAULT','CREATE_SYNONYMS',sCrSyn);
        :v_All_users := 1;
      elsif sCrSyn = 'F' then
        :v_All_users := 1;
      end if;
    elsif v_cntroles = :cntroles then
      null;
    elsif v_cntroles is not null or (v_cntroles is null and :cntroles > 0) then
      :v_All_users := 1;
    elsif :cntroles = 0 then
      :v_All_users := 0;
    end if;

    v_grproles := upper(substr(storage_mgr.get_storage_parameter('GLOBAL', 'GROUP_REPORT_ROLES'),1,1)) in ('Y','1');
    if v_grproles is null then
      :grproles := case when :cntroles > 10 then 1 else 0 end;
    elsif v_grproles then
      if :cntroles <= 10 then
        :grproles := 0;
      end if;
    elsif :cntroles > 10 then
      :grproles := 1;
    end if;

    if :grproles is null then
      select count(1) into :reproles from report_roles where rownum=1;
    end if;
    if :reproles = 0 then
      if sCrSyn = 'S' then
        :v_All_users := 0;
      else
        :v_All_users := 1;
      end if;
    end if;

    if :v_All_users = 0 then
      -- требуетс€ пересоздание синонимов дл€ пользователей APP_SRV или пользователей из ADMIN_GRP
      -- или дл€ рутовых ревизоров
      if secadmin.IsAdminGrpEnabled then
        :v_AdminGrp := 1;
      end if;
    end if;

end;
/

spool c_syn_.sql

select
  'prompt ***' || u.username||chr(10)||
  'exec secadmin.CreateSynonymsForSubject(''' || u.username || ''',false,true,false);'
  from users u
 where type = 'U' and instr(nvl(properties,'|'),'|2L_LOCK') = 0
   and exists (select 1 from all_users where username = u.username)
   and ( lock_status is null or lock_status not in ('DELETED','TO_DELETE') )
   and ( :v_All_users = 1
         and ( instr(nvl(properties,'|'),'|LOCK') = 0
            or instr(nvl(properties,'|'),'|REVISOR') > 0 )
      or :v_All_users = 0
         and ( instr(nvl(properties,'|'),'|INIT_SESSION') > 0
            or ( instr(nvl(properties,'|'),'|REVISOR') > 0
                 and not exists (select 1 from sec_domain_entries where user_id=u.username) )
            or ( :v_AdminGrp = 1
                 and exists (select 1 from Subj_Equal where Equal_Id='ADMIN_GRP' and Subj_Id=u.username) )
         )
   )
 order by u.username;

spool off

set termout on

spool c_syn.log
set serveroutput on size 1000000

select 'Started  creating report roles - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;

prompt Create roles for report_objects

exec secadmin.set_max_report_roles(:cntroles);
exec secadmin.set_group_report_roles(:grproles=1);

declare
   procedure insert$(p_group varchar2, p_name varchar2, p_value varchar2) is
   begin
     insert into storage_parameters
          (param_group, param_name, param_value)
     values
            (p_group, p_name, p_value);
     stdio.put_line_buf(p_group || '.' || p_name || ' - OK');
     commit;
   exception when others then null;
   end;
begin
 insert$('GLOBAL', 'GRANTS_LIMIT_SESSIONS', 1000);
 insert$('GLOBAL', 'GRANTS_LIMIT_ACTIVE_SESSIONS', 20);
 if :reproles = 0 then
   secadmin.generate_report_roles(:cntroles, p_grants=>false);
 elsif :v_All_users is not null then
   secadmin.ReportRolesCare;
 end if;
end;
/

select 'Finished creating report roles - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;

select 'Started  creating synonyms - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
@C_SYN_.SQL
select 'Finished creating synonyms - '||TO_CHAR(SYSDATE,'DD/MM/YY (HH24:MI:SS)') from dual;
spool off
host del C_SYN_.SQL
set feedback on
set heading on
set timi on
--EXIT