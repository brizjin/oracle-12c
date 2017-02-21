spool audm.log

@@../settings

Prompt Creating auditor manager schema objects...
define audit = &&AUDM_OWNER --ACCEPT audit   PROMPT 'Schema Name for AUDIT manager (&&AUDM_OWNER):' default &&AUDM_OWNER
define tusers = &&AUDM_TUSERS --ACCEPT tusers  PROMPT 'Tablespace for tables (&&AUDM_TUSERS):'  default &&AUDM_TUSERS
define tspacei = &&AUDM_TSPACEI --ACCEPT tspacei PROMPT 'Tablespace for indexes (&&AUDM_TSPACEI) :'  default &&AUDM_TSPACEI

SET TERMOUT OFF
column xxx new_value audmgr noprint
select decode('&&audit','SYS','AUDM','','AUDM','&&audit') xxx from dual;
column xxx new_value audpart noprint
select to_char(add_months(sysdate,1),'YYYY-MM')||'-02 01:00:00' xxx from dual;
select value xxx from &&audmgr..settings where name='DATE_PARTITIONS';
SET TERMOUT ON

define auditor = &&AUD_OWNER --ACCEPT auditor PROMPT 'Enter AUDIT schema name with diaries (&&AUD_OWNER): '  default &&AUD_OWNER
define ibso = &&IBSO_OWNER --ACCEPT ibso    PROMPT 'Enter IBSO OWNER schema name (&&IBSO_OWNER): '  default &&IBSO_OWNER
define audpart = '&&AUDPART' --ACCEPT audpart PROMPT 'Monthly add diary partitions "YYYY-MM-DD HH24:MI:SS" (&&AUDPART): '  default '&&AUDPART'


@@../UTILS/chk_sets
@@../UTILS/chk_tsps '&&tusers, &&tspacei'

exec &&audmgr..aud_mgr.stop;
prompt settings
create table &&audmgr..settings (name varchar2(20),value varchar2(100)) tablespace &&tusers;
alter table &&audmgr..settings add constraint pk_settings_name
  primary key(name) using index tablespace &&tspacei;
create or replace trigger &&audmgr..trg_settings_ins_upd
before insert or update
on &&audmgr..settings
for each row
begin
  :new.name:=upper(:new.name);
  :new.value:=upper(:new.value);
end;
/
audit session;
insert into &&audmgr..settings(name,value) values ('AUDITOR','&&auditor');

@@packages/audm_vw

@@packages/aud1
@@packages/aud2

alter trigger &&audmgr..logon_trigger compile;
alter trigger &&audmgr..logoff_trigger compile;
alter table &&ibso..users add
  (date_lock date, date_unlock date, lock_status varchar2(16));
exec &&audmgr..aud_mgr.get_settings(true);
exec &&audmgr..aud_mgr.add_owner('&&ibso');

@@packages/ora_user_password_set

declare
  d date;
begin
  begin
    d := to_date('&&audpart','YYYY-MM-DD HH24:MI:SS');
  exception when others then d := null;
  end;
  if d is null then
    delete &&audmgr..settings where name='DATE_PARTITIONS';
  else
    &&audmgr..aud_mgr.set_value('DATE_PARTITIONS','&&audpart');
  end if;
end;
/
commit;

rem exec &&audmgr..aud_mgr.submit;
spool off
exit

