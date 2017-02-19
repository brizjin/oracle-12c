SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool $ORACLE_BASE/admin/work/scripts/JServer.log append
@$ORACLE_BASE/product/12.1.0/dbhome_1/javavm/install/initjvm.sql;
@$ORACLE_BASE/product/12.1.0/dbhome_1/xdk/admin/initxml.sql;
@$ORACLE_BASE/product/12.1.0/dbhome_1/xdk/admin/xmlja.sql;
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/catjava.sql;
connect "SYS"/"&&sysPassword" as SYSDBA
@$ORACLE_BASE/product/12.1.0/dbhome_1/rdbms/admin/catxdbj.sql;
spool off
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool $ORACLE_BASE/admin/work/scripts/postDBCreation.log append
grant sysdg to sysdg;
grant sysbackup to sysbackup;
grant syskm to syskm;
