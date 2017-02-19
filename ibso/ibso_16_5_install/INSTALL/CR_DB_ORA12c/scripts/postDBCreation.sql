SET VERIFY OFF
spool $ORACLE_BASE/admin/work/scripts/postDBCreation.log append
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/catbundleapply.sql;
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
create spfile='$ORACLE_BASE/product/12.1.0/dbhome_1/dbs/spfilework.ora' FROM pfile='$ORACLE_BASE/admin/work/scripts/init.ora';
connect "SYS"/"&&sysPassword" as SYSDBA
select 'utlrp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/utlrp.sql;
select 'utlrp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;
select comp_id, status from dba_registry;
shutdown immediate;
connect "SYS"/"&&sysPassword" as SYSDBA
startup ;
spool off
exit;
