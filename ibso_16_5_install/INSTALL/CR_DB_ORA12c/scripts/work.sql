set verify off
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
host /u/app/oracle/product/12.1.0/dbhome_1/bin/orapwd file=/u/app/oracle/product/12.1.0/dbhome_1/dbs/orapwwork force=y format=12
@/u/app/oracle/admin/work/scripts/CreateDB.sql
@/u/app/oracle/admin/work/scripts/CreateDBFiles.sql
@/u/app/oracle/admin/work/scripts/CreateDBCatalog.sql
@/u/app/oracle/admin/work/scripts/JServer.sql
@/u/app/oracle/admin/work/scripts/lockAccount.sql
@/u/app/oracle/admin/work/scripts/postDBCreation.sql
