SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool $ORACLE_BASE/admin/work/scripts/CreateDBCatalog.log append
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/catalog.sql;
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/catproc.sql;
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/catoctk.sql;
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/owminst.plb;
connect "SYSTEM"/"&&systemPassword"
@$ORACLE_BASE/product/12.1.0/dbhome_1/sqlplus/admin/pupbld.sql;
connect "SYSTEM"/"&&systemPassword"
set echo on
spool $ORACLE_BASE/admin/work/scripts/sqlPlusHelp.log append
@$ORACLE_BASE/product/12.1.0/dbhome_1/sqlplus/admin/help/hlpbld.sql helpus.sql;
spool off
spool off
