SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /u/app/oracle/admin/work/scripts/CreateDBCatalog.log append
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/catalog.sql;
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/catproc.sql;
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/catoctk.sql;
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/owminst.plb;
connect "SYSTEM"/"&&systemPassword"
@/u/app/oracle/product/12.1.0/dbhome_1/sqlplus/admin/pupbld.sql;
connect "SYSTEM"/"&&systemPassword"
set echo on
spool /u/app/oracle/admin/work/scripts/sqlPlusHelp.log append
@/u/app/oracle/product/12.1.0/dbhome_1/sqlplus/admin/help/hlpbld.sql helpus.sql;
spool off
spool off
