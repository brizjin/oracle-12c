spool audinit.log

@../settings

DEFINE u=&&AUD_OWNER
prompt Creating Auditor Schema - &&u
define dt = &&AUD_TDEF --ACCEPT dt PROMPT 'Default tablespace (&&AUD_TDEF) :' default &&AUD_TDEF
define tt = &&AUD_TTMP --ACCEPT tt PROMPT 'Temporary tablespace (&&AUD_TTMP):' default &&AUD_TTMP

@../UTILS/chk_sets
@../UTILS/chk_tsps '&&dt, &&tt'

prompt
prompt Stop all background processes and press ENTER to continue...
--pause

SET VERIFY OFF
set echo on
create user &&u identified by &&u;
alter user &&u
    default tablespace &&dt
    temporary tablespace &&tt
    default role none;

grant alter  system  to &&u;
grant create session to &&u;
grant create table to &&u;
grant create trigger to &&u;
grant create view to &&u;
grant create sequence to &&u;
grant create procedure to &&u;
grant create role to &&u;
grant create any directory to &&u;
grant drop any directory to &&u;
grant UNLIMITED TABLESPACE to &&u;
grant EXECUTE on SYS.UTL_FILE to &&u;
grant EXECUTE on SYS.UTL_SMTP to &&u;
grant EXECUTE on SYS.UTL_RAW  to &&u;
grant EXECUTE on SYS.DBMS_SQL to &&u;
rem grant EXECUTE on SYS.DBMS_LOB to &&u;
grant EXECUTE on SYS.DBMS_LOCK    to &&u;
grant EXECUTE on SYS.DBMS_OUTPUT  to &&u;
grant EXECUTE on SYS.DBMS_UTILITY to &&u;
grant EXECUTE on SYS.DBMS_SESSION to &&u;
grant SELECT on SYS.V_$SESSION to &&u;
grant SELECT on SYS.V_$PROCESS to &&u;
grant SELECT on SYS.V_$MYSTAT  to &&u;
grant SELECT on SYS.V_$LOCK  to &&u;
grant SELECT on SYS.DBA_ROLE_PRIVS to &&u;
spool off
exit

