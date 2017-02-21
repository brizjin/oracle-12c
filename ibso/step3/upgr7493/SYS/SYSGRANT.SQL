-- –аздача необходимых грантов пользователю-владельцу схемы IBSO.
-- ¬ыполн€етс€ из-под SYS или другого пользовател€ с полномочи€ми DBA.
-- ѕеред запуском нужно убедитьс€, что нет активных пользовательских
-- сессий (иначе не добав€тс€ гранты на пакеты).

spool grant_sys.log

prompt Refreshing System Privileges and Grants

set echo on

prompt ROLES grants
grant RESOURCE to &&OWNER;
grant CONNECT to &&OWNER with admin option;

prompt PRIVILEGES grants
grant ALTER SESSION to &&OWNER with admin option;
grant ALTER SYSTEM to &&OWNER;
grant ALTER TABLESPACE to &&OWNER;
grant ANALYZE ANY to &&OWNER;
grant CHANGE NOTIFICATION to &&OWNER; 
grant CREATE ANY CONTEXT to &&OWNER;
grant CREATE ANY DIRECTORY to &&OWNER;
grant CREATE ANY JOB to &&OWNER;
grant CREATE ANY SYNONYM to &&OWNER;
grant CREATE ANY TRIGGER to &&OWNER;
grant CREATE DATABASE LINK to &&OWNER;
grant CREATE PROCEDURE to &&OWNER;
grant CREATE ROLE to &&OWNER;
grant CREATE SEQUENCE to &&OWNER;
grant CREATE SESSION to &&OWNER;
grant CREATE SNAPSHOT to &&OWNER;
grant CREATE TABLE to &&OWNER;
grant CREATE TRIGGER to &&OWNER;
grant CREATE TYPE to &&OWNER;
grant CREATE USER to &&OWNER;
grant CREATE VIEW to &&OWNER;
grant DROP ANY CONTEXT to &&OWNER;
grant DROP ANY DIRECTORY to &&OWNER;
grant DROP ANY SYNONYM to &&OWNER;
grant DROP ANY TRIGGER to &&OWNER;
grant MANAGE SCHEDULER to &&OWNER;
grant QUERY REWRITE to &&OWNER;
grant UNLIMITED TABLESPACE to &&OWNER;

prompt OBJECTS grants
grant EXECUTE on SYS.DBMS_ALERT to &&OWNER;
grant EXECUTE on SYS.DBMS_APPLICATION_INFO to &&OWNER;
grant EXECUTE on SYS.DBMS_AQ to &&OWNER;
grant EXECUTE on SYS.DBMS_AQADM to &&OWNER;
grant EXECUTE on SYS.DBMS_JOB to &&OWNER;
grant EXECUTE on SYS.DBMS_LOB to &&OWNER;
grant EXECUTE on SYS.DBMS_LOCK to &&OWNER;
grant EXECUTE on SYS.DBMS_OUTPUT to &&OWNER;
grant EXECUTE on SYS.DBMS_PIPE to &&OWNER;
grant EXECUTE on SYS.DBMS_RLS to &&OWNER;
grant EXECUTE on SYS.DBMS_SCHEDULER to &&OWNER;
grant EXECUTE on SYS.DBMS_SESSION to &&OWNER;
grant EXECUTE on SYS.DBMS_SHARED_POOL to &&OWNER;
grant EXECUTE on SYS.DBMS_SQL to &&OWNER;
grant EXECUTE on SYS.DBMS_STATS to &&OWNER;
grant EXECUTE on SYS.DBMS_SYSTEM to &&OWNER;
grant EXECUTE on SYS.DBMS_UTILITY to &&OWNER;
grant EXECUTE on SYS.DBMS_XMLGEN to &&OWNER;
grant EXECUTE on SYS.UTL_FILE to &&OWNER;
grant EXECUTE on SYS.UTL_RAW to &&OWNER;
grant EXECUTE on SYS.UTL_RECOMP to &&OWNER;
grant EXECUTE on SYS.DBMS_CRYPTO to &&OWNER;

