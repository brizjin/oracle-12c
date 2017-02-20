spool audminit.log

@@..\settings

Prompt Creating auditor manager schema...
accept audit prompt 'Schema Name for AUDIT manager (&&AUDM_OWNER):' default &&AUDM_OWNER
ACCEPT dt PROMPT 'Default tablespace (&&AUDM_TDEF) :'  default &&AUDM_TDEF
ACCEPT tt PROMPT 'Temporary tablespace (&&AUDM_TTMP) :' default &&AUDM_TTMP
ACCEPT it PROMPT 'Tablespace for indexes(&&AUDM_TSPACEI) :' default &&AUDM_TSPACEI

@@..\UTILS\chk_sets
@@..\UTILS\chk_tsps '&&dt, &&tt, &&it'

set echo on
create user &&audit identified by &&audit;
alter  user &&audit default tablespace &dt;
alter  user &&audit temporary tablespace &tt;
alter  user &&audit default role none;

rem common grants
grant CREATE SESSION to &&audit;
grant CREATE PROCEDURE to &&audit;
grant CREATE TABLE to &&audit;
grant CREATE VIEW to &&audit;
grant UNLIMITED TABLESPACE to &&audit;

rem special grants
grant ALTER USER to &&audit;
grant AUDIT SYSTEM to &&audit;
grant CREATE ANY TRIGGER to &&audit;
grant EXECUTE ANY PROCEDURE to &&audit;
grant SELECT ANY SEQUENCE to &&audit;
grant SELECT ANY TABLE to &&audit;
grant DELETE ANY TABLE to &&audit;
grant INSERT ANY TABLE to &&audit;
grant UPDATE ANY TABLE to &&audit;

rem For Oracle 9i
grant execute on sys.DBMS_PIPE  to &&audit;
grant execute on sys.DBMS_LOCK  to &&audit;
grant execute on sys.DBMS_ALERT to &&audit;
grant execute on sys.DBMS_UTILITY to &&audit;
grant select  on sys.DBA_AUDIT_TRAIL to &&audit;
grant select  on sys.DBA_JOBS to &&audit;
grant select  on sys.DBA_OBJECTS to &&audit;
grant select  on sys.DBA_PRIV_AUDIT_OPTS to &&audit;
grant select  on sys.DBA_TAB_COLUMNS to &&audit;
grant select  on sys.DBA_USERS to &&audit;

grant select on sys.AUD$ to &&audit;
grant delete on sys.AUD$ to &&audit;

grant select on sys.USER_ASTATUS_MAP to &&audit;
grant select on sys.USER$ to &&audit;
grant select on sys.V_$PARAMETER to &&audit;
grant select on sys.V_$LOCK to &&audit;
grant select on sys.V_$MYSTAT to &&audit;
grant select on sys.V_$SESSION to &&audit;
grant select on sys.V_$PROCESS to &&audit;

alter  tablespace &&dt coalesce;
alter  tablespace &&it coalesce;
drop index sys.i_aud_timestamp;
alter  table sys.aud$ move tablespace &&dt storage (initial 512K next 512K maxextents unlimited pctincrease 0);
alter  index sys.i_aud1 rebuild tablespace &&it storage (initial 128K next 128K maxextents unlimited pctincrease 0);
rem index on sys.aud$ - Oracle10
create index sys.i_aud_timestamp on sys.aud$(ntimestamp#)
  tablespace &&it storage (initial 128K next 128K maxextents unlimited pctincrease 0);
rem index on sys.aud$ - Oracle8-9
create index sys.i_aud_timestamp on sys.aud$(timestamp#)
  tablespace &&it storage (initial 128K next 128K maxextents unlimited pctincrease 0);
alter  tablespace system coalesce;
@@packages\verify
spool off
exit
