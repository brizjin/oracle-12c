prompt view DBA_USERS
create or replace view &&audmgr..dba_users(USERNAME,USER_ID,ACCOUNT_STATUS) AS
select u.name, u.user#, m.status
  from sys.user$ u, sys.user_astatus_map m
 where u.type#=1 and  u.astatus = m.status#;
sho err

var s varchar2(100);

prompt view DBA_AUDIT_TRAIL for Oracle10g
declare
  s1 varchar2(100);
  s2 varchar2(100);
  v number;
begin
  dbms_utility.db_version(s1,s2);
  v := substr(s1,1,instr(s1,'.')-1);
  if v>=10 then
    execute immediate
'create or replace view &&audmgr..dba_audit_trail as
select spare1           OS_USERNAME,
       userid           USERNAME,
       userhost         USERHOST,
       terminal         TERMINAL,
       ntimestamp#      NTIMESTAMP#,
       obj$creator      OWNER,
       obj$name         OBJECT_NAME,
       action#          ACTION,
       new$owner        NEW_OWNER,
       new$name         NEW_NAME,
       auth$privileges  PRIVS,
       auth$grantee     GRANTEE,
       ses$actions      SES_ACTIONS,
       logoff$time      LOGOFF_TIME,
       logoff$lread     LOGOFF_LREAD,
       logoff$pread     LOGOFF_PREAD,
       logoff$lwrite    LOGOFF_LWRITE,
       decode(action#,
              104 /* audit   */, null,
              105 /* noaudit */, null,
              108 /* grant  sys_priv */, null,
              109 /* revoke sys_priv */, null,
              114 /* grant  role */, null,
              115 /* revoke role */, null,
              logoff$dead)
                         LOGOFF_DLOCK,
       comment$text      COMMENT_TEXT,
       sessionid         SESSIONID,
       entryid           ENTRYID,
       statement         STATEMENTID,
       returncode        RETURNCODE,
       clientid          CLIENT_ID,
       auditid           ECONTEXT_ID,
       sessioncpu        SESSION_CPU,
       from_tz(ntimestamp#,''00:00'') at local
                                   EXTENDED_TIMESTAMP,
       proxy$sid                      PROXY_SESSIONID,
       user$guid                           GLOBAL_UID,
       instance#                      INSTANCE_NUMBER,
       process#                            OS_PROCESS,
       xid                              TRANSACTIONID,
       scn                                        SCN,
       to_nchar(substr(sqlbind,1,2000))      SQL_BIND,
       to_nchar(substr(sqltext,1,2000))      SQL_TEXT
from sys.aud$';
    :s := 'view DBA_AUDIT_TRAIL - created';
  else
    :s := 'view DBA_AUDIT_TRAIL - creation skipped due to Oracle version: '||s1;
  end if;
end;
/

print s