grant SELECT  on SYS.DBA_CONTEXT to &&OWNER;
grant SELECT  on SYS.DBA_DATA_FILES to &&OWNER;
grant SELECT  on SYS.DBA_ROLE_PRIVS to &&OWNER;
grant SELECT  on SYS.DBA_OBJECTS  to &&OWNER with grant option;
grant SELECT  on SYS.DBA_JOBS to &&OWNER with grant option;
grant SELECT  on SYS.DBA_SCHEDULER_JOBS to &&OWNER with grant option;
grant SELECT  on SYS.DBA_SCHEDULER_JOB_CLASSES to &&OWNER with grant option;
grant SELECT  on SYS.DBA_SCHEDULER_JOB_RUN_DETAILS to &&OWNER with grant option;
grant SELECT  on SYS.DBA_TABLES  to &&OWNER with grant option;
grant SELECT  on SYS.DBA_INDEXES  to &&OWNER;
grant SELECT  on SYS.DBA_TRIGGERS  to &&OWNER;
grant SELECT  on SYS.DBA_CONSTRAINTS  to &&OWNER;
grant SELECT  on SYS.DBA_SOURCE  to &&OWNER;
grant SELECT  on SYS.DBA_ERRORS  to &&OWNER;
grant SELECT  on SYS.DBA_VIEWS  to &&OWNER;
grant SELECT  on SYS.DBA_TYPES  to &&OWNER;
grant SELECT  on SYS.DBA_COLL_TYPES  to &&OWNER;
grant SELECT  on SYS.DBA_TYPE_ATTRS  to &&OWNER;
grant SELECT  on SYS.DBA_TYPE_METHODS  to &&OWNER;
grant SELECT  on SYS.DBA_METHOD_RESULTS  to &&OWNER;
grant SELECT  on SYS.DBA_ALL_TABLES  to &&OWNER;
grant SELECT  on SYS.DBA_NESTED_TABLES  to &&OWNER;
grant SELECT  on SYS.DBA_TAB_COLUMNS  to &&OWNER;
grant SELECT  on SYS.DBA_UNUSED_COL_TABS  to &&OWNER;
grant SELECT  on SYS.DBA_IND_COLUMNS  to &&OWNER;
grant SELECT  on SYS.DBA_IND_EXPRESSIONS  to &&OWNER;
grant SELECT  on SYS.DBA_CONS_COLUMNS  to &&OWNER;
grant SELECT  on SYS.DBA_TRIGGER_COLS  to &&OWNER;
grant SELECT  on SYS.DBA_TAB_PARTITIONS  to &&OWNER with grant option;
grant SELECT  on SYS.DBA_TAB_SUBPARTITIONS  to &&OWNER with grant option;
grant SELECT  on SYS.DBA_IND_PARTITIONS  to &&OWNER with grant option;
grant SELECT  on SYS.DBA_IND_SUBPARTITIONS to &&OWNER with grant option;
grant SELECT  on SYS.DBA_PART_COL_STATISTICS to &&OWNER;
grant SELECT  on SYS.DBA_PART_INDEXES to &&OWNER with grant option;
grant SELECT  on SYS.DBA_USERS  to &&OWNER;
grant SELECT  on SYS.DBA_DEPENDENCIES  to &&OWNER;
grant SELECT  on SYS.DBA_TAB_PRIVS  to &&OWNER;
grant SELECT  on SYS.DBA_SYS_PRIVS  to &&OWNER;
grant SELECT  on SYS.DBA_TABLESPACES  to &&OWNER with grant option;
grant SELECT  on SYS.DBA_SYNONYMS  to &&OWNER;
grant SELECT  on SYS.DBA_SEQUENCES  to &&OWNER;
grant SELECT  on SYS.DBA_EXTENTS  to &&OWNER;
grant SELECT  on SYS.DBA_LOCK  to &&OWNER;
grant SELECT  on SYS.DBA_LOCK_INTERNAL to &&OWNER;
grant SELECT  on SYS.DBA_LIBRARIES  to &&OWNER;
grant SELECT  on SYS.DBA_OBJECT_TABLES to &&OWNER;
grant SELECT  on SYS.DBA_NESTED_TABLE_COLS to &&OWNER;
grant SELECT  on SYS.DBA_TAB_COLS to &&OWNER;
grant SELECT  on SYS.DBA_TABLESPACE_GROUPS to &&OWNER;

grant SELECT  on SYS.V_$SESSION to &&OWNER with grant option;
grant SELECT  on SYS.V_$LOCK  to &&OWNER with grant option;
grant SELECT  on SYS.V_$PROCESS  to &&OWNER with grant option;
grant SELECT  on SYS.V_$INSTANCE to &&OWNER with grant option;
grant SELECT  on SYS.V_$SESSTAT  to &&OWNER with grant option;
grant SELECT  on SYS.V_$STATNAME to &&OWNER with grant option;
grant SELECT  on SYS.GV_$SESSION  to &&OWNER with grant option;
grant SELECT  on SYS.GV_$LOCK     to &&OWNER with grant option;
grant SELECT  on SYS.GV_$PROCESS  to &&OWNER with grant option;
grant SELECT  on SYS.GV_$INSTANCE to &&OWNER with grant option;
grant SELECT  on SYS.GV_$SESSTAT  to &&OWNER with grant option;
grant SELECT  on SYS.GV_$STATNAME to &&OWNER with grant option;

