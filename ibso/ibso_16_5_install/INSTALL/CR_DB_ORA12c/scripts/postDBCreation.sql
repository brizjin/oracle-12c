SET VERIFY OFF
spool /u/app/oracle/admin/work/scripts/postDBCreation.log append
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/catbundleapply.sql;
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
create spfile='/u/app/oracle/product/12.1.0/dbhome_1/dbs/spfilework.ora' FROM pfile='/u/app/oracle/admin/work/scripts/init.ora';
connect "SYS"/"&&sysPassword" as SYSDBA
select 'utlrp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/utlrp.sql;
select 'utlrp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;
select comp_id, status from dba_registry;
shutdown immediate;
connect "SYS"/"&&sysPassword" as SYSDBA
startup ;
spool off
exit;
