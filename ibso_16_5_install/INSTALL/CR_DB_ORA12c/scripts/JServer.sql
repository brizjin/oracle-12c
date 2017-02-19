SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /u/app/oracle/admin/work/scripts/JServer.log append
@/u/app/oracle/product/12.1.0/dbhome_1/javavm/install/initjvm.sql;
@/u/app/oracle/product/12.1.0/dbhome_1/xdk/admin/initxml.sql;
@/u/app/oracle/product/12.1.0/dbhome_1/xdk/admin/xmlja.sql;
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/catjava.sql;
connect "SYS"/"&&sysPassword" as SYSDBA
@/u/app/oracle/product/12.1.0/dbhome_1/rdbms/admin/catxdbj.sql;
spool off
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool /u/app/oracle/admin/work/scripts/postDBCreation.log append
grant sysdg to sysdg;
grant sysbackup to sysbackup;
grant syskm to syskm;