grant SELECT  on SYS.V_$SQLAREA to &&OWNER;
grant SELECT  on SYS.V_$DB_PIPES to &&OWNER;
grant SELECT  on SYS.V_$SGASTAT  to &&OWNER;
grant SELECT  on SYS.V_$SYSSTAT  to &&OWNER;
grant SELECT  on SYS.V_$SQLTEXT  to &&OWNER;
grant SELECT  on SYS.GV_$SGASTAT  to &&OWNER;
grant SELECT  on SYS.GV_$SYSSTAT  to &&OWNER;
grant SELECT  on SYS.GV_$SQLTEXT  to &&OWNER;
grant SELECT  on SYS.GV_$SQLAREA  to &&OWNER;
grant SELECT  on SYS.GV_$DB_PIPES to &&OWNER;

grant SELECT  on SYS.V_$PARAMETER to &&OWNER with grant option;
grant SELECT  on SYS.GV_$PARAMETER to &&OWNER with grant option;
grant SELECT  on SYS.V_$SESSION_EVENT to &&OWNER with grant option;
grant SELECT  on SYS.GV_$SESSION_EVENT to &&OWNER with grant option;
grant SELECT  on SYS.V_$SESSION_WAIT to &&OWNER with grant option;
grant SELECT  on SYS.GV_$SESSION_WAIT to &&OWNER with grant option;
grant SELECT  on SYS.V_$SYSTEM_EVENT to &&OWNER with grant option;
grant SELECT  on SYS.GV_$SYSTEM_EVENT to &&OWNER with grant option;
grant SELECT  on SYS.V_$EVENT_NAME to &&OWNER with grant option;
grant SELECT  on SYS.GV_$EVENT_NAME to &&OWNER with grant option;
grant SELECT  on SYS.V_$SESS_IO to &&OWNER with grant option;
grant SELECT  on SYS.GV_$SESS_IO to &&OWNER with grant option;
grant SELECT  on SYS.V_$MYSTAT to &&OWNER with grant option;
grant SELECT  on SYS.GLOBAL_CONTEXT to &&OWNER with grant option;
grant SELECT  on SYS.V_$CONTEXT to &&OWNER with grant option;
grant SELECT  on SYS.GV_$CONTEXT to &&OWNER with grant option;
grant SELECT  on SYS.V_$GLOBALCONTEXT to &&OWNER with grant option;
grant SELECT  on SYS.GV_$GLOBALCONTEXT to &&OWNER with grant option;
grant SELECT  on SYS.V_$DB_OBJECT_CACHE to &&OWNER;
grant SELECT  on SYS.V_$DATABASE to &&OWNER;
grant SELECT  on SYS.V_$OSSTAT  to &&OWNER;
grant SELECT  on SYS.V_$LICENSE to &&OWNER;

prompt XDB grants
grant EXECUTE on XDB.DBMS_XMLDOM to &&OWNER;
grant EXECUTE on XDB.DBMS_XMLPARSER to &&OWNER;

prompt NO DEFAULT ROLES

alter user &&OWNER default role none;
revoke ALTER USER from &&OWNER;

prompt Patch for Oracle Bugs for role CONNECT

revoke create view from connect;
revoke create table from connect;
revoke create synonym from connect;
revoke create cluster from connect;
revoke create sequence from connect;
revoke create database link from connect;
revoke alter  session from connect;
grant  create session to connect;

prompt Drop owner roles without admin option

begin
  for i in (
    select p.granted_role as role
      from dba_role_privs p
     where p.grantee = upper('&&OWNER')
       and p.granted_role like upper('&&OWNER\_%') escape '\'
       and upper(p.admin_option) <> 'YES'
    union
    select r.role
      from dba_roles r
     where r.role like upper('&&OWNER\_%') escape '\'
       and not exists (select 1
              from dba_role_privs p
             where p.granted_role = r.role
               and p.grantee <> 'SYS')
  ) loop
    execute immediate('DROP ROLE ' || i.role);
  end loop;
end;
/

set echo off

spool off
